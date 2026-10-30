<template>
  <OceanBg>
    <main class="sponge-card wide">
      <h1 class="title">🐚 比奇堡居民名单</h1>
      <p class="subtitle">数据来自 MySQL · MyBatis-Plus 分页查询</p>

      <div class="search">
        <div class="input-wrap">
          <span class="icon">🔍</span>
          <input
            v-model.trim="keyword"
            type="text"
            placeholder="按用户名或昵称搜索"
            @keyup.enter="load(1)"
          />
        </div>
        <button class="btn small" :disabled="loading" @click="load(1)">搜索</button>
      </div>

      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>头像</th>
              <th>用户名</th>
              <th>昵称</th>
              <th>状态</th>
              <th>注册时间</th>
              <th class="th-act">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="u in records" :key="u.id">
              <td>{{ u.id }}</td>
              <td>{{ u.avatar }}</td>
              <td>{{ u.username }}</td>
              <td>{{ u.nickname }}</td>
              <td>
                <span class="tag" :class="u.status === 1 ? 'on' : 'off'">
                  {{ u.status === 1 ? '正常' : '禁用' }}
                </span>
              </td>
              <td class="time">{{ u.createTime }}</td>
              <td class="act">
                <!-- 自己的账号：可改昵称 / 改密码，不能禁用、不能删除 -->
                <template v-if="u.id === myId">
                  <button class="op" type="button" @click="openNick(u)">改昵称</button>
                  <button class="op" type="button" @click="openPwd(u)">改密码</button>
                  <span class="self-tag">本人</span>
                </template>
                <!-- 他人账号：可禁用 / 启用、删除 -->
                <template v-else>
                  <button class="op" type="button" @click="toggleStatus(u)">
                    {{ u.status === 1 ? '禁用' : '启用' }}
                  </button>
                  <button class="op danger" type="button" @click="askRemove(u)">删除</button>
                </template>
              </td>
            </tr>
            <tr v-if="!records.length">
              <td colspan="7" class="empty">🫧 没有找到居民</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pager">
        <button class="btn tiny" :disabled="current <= 1 || loading" @click="load(current - 1)">上一页</button>
        <span class="pinfo">第 {{ current }} / {{ pages || 1 }} 页 · 共 {{ total }} 人</span>
        <button class="btn tiny" :disabled="current >= pages || loading" @click="load(current + 1)">下一页</button>
      </div>

      <div class="tips" :class="tipsType">{{ tips }}</div>

      <router-link class="back" to="/home">← 回蟹堡王后台</router-link>
    </main>

    <!-- ============ 改昵称弹窗 ============ -->
    <div v-if="nickDialog.open" class="mask" @click.self="nickDialog.open = false">
      <div class="dialog">
        <h3>✏️ 修改昵称</h3>
        <p class="dialog-sub">用户：{{ nickDialog.username }}</p>
        <div class="input-wrap">
          <span class="icon">🧽</span>
          <input
            ref="nickInput"
            v-model.trim="nickDialog.value"
            type="text"
            maxlength="50"
            placeholder="输入新昵称"
            @keyup.enter="submitNick"
          />
        </div>
        <p class="dialog-err">{{ nickDialog.err }}</p>
        <div class="dialog-btns">
          <button class="btn tiny ghost" type="button" @click="nickDialog.open = false">取消</button>
          <button class="btn tiny" type="button" :disabled="nickDialog.busy" @click="submitNick">
            {{ nickDialog.busy ? '保存中…' : '保存' }}
          </button>
        </div>
      </div>
    </div>

    <!-- ============ 改密码弹窗 ============ -->
    <div v-if="pwdDialog.open" class="mask" @click.self="pwdDialog.open = false">
      <div class="dialog">
        <h3>🔑 修改密码</h3>
        <p class="dialog-sub">用户：{{ pwdDialog.username }}</p>
        <div class="input-wrap">
          <span class="icon">🔒</span>
          <input v-model="pwdDialog.oldPwd" type="password" placeholder="请输入原密码" />
        </div>
        <div class="input-wrap" style="margin-top:10px">
          <span class="icon">🆕</span>
          <input v-model="pwdDialog.newPwd" type="password" placeholder="新密码（至少 6 位）" />
        </div>
        <div class="input-wrap" style="margin-top:10px">
          <span class="icon">✅</span>
          <input v-model="pwdDialog.confirmPwd" type="password" placeholder="再输一次新密码" @keyup.enter="submitPwd" />
        </div>
        <p class="dialog-err">{{ pwdDialog.err }}</p>
        <div class="dialog-btns">
          <button class="btn tiny ghost" type="button" @click="pwdDialog.open = false">取消</button>
          <button class="btn tiny" type="button" :disabled="pwdDialog.busy" @click="submitPwd">
            {{ pwdDialog.busy ? '保存中…' : '保存' }}
          </button>
        </div>
      </div>
    </div>

    <!-- ============ 删除确认 ============ -->
    <div v-if="delDialog.open" class="mask" @click.self="delDialog.open = false">
      <div class="dialog">
        <h3>🗑️ 确认删除</h3>
        <p class="dialog-sub">
          将删除用户 <b>{{ delDialog.nickname || delDialog.username }}</b>（@{{ delDialog.username }}）。
          这是逻辑删除，数据仍在库中但不再出现在列表里。
        </p>
        <p class="dialog-err">{{ delDialog.err }}</p>
        <div class="dialog-btns">
          <button class="btn tiny ghost" type="button" @click="delDialog.open = false">取消</button>
          <button class="btn tiny danger" type="button" :disabled="delDialog.busy" @click="submitRemove">
            {{ delDialog.busy ? '删除中…' : '确认删除' }}
          </button>
        </div>
      </div>
    </div>
  </OceanBg>
</template>

<script setup>
import { nextTick, onMounted, reactive, ref } from 'vue'
import OceanBg from '../components/OceanBg.vue'
import { userPage, updateNickname, updatePassword, updateStatus, removeUser } from '../api/user'
import { toast } from '../utils/toast'

const records = ref([])
const total = ref(0)
const current = ref(1)
const pages = ref(1)
const keyword = ref('')
const loading = ref(false)
const tips = ref('')
const tipsType = ref('')

const nickInput = ref(null)

/** 当前登录用户 id，用来区分「自己」和「别人」 */
const myId = (() => {
  try {
    const u = JSON.parse(localStorage.getItem('bob_user') || '{}')
    return u.id ?? null
  } catch {
    return null
  }
})()

/* ---------------- 列表 ---------------- */

async function load(page = 1) {
  loading.value = true
  tips.value = ''
  try {
    const res = await userPage({ page, size: 5, keyword: keyword.value })
    if (res.code === 200) {
      records.value = res.data.records || []
      total.value = res.data.total || 0
      current.value = res.data.current || 1
      pages.value = res.data.pages || 1
    } else {
      tipsType.value = 'err'
      tips.value = '❌ ' + (res.msg || '查询失败')
    }
  } catch (e) {
    tipsType.value = 'err'
    tips.value = '❌ ' + e.message
  } finally {
    loading.value = false
  }
}

onMounted(() => load(1))

/* ---------------- 改昵称 ---------------- */

const nickDialog = reactive({ open: false, id: null, username: '', value: '', err: '', busy: false })

function openNick(u) {
  nickDialog.id = u.id
  nickDialog.username = u.username
  nickDialog.value = u.nickname || ''
  nickDialog.err = ''
  nickDialog.busy = false
  nickDialog.open = true
  nextTick(() => nickInput.value?.focus())
}

async function submitNick() {
  nickDialog.err = ''
  if (!nickDialog.value) {
    nickDialog.err = '昵称不能为空'
    return
  }
  nickDialog.busy = true
  try {
    const res = await updateNickname(nickDialog.id, nickDialog.value)
    if (res.code === 200) {
      nickDialog.open = false
      toast('✅ 昵称已更新', 'ok')
      // 同步本地缓存的用户信息，避免顶部栏还显示旧昵称
      syncSelf(res.data)
      await load(current.value)
    } else {
      nickDialog.err = res.msg || '保存失败'
    }
  } catch (e) {
    nickDialog.err = e.message
  } finally {
    nickDialog.busy = false
  }
}

/* ---------------- 改密码 ---------------- */

const pwdDialog = reactive({
  open: false, id: null, username: '',
  oldPwd: '', newPwd: '', confirmPwd: '', err: '', busy: false
})

function openPwd(u) {
  pwdDialog.id = u.id
  pwdDialog.username = u.username
  pwdDialog.oldPwd = ''
  pwdDialog.newPwd = ''
  pwdDialog.confirmPwd = ''
  pwdDialog.err = ''
  pwdDialog.busy = false
  pwdDialog.open = true
}

async function submitPwd() {
  pwdDialog.err = ''
  if (!pwdDialog.oldPwd) {
    pwdDialog.err = '请输入原密码'
    return
  }
  if (pwdDialog.newPwd.length < 6) {
    pwdDialog.err = '新密码至少 6 位'
    return
  }
  if (pwdDialog.newPwd !== pwdDialog.confirmPwd) {
    pwdDialog.err = '两次输入的新密码不一致'
    return
  }
  pwdDialog.busy = true
  try {
    const res = await updatePassword(pwdDialog.id, pwdDialog.oldPwd, pwdDialog.newPwd)
    if (res.code === 200) {
      pwdDialog.open = false
      toast('✅ 密码已修改，正在退出，请用新密码重新登录', 'ok')
      // 后端改密码会清掉令牌，这里主动清本地并回登录页
      localStorage.removeItem('bob_token')
      localStorage.removeItem('bob_user')
      setTimeout(() => window.location.replace('/login'), 1200)
    } else {
      pwdDialog.err = res.msg || '修改失败'
    }
  } catch (e) {
    pwdDialog.err = e.message
  } finally {
    pwdDialog.busy = false
  }
}

/* ---------------- 启用 / 禁用 ---------------- */

async function toggleStatus(u) {
  const next = u.status === 1 ? 0 : 1
  const label = next === 1 ? '启用' : '禁用'
  if (!window.confirm(`确定要${label}用户「${u.nickname || u.username}」吗？`)) return
  try {
    const res = await updateStatus(u.id, next)
    if (res.code === 200) {
      toast(`✅ 已${label}「${u.nickname || u.username}」`, 'ok')
      await load(current.value)
    } else {
      toast('❌ ' + (res.msg || `${label}失败`), 'err')
    }
  } catch (e) {
    toast('❌ ' + e.message, 'err')
  }
}

/* ---------------- 删除 ---------------- */

const delDialog = reactive({ open: false, id: null, username: '', nickname: '', err: '', busy: false })

function askRemove(u) {
  delDialog.id = u.id
  delDialog.username = u.username
  delDialog.nickname = u.nickname
  delDialog.err = ''
  delDialog.busy = false
  delDialog.open = true
}

async function submitRemove() {
  delDialog.err = ''
  delDialog.busy = true
  try {
    const res = await removeUser(delDialog.id)
    if (res.code === 200) {
      delDialog.open = false
      toast('✅ 用户已删除', 'ok')
      // 删掉最后一页的最后一条时，回退一页
      const target = records.value.length === 1 && current.value > 1 ? current.value - 1 : current.value
      await load(target)
    } else {
      delDialog.err = res.msg || '删除失败'
    }
  } catch (e) {
    delDialog.err = e.message
  } finally {
    delDialog.busy = false
  }
}

/* ---------------- 工具 ---------------- */

/** 改的是自己时，同步 localStorage 里的 bob_user */
function syncSelf(updated) {
  if (!updated || updated.id !== myId) return
  try {
    const old = JSON.parse(localStorage.getItem('bob_user') || '{}')
    localStorage.setItem('bob_user', JSON.stringify({ ...old, ...updated }))
  } catch {
    /* 忽略 */
  }
}
</script>

<style scoped>
.wide { max-width: 760px; }
.search { display: flex; gap: 10px; align-items: center; margin-top: 16px; }
.search .input-wrap { flex: 1; }
.search input { padding-left: 42px; }
.btn.small { margin-top: 0; width: auto; padding: 12px 18px; font-size: 15px; }
.btn.tiny { margin-top: 0; width: auto; padding: 8px 14px; font-size: 14px; }

.table-wrap {
  margin-top: 16px;
  background: rgba(255, 255, 255, .6);
  border: 3px dashed var(--sponge-border);
  border-radius: 18px;
  padding: 10px;
  max-height: 340px;
  overflow: auto;
}
table { width: 100%; border-collapse: collapse; font-size: 13px; }
th, td { padding: 8px 6px; text-align: left; border-bottom: 1px solid rgba(169, 123, 0, .3); }
th { color: #7a5400; font-weight: 800; white-space: nowrap; }
th.th-act { text-align: right; }
td.time { font-size: 12px; color: #7a5400; white-space: nowrap; }
td.empty { text-align: center; padding: 20px; color: #7a5400; }
.tag { padding: 2px 8px; border-radius: 10px; font-size: 12px; font-weight: 700; white-space: nowrap; }
.tag.on { background: #c8f0cd; color: var(--green-dark); }
.tag.off { background: #ffd9d3; color: var(--red); }

/* 操作列 */
td.act { text-align: right; white-space: nowrap; }
.op {
  padding: 3px 9px;
  margin-left: 4px;
  font-size: 12px; font-weight: 700; font-family: inherit;
  color: var(--ocean-1); cursor: pointer;
  background: #fff;
  border: 2px solid var(--ocean-1);
  border-radius: 9px;
  transition: .12s;
}
.op:hover { background: var(--ocean-3); color: #fff; border-color: var(--ocean-2); }
.op.danger { color: var(--red); border-color: var(--red); }
.op.danger:hover { background: var(--red); color: #fff; }
.self-tag {
  display: inline-block;
  margin-left: 6px; padding: 2px 7px;
  font-size: 11px; font-weight: 800; color: #7a5400;
  background: rgba(255, 217, 15, .55);
  border-radius: 8px;
}

.pager { display: flex; align-items: center; justify-content: center; gap: 12px; margin-top: 14px; }
.pinfo { font-size: 13px; font-weight: 700; color: #7a5400; }
.back { display: block; margin-top: 16px; text-align: center; font-size: 13px; font-weight: 700; color: #8a5a00; }

/* ---------- 弹窗 ---------- */
.mask {
  position: fixed; inset: 0;
  z-index: 200;
  display: flex; align-items: center; justify-content: center;
  padding: 20px;
  background: rgba(4, 55, 107, .55);
}
.dialog {
  width: 100%; max-width: 360px;
  padding: 20px 22px;
  background: #fffdf5;
  border: 5px solid var(--sponge-border);
  border-radius: 22px;
  box-shadow: 0 10px 0 var(--sponge-border), 0 20px 40px rgba(0, 0, 0, .4);
}
.dialog h3 { font-size: 18px; margin-bottom: 6px; }
.dialog-sub { font-size: 13px; color: #7a5400; line-height: 1.6; margin-bottom: 12px; }
.dialog .input-wrap { background: #fff; }
.dialog .input-wrap input { padding-left: 40px; }
.dialog-err { min-height: 18px; margin-top: 8px; font-size: 12px; font-weight: 700; color: var(--red); }
.dialog-btns { display: flex; gap: 10px; justify-content: flex-end; margin-top: 6px; }
.btn.tiny.ghost { background: #fff; color: var(--ink); border: 3px solid var(--sponge-border); }
.btn.tiny.danger { background: var(--red); color: #fff; border-color: #8e1a08; }

@media (max-width: 480px) {
  .table-wrap { font-size: 12px; }
  th, td { padding: 6px 4px; }
  .op { padding: 3px 7px; margin-left: 2px; font-size: 11px; }
}
</style>
