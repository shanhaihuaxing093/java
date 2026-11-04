<template>
  <div class="admin-shell">
    <OceanBg>
      <div class="admin-inner">
        <!-- 顶栏 -->
        <header class="admin-bar">
          <div class="brand"><span>🦀</span><b>蟹堡王 · 后台管理系统</b></div>
          <div class="spacer"></div>
          <button class="bar-btn" type="button" @click="$router.push('/home')">← 返回首页</button>
          <button class="bar-btn danger" type="button" @click="onLogout">退出后台</button>
        </header>

        <!-- 标签页 -->
        <nav class="tabs">
          <button
            v-for="t in TABS"
            :key="t.key"
            class="tab"
            :class="{ active: tab === t.key }"
            type="button"
            @click="tab = t.key"
          >
            {{ t.icon }} {{ t.title }}
          </button>
        </nav>

        <!-- ① 概览数据管理 -->
        <section v-show="tab === 'overview'" class="panel">
          <h2 class="panel-title">📊 首页概览数据</h2>
          <div class="form-grid">
            <label>今日蟹黄堡<input v-model.number="overviewForm.krabby" type="number" min="0" /></label>
            <label>在岗员工<input v-model.number="overviewForm.online" type="number" min="0" /></label>
            <label>海水温度<input v-model="overviewForm.waterTemp" type="text" placeholder="如 26℃" /></label>
            <label>天气描述<input v-model="overviewForm.weather" type="text" placeholder="如 晴 · 微浪" /></label>
          </div>
          <p class="hint">🐚 居民总数随「居民管理」自动统计，无需手填。</p>
          <button class="btn" type="button" @click="saveOverviewForm">保存概览数据</button>
        </section>

        <!-- ② 公告管理 -->
        <section v-show="tab === 'notices'" class="panel">
          <h2 class="panel-title">📢 公告管理</h2>
          <form class="add-row" @submit.prevent="onAddNotice">
            <select v-model="newNotice.icon" class="icon-select">
              <option v-for="i in ICONS" :key="i" :value="i">{{ i }}</option>
            </select>
            <input v-model.trim="newNotice.text" type="text" placeholder="输入公告内容…" required />
            <button class="btn small" type="submit">➕ 添加</button>
          </form>
          <ul class="row-list">
            <li v-for="n in notices" :key="n.id">
              <span class="r-icon">{{ n.icon }}</span>
              <span class="r-text">{{ n.text }}</span>
              <button class="mini danger" type="button" @click="onDeleteNotice(n)">删除</button>
            </li>
            <li v-if="!notices.length" class="empty">🫧 暂无公告，去添加一条吧</li>
          </ul>
        </section>

        <!-- ③ 居民管理 -->
        <section v-show="tab === 'residents'" class="panel">
          <h2 class="panel-title">🐚 居民管理</h2>
          <form class="add-row" @submit.prevent="onAddResident">
            <input v-model.trim="newResident.username" type="text" placeholder="用户名" required style="max-width:140px" />
            <input v-model.trim="newResident.nickname" type="text" placeholder="昵称" required style="max-width:140px" />
            <button class="btn small" type="submit">➕ 添加</button>
          </form>
          <ul class="row-list">
            <li v-for="r in residents" :key="r.id">
              <span class="r-icon">{{ r.avatar }}</span>
              <div class="r-main">
                <b>{{ r.nickname }}</b>
                <small>@{{ r.username }}</small>
              </div>
              <button class="mini" :class="r.status === 1 ? 'warn' : 'ok'" type="button" @click="toggleResident(r)">
                {{ r.status === 1 ? '禁用' : '启用' }}
              </button>
              <button class="mini danger" type="button" @click="onDeleteResident(r)">删除</button>
            </li>
            <li v-if="!residents.length" class="empty">🫧 暂无居民</li>
          </ul>
        </section>

        <p class="footnote">
          🫧 数据保存在浏览器本地（localStorage），后端 <code>/api/home/*</code> 就绪后自动切换为接口存储
        </p>
      </div>
    </OceanBg>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import OceanBg from '../../components/OceanBg.vue'
import { logout } from '../../api/auth'
import { clearSession } from '../../api/request'
import {
  getHomeData, saveOverview, resetHomeData,
  addNotice, removeNotice,
  addResident, updateResident, removeResident
} from '../../api/home'
import { toast } from '../../utils/toast'

const router = useRouter()

const TABS = [
  { key: 'overview', icon: '📊', title: '概览数据' },
  { key: 'notices', icon: '📢', title: '公告管理' },
  { key: 'residents', icon: '🐚', title: '居民管理' }
]
const ICONS = ['📢', '🍔', '🧽', '🦀', '⭐', '🐚', '🎉', '⚠️']

const tab = ref('overview')
const overviewForm = reactive({ krabby: 0, online: 0, waterTemp: '', weather: '' })
const notices = ref([])
const residents = ref([])
const newNotice = reactive({ icon: '📢', text: '' })
const newResident = reactive({ username: '', nickname: '' })

function loadData() {
  const d = getHomeData()
  Object.assign(overviewForm, d.overview)
  notices.value = d.notices
  residents.value = d.residents
}

function saveOverviewForm() {
  saveOverview({ ...overviewForm })
  toast('✅ 概览数据已保存，首页刷新后生效', 'ok')
}

function onAddNotice() {
  if (!newNotice.text) return toast('⚠️ 公告内容不能为空', 'err')
  addNotice({ ...newNotice })
  newNotice.text = ''
  loadData()
  toast('✅ 公告已发布', 'ok')
}

function onDeleteNotice(n) {
  removeNotice(n.id)
  loadData()
  toast('🗑️ 公告已删除', 'ok')
}

function onAddResident() {
  if (!newResident.username || !newResident.nickname) return toast('⚠️ 用户名和昵称都要填', 'err')
  if (residents.value.some((r) => r.username === newResident.username))
    return toast('⚠️ 该用户名已存在', 'err')
  addResident({ ...newResident })
  newResident.username = ''
  newResident.nickname = ''
  loadData()
  toast('✅ 居民已添加', 'ok')
}

function toggleResident(r) {
  updateResident(r.id, { status: r.status === 1 ? 0 : 1 })
  loadData()
}

function onDeleteResident(r) {
  removeResident(r.id)
  loadData()
  toast(`🗑️ 已移除居民 ${r.nickname}`, 'ok')
}

async function onLogout() {
  try {
    await logout()
  } catch {
    /* 后端不可用也要能退出 */
  }
  clearSession()
  router.replace('/admin/login')
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.admin-shell { min-height: 100vh; }
.admin-inner {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  gap: 14px;
  max-width: 1080px;
  margin: 0 auto;
  padding: 18px 20px 48px;
}

.admin-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 18px;
  background: rgba(255, 253, 242, 0.92);
  border: 3px solid rgba(169, 123, 0, 0.45);
  border-radius: 16px;
  backdrop-filter: blur(6px);
}
.brand { display: flex; align-items: center; gap: 8px; font-size: 17px; font-weight: 800; color: #6b4a00; }
.spacer { flex: 1; }
.bar-btn {
  padding: 8px 14px;
  font-family: inherit;
  font-size: 13px;
  font-weight: 800;
  color: #6b4a00;
  cursor: pointer;
  background: #fff;
  border: 2px solid rgba(169, 123, 0, 0.45);
  border-radius: 12px;
  transition: 0.15s;
}
.bar-btn:hover { background: rgba(255, 217, 15, 0.4); }
.bar-btn.danger { color: #b23c0e; border-color: rgba(210, 80, 80, 0.7); }
.bar-btn.danger:hover { background: #ffe3e3; }

.tabs { display: flex; gap: 8px; flex-wrap: wrap; }
.tab {
  padding: 10px 20px;
  font-family: inherit;
  font-size: 14px;
  font-weight: 800;
  color: #6b4a00;
  cursor: pointer;
  background: rgba(255, 253, 242, 0.9);
  border: 3px solid rgba(169, 123, 0, 0.4);
  border-radius: 14px;
  transition: 0.15s;
}
.tab:hover { background: rgba(255, 217, 15, 0.45); }
.tab.active {
  color: #fff;
  background: linear-gradient(135deg, #ff7a45, #e8541d);
  border-color: #a63a10;
}

.panel {
  padding: 20px 22px;
  background: rgba(255, 253, 242, 0.94);
  border: 3px solid rgba(169, 123, 0, 0.45);
  border-radius: 18px;
}
.panel-title { margin: 0 0 16px; font-size: 18px; font-weight: 800; color: #6b4a00; }

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
  margin-bottom: 12px;
}
.form-grid label {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 13px;
  font-weight: 800;
  color: #6b4a00;
}
.form-grid input,
.add-row input {
  height: 38px;
  padding: 0 11px;
  font-family: inherit;
  font-size: 14px;
  color: var(--ink, #3a2c00);
  background: #fff;
  border: 2px solid rgba(169, 123, 0, 0.45);
  border-radius: 11px;
  outline: none;
}
.form-grid input:focus,
.add-row input:focus { border-color: var(--ocean-1, #3fc4e8); }
.hint { margin: 0 0 14px; font-size: 12px; color: #7a5400; }

.btn {
  padding: 11px 22px;
  font-family: inherit;
  font-size: 14px;
  font-weight: 800;
  color: #fff;
  cursor: pointer;
  background: linear-gradient(135deg, #ff7a45, #e8541d);
  border: 3px solid #a63a10;
  border-radius: 13px;
  box-shadow: 0 3px 0 #a63a10;
  transition: 0.15s;
}
.btn:hover { transform: translateY(-2px); box-shadow: 0 5px 0 #a63a10; }
.btn.small { padding: 8px 15px; border-width: 2px; font-size: 13px; }

.add-row {
  display: flex;
  align-items: center;
  gap: 9px;
  margin-bottom: 15px;
  flex-wrap: wrap;
}
.add-row input { flex: 1; min-width: 180px; }
.icon-select {
  width: 52px;
  height: 38px;
  font-size: 16px;
  background: #fff;
  border: 2px solid rgba(169, 123, 0, 0.45);
  border-radius: 11px;
}

.row-list {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.row-list li {
  display: flex;
  align-items: center;
  gap: 11px;
  padding: 10px 13px;
  background: #fff;
  border: 2px solid rgba(169, 123, 0, 0.36);
  border-radius: 13px;
}
.r-icon { font-size: 18px; }
.r-text { flex: 1; font-size: 13px; line-height: 1.5; }
.r-main { display: flex; flex-direction: column; flex: 1; line-height: 1.3; min-width: 0; }
.r-main b { font-size: 14px; }
.r-main small { font-size: 11px; color: #7a5400; }

.mini {
  padding: 5px 12px;
  font-family: inherit;
  font-size: 12px;
  font-weight: 800;
  cursor: pointer;
  background: #fff;
  border: 2px solid rgba(169, 123, 0, 0.5);
  border-radius: 10px;
  transition: 0.13s;
}
.mini:hover { background: rgba(255, 217, 15, 0.4); }
.mini.danger { color: #b23c0e; border-color: rgba(210, 80, 80, 0.7); }
.mini.danger:hover { background: #ffe3e3; }
.mini.warn { color: #a97b00; }
.mini.ok { color: #2e7d32; border-color: rgba(63, 156, 79, 0.7); }

.empty { justify-content: center; color: #7a5400; font-weight: 700; font-size: 13px; }

.footnote {
  text-align: center;
  font-size: 12px;
  font-weight: 700;
  color: var(--white, #e8f6ff);
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.45);
}
.footnote code {
  padding: 1px 5px;
  font-family: Consolas, monospace;
  background: rgba(255, 255, 255, 0.18);
  border-radius: 6px;
}

@media (max-width: 640px) {
  .form-grid { grid-template-columns: 1fr; }
  .admin-inner { padding: 12px 12px 40px; }
}
</style>
