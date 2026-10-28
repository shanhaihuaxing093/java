<template>
  <div class="home-app">
    <!-- 背景气泡（装饰，不影响交互） -->
    <div class="home-bubbles" aria-hidden="true">
      <span v-for="b in bubbles" :key="b.id" :style="b.style"></span>
    </div>

    <AppTopBar
      :user="user"
      @toggle="asideOpen = !asideOpen"
      @logout="onLogout"
      @refresh="loadProfile"
      @select="onSelect"
    />

    <div class="home-body">
      <AppSideBar :open="asideOpen" @navigate="onNavigate" @close="asideOpen = false" />

      <main class="home-content">
        <!-- 欢迎横幅 -->
        <section class="hero">
          <div class="hero-text">
            <p class="hero-hi">{{ greeting }}，{{ displayName }}！</p>
            <h1 class="hero-title">🍍 欢迎回到蟹堡王后台</h1>
            <p class="hero-sub">
              今天是 {{ today }} · 海水 {{ overview.waterTemp }} · {{ overview.weather }}
            </p>
            <div class="hero-actions">
              <button class="bob-btn primary" type="button" @click="onNavigate({ to: '/users', built: true })">
                查看居民名单 🐚
              </button>
              <button class="bob-btn ghost" type="button" :disabled="loading" @click="reload">
                {{ loading ? '刷新中…' : '刷新数据 🔄' }}
              </button>
            </div>
          </div>
          <div class="hero-bob"><SpongeBob /></div>
        </section>

        <!-- 概览卡片 -->
        <section class="stats">
          <div v-for="s in statCards" :key="s.label" class="stat-card">
            <span class="stat-icon">{{ s.icon }}</span>
            <b class="stat-num">{{ s.value }}</b>
            <span class="stat-label">{{ s.label }}</span>
          </div>
        </section>

        <div class="grid">
          <!-- 快捷入口 -->
          <section class="panel">
            <h2 class="panel-title">⚡ 快捷入口</h2>
            <div class="quick">
              <button
                v-for="q in QUICK_ACTIONS"
                :key="q.key"
                class="quick-item"
                type="button"
                @click="onNavigate(q)"
              >
                <span class="quick-icon">{{ q.icon }}</span>
                <b>{{ q.title }}</b>
                <small>{{ q.desc }}</small>
              </button>
            </div>
          </section>

          <!-- 公告 -->
          <section class="panel">
            <h2 class="panel-title">📢 比奇堡公告</h2>
            <ul class="notice">
              <li v-for="n in notices" :key="n.id">
                <span class="notice-icon">{{ n.icon }}</span>
                <span>{{ n.text }}</span>
              </li>
              <li v-if="!notices.length" class="empty">🫧 暂无公告</li>
            </ul>
          </section>
        </div>

        <!-- 最近居民 -->
        <section class="panel">
          <h2 class="panel-title">
            🐚 最近居民
            <button class="panel-more" type="button" @click="onNavigate({ to: '/users', built: true })">
              查看全部 →
            </button>
          </h2>

          <div class="resident-list">
            <div v-for="u in residents" :key="u.id" class="resident">
              <span class="resident-avatar">{{ u.avatar }}</span>
              <div class="resident-main">
                <b>{{ u.nickname || u.username }}</b>
                <small>@{{ u.username }} · {{ u.createTime }}</small>
              </div>
              <span class="tag" :class="u.status === 1 ? 'on' : 'off'">
                {{ u.status === 1 ? '正常' : '禁用' }}
              </span>
            </div>
            <div v-if="!residents.length" class="empty">🫧 还没有居民数据</div>
          </div>
        </section>

        <p class="foot-note">
          <span v-if="usingMock">🫧 当前展示的是本地示例数据（后端接口 <code>/api/home/*</code> 尚未实现，接口就绪后会自动切换）</span>
          <span v-else>✅ 数据来自后端接口</span>
          <span class="dot">·</span>
          <span>令牌有效期至 {{ user.tokenExpire || '-' }}</span>
        </p>
      </main>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import AppTopBar from '../components/AppTopBar.vue'
import AppSideBar from '../components/AppSideBar.vue'
import SpongeBob from '../components/SpongeBob.vue'
import { QUICK_ACTIONS } from '../config/nav'
import { fetchNotices, fetchOverview, fetchResidents } from '../api/home'
import { profile, logout } from '../api/auth'
import { clearSession } from '../api/request'
import { toast } from '../utils/toast'

const router = useRouter()

const user = ref({})
const overview = ref({})
const notices = ref([])
const residents = ref([])
const loading = ref(false)
const asideOpen = ref(false)
const mockFlags = ref({ overview: true, notices: true, residents: true })

const bubbles = Array.from({ length: 12 }, (_, i) => ({
  id: i,
  style: {
    width: 8 + Math.random() * 22 + 'px',
    height: 8 + Math.random() * 22 + 'px',
    left: Math.random() * 100 + '%',
    animationDuration: 9 + Math.random() * 9 + 's',
    animationDelay: '-' + (Math.random() * 12).toFixed(1) + 's'
  }
}))

const displayName = computed(() => user.value.nickname || user.value.username || '比奇堡居民')

const hour = new Date().getHours()
const greeting = hour < 6 ? '夜深了' : hour < 11 ? '早上好' : hour < 14 ? '中午好' : hour < 18 ? '下午好' : '晚上好'
const today = new Date().toLocaleDateString('zh-CN', { month: 'long', day: 'numeric', weekday: 'long' })

const statCards = computed(() => [
  { icon: '🐚', label: '比奇堡居民', value: overview.value.residents ?? '-' },
  { icon: '🍔', label: '今日蟹黄堡', value: overview.value.krabby ?? '-' },
  { icon: '🧽', label: '在岗员工', value: overview.value.online ?? '-' },
  { icon: '🌡️', label: '海水温度', value: overview.value.waterTemp ?? '-' }
])

const usingMock = computed(() => Object.values(mockFlags.value).some(Boolean))

/* ---------------- 数据加载 ---------------- */

async function loadAll() {
  loading.value = true
  try {
    const [ov, nt, rs] = await Promise.all([fetchOverview(), fetchNotices(), fetchResidents('', 5)])
    overview.value = ov
    mockFlags.value.overview = !!ov._mock
    notices.value = nt.list
    mockFlags.value.notices = !!nt._mock
    residents.value = rs.list
    mockFlags.value.residents = !!rs._mock
  } finally {
    loading.value = false
  }
}

/** 受保护接口：带 Authorization 头校验令牌，并同步最新用户信息 */
async function loadProfile() {
  try {
    const res = await profile()
    if (res.code === 200) {
      user.value = res.data
      localStorage.setItem('bob_user', JSON.stringify(res.data))
      toast('✅ 信息已同步', 'ok')
    } else {
      toast('❌ ' + (res.msg || '获取信息失败'), 'err')
    }
  } catch (e) {
    toast('❌ ' + e.message, 'err')
  }
}

function reload() {
  loadAll()
  loadProfile()
}

onMounted(async () => {
  const cached = localStorage.getItem('bob_user')
  if (cached) {
    try {
      user.value = JSON.parse(cached)
    } catch {
      user.value = {}
    }
  }
  await loadAll()
  await loadProfile()
})

/* ---------------- 交互 ---------------- */

function onNavigate(item) {
  if (!item) return
  if (item.built === false) {
    toast(`🚧 「${item.title}」页面建设中，敬请期待`, 'info')
    return
  }
  if (item.to && item.to !== router.currentRoute.value.path) router.push(item.to)
}

function onSelect(item) {
  if (!item) return
  if (item.type === 'keyword') {
    toast(`🫧 没找到「${item.keyword}」的直达入口，试试点搜索结果吧`, 'info')
    return
  }
  onNavigate(item)
}

async function onLogout() {
  try {
    await logout() // 通知后端作废令牌
  } catch (e) {
    /* 后端不可用时也要清本地，保证能退出 */
  }
  clearSession()
  router.replace('/login')
}
</script>

<style scoped>
.home-app {
  position: relative;
  min-height: 100vh;
  background: linear-gradient(180deg, var(--ocean-1) 0%, var(--ocean-2) 55%, var(--ocean-3) 100%);
}

/* 背景气泡 */
.home-bubbles { position: fixed; inset: 0; overflow: hidden; pointer-events: none; z-index: 0; }
.home-bubbles span {
  position: absolute;
  bottom: -80px;
  border-radius: 50%;
  background: radial-gradient(circle at 30% 30%, rgba(255, 255, 255, .9), rgba(255, 255, 255, .12) 60%, rgba(255, 255, 255, .02));
  border: 1px solid rgba(255, 255, 255, .4);
  animation: home-rise linear infinite;
}
@keyframes home-rise {
  0%   { transform: translateY(0) scale(.6); opacity: 0; }
  10%  { opacity: .7; }
  100% { transform: translateY(-110vh) translateX(24px) scale(1.1); opacity: 0; }
}

.home-body { position: relative; z-index: 1; display: flex; align-items: flex-start; }

.home-content {
  flex: 1;
  min-width: 0;
  padding: 18px 22px 40px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* ---------- 欢迎横幅（沿用登录页的海绵卡片风格） ---------- */
.hero {
  display: flex;
  align-items: center;
  gap: 18px;
  padding: 24px 28px;
  color: var(--ink);
  background:
    radial-gradient(circle at 20% 30%, var(--sponge-deep) 0 6px, transparent 7px),
    radial-gradient(circle at 72% 22%, var(--sponge-deep) 0 5px, transparent 6px),
    radial-gradient(circle at 88% 70%, var(--sponge-deep) 0 8px, transparent 9px),
    linear-gradient(160deg, #ffe95c, var(--sponge) 60%, var(--sponge-dark));
  border: 5px solid var(--sponge-border);
  border-radius: 28px;
  box-shadow: 0 12px 0 var(--sponge-border), 0 22px 40px rgba(0, 0, 0, .35);
}
.hero-text { flex: 1; min-width: 0; }
.hero-hi { font-size: 15px; font-weight: 800; color: #6b4a00; }
.hero-title {
  margin-top: 4px;
  font-size: 26px; font-weight: 800; letter-spacing: 1px;
  text-shadow: 2px 2px 0 #fff, 4px 4px 0 rgba(0, 0, 0, .12);
}
.hero-sub { margin-top: 6px; font-size: 13px; color: #7a5400; }
.hero-actions { display: flex; gap: 10px; margin-top: 16px; flex-wrap: wrap; }
.hero-bob { width: 150px; flex: none; }
.hero-bob :deep(.bob) { width: 150px; margin: 0; }

/* 按钮：全局 .btn 是块级满宽，这里要行内小块，单独定义 */
.bob-btn {
  padding: 11px 20px;
  font-size: 15px; font-weight: 800; font-family: inherit;
  color: var(--ink); cursor: pointer;
  border: 4px solid var(--sponge-border); border-radius: 18px;
  transition: .12s;
}
.bob-btn.primary { background: linear-gradient(180deg, #7ee081, var(--green)); box-shadow: 0 6px 0 var(--green-dark); }
.bob-btn.primary:active { transform: translateY(4px); box-shadow: 0 2px 0 var(--green-dark); }
.bob-btn.ghost { background: #fffdf5; box-shadow: 0 6px 0 var(--sponge-border); }
.bob-btn.ghost:active { transform: translateY(4px); box-shadow: 0 2px 0 var(--sponge-border); }
.bob-btn:disabled { opacity: .6; cursor: not-allowed; }

/* ---------- 概览卡片 ---------- */
.stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; }
.stat-card {
  display: flex; flex-direction: column; align-items: center; gap: 4px;
  padding: 16px 12px;
  background: rgba(255, 253, 245, .94);
  border: 4px solid var(--sponge-border);
  border-radius: 20px;
  box-shadow: 0 6px 0 rgba(169, 123, 0, .55), 0 12px 22px rgba(0, 0, 0, .22);
}
.stat-icon { font-size: 24px; }
.stat-num { font-size: 26px; font-weight: 800; line-height: 1.1; }
.stat-label { font-size: 12px; color: #7a5400; font-weight: 700; }

/* ---------- 面板 ---------- */
.grid { display: grid; grid-template-columns: 1.25fr 1fr; gap: 16px; align-items: start; }
.panel {
  padding: 16px 18px;
  background: rgba(255, 253, 245, .94);
  border: 4px solid var(--sponge-border);
  border-radius: 20px;
  box-shadow: 0 6px 0 rgba(169, 123, 0, .55), 0 12px 22px rgba(0, 0, 0, .22);
}
.panel-title {
  display: flex; align-items: center; gap: 8px;
  font-size: 16px; font-weight: 800;
  padding-bottom: 10px; margin-bottom: 12px;
  border-bottom: 3px dashed rgba(169, 123, 0, .45);
}
.panel-more {
  margin-left: auto;
  padding: 4px 10px;
  font-size: 12px; font-family: inherit; font-weight: 800;
  color: var(--ocean-1); cursor: pointer;
  background: #fff; border: 2px solid var(--ocean-1); border-radius: 12px;
}
.panel-more:hover { background: var(--ocean-3); }

/* 快捷入口 */
.quick { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; }
.quick-item {
  display: flex; flex-direction: column; align-items: center; gap: 3px;
  padding: 12px 8px;
  font-family: inherit; cursor: pointer;
  background: #fffdf5;
  border: 3px solid rgba(169, 123, 0, .5);
  border-radius: 16px;
  transition: .15s;
}
.quick-item:hover { background: var(--sponge); border-color: var(--sponge-border); transform: translateY(-2px); }
.quick-icon { font-size: 22px; }
.quick-item b { font-size: 13px; }
.quick-item small { font-size: 11px; color: #7a5400; }

/* 公告 */
.notice { list-style: none; display: flex; flex-direction: column; gap: 10px; }
.notice li {
  display: flex; gap: 8px; align-items: flex-start;
  font-size: 13px; line-height: 1.5;
  padding: 10px 12px;
  background: rgba(63, 196, 232, .14);
  border: 2px dashed rgba(169, 123, 0, .4);
  border-radius: 14px;
}
.notice-icon { font-size: 16px; }

/* 居民列表 */
.resident-list { display: flex; flex-direction: column; gap: 8px; }
.resident {
  display: flex; align-items: center; gap: 12px;
  padding: 10px 12px;
  background: #fffdf5;
  border: 2px solid rgba(169, 123, 0, .35);
  border-radius: 14px;
}
.resident-avatar {
  width: 40px; height: 40px; flex: none;
  display: flex; align-items: center; justify-content: center;
  font-size: 22px;
  background: var(--sponge);
  border: 3px solid var(--sponge-border);
  border-radius: 50%;
}
.resident-main { display: flex; flex-direction: column; min-width: 0; flex: 1; }
.resident-main b { font-size: 14px; }
.resident-main small { font-size: 12px; color: #7a5400; }
.tag { padding: 3px 10px; border-radius: 10px; font-size: 12px; font-weight: 700; }
.tag.on { background: #c8f0cd; color: var(--green-dark); }
.tag.off { background: #ffd9d3; color: var(--red); }

.empty { text-align: center; padding: 18px; font-size: 13px; color: #7a5400; font-weight: 700; }

.foot-note {
  display: flex; align-items: center; gap: 6px; flex-wrap: wrap;
  font-size: 12px; font-weight: 700; color: #fffdf5;
  text-shadow: 0 1px 3px rgba(0, 0, 0, .45);
}
.foot-note code {
  font-family: Consolas, monospace;
  background: rgba(255, 255, 255, .18);
  padding: 1px 5px; border-radius: 6px;
}
.dot { opacity: .7; }

/* ---------- 响应式 ---------- */
@media (max-width: 1100px) {
  .stats { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 768px) {
  .home-content { padding: 14px 14px 32px; }
  .grid { grid-template-columns: 1fr; }
  .hero { flex-direction: column; text-align: center; padding: 20px; }
  .hero-actions { justify-content: center; }
  .hero-bob { width: 120px; }
  .hero-bob :deep(.bob) { width: 120px; }
  .quick { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 480px) {
  .hero-title { font-size: 21px; }
  .stats { grid-template-columns: repeat(2, 1fr); gap: 10px; }
  .stat-num { font-size: 22px; }
  .panel { padding: 14px; }
}

@media (prefers-reduced-motion: reduce) {
  .home-bubbles span { animation: none !important; }
}
</style>
