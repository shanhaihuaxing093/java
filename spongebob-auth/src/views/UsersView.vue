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
            </tr>
            <tr v-if="!records.length">
              <td colspan="6" class="empty">🫧 没有找到居民</td>
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
  </OceanBg>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import OceanBg from '../components/OceanBg.vue'
import { userPage } from '../api/user'

const records = ref([])
const total = ref(0)
const current = ref(1)
const pages = ref(1)
const keyword = ref('')
const loading = ref(false)
const tips = ref('')
const tipsType = ref('')

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
</script>

<style scoped>
.wide { max-width: 640px; }
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
  max-height: 300px;
  overflow: auto;
}
table { width: 100%; border-collapse: collapse; font-size: 13px; }
th, td { padding: 8px 6px; text-align: left; border-bottom: 1px solid rgba(169, 123, 0, .3); }
th { color: #7a5400; font-weight: 800; }
td.time { font-size: 12px; color: #7a5400; }
td.empty { text-align: center; padding: 20px; color: #7a5400; }
.tag { padding: 2px 8px; border-radius: 10px; font-size: 12px; font-weight: 700; }
.tag.on { background: #c8f0cd; color: var(--green-dark); }
.tag.off { background: #ffd9d3; color: var(--red); }

.pager {
  display: flex; align-items: center; justify-content: space-between;
  margin-top: 14px; gap: 8px;
}
.pinfo { font-size: 13px; color: #7a5400; font-weight: 700; }
.back { display: block; margin-top: 14px; text-align: center; font-size: 14px; color: #8a5a00; font-weight: 700; }
</style>
