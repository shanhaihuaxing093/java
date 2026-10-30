<template>
  <div class="shell">
    <!-- 海底装饰层 -->
    <div class="shell-bubbles" aria-hidden="true">
      <i v-for="b in bubbles" :key="b.id" :style="b.style"></i>
    </div>
    <div class="shell-weed" v-for="w in weeds" :key="'w' + w.id" :style="w.style" aria-hidden="true"></div>
    <div class="shell-floor" aria-hidden="true"></div>

    <!-- 顶栏：品牌 + 导航 + 搜索 + 用户 -->
    <AppTopBar
      :user="user"
      class="layer"
      @toggle="drawer = !drawer"
      @navigate="onNavigate"
      @logout="onLogout"
      @refresh="syncProfile"
    />

    <div class="layout layer">
      <AppSideBar :open="drawer" :user="user" @navigate="onNavigate" @close="drawer = false" />

      <main class="main">
        <!-- ① 欢迎横幅（登录页海绵卡片放大版） -->
        <section class="hero skin">
          <div class="hero-left">
            <p class="hero-hi">
              {{ greeting }}，<b>{{ displayName }}</b>
              <span class="wave">👋</span>
            </p>
            <h1 class="hero-title">欢迎回到蟹堡王</h1>
            <p class="hero-sub">{{ today }} · 比奇堡海水 {{ overview.waterTemp }} · {{ overview.weather }}</p>

            <div class="hero-actions">
              <button class="pk-btn" type="button" @click="onNavigate({ to: '/users', built: true })">
                查看居民名单 🐚
              </button>
              <button class="pk-btn ghost" type="button" :disabled="loading" @click="reload">
                {{ loading ? '刷新中…' : '刷新数据 🔄' }}
              </button>
            </div>
          </div>

          <div class="hero-right">
            <SpongeBob class="hero-bob" />
          </div>
        </section>

        <!-- ② 概览数字 -->
        <section class="stats">
          <article v-for="s in statCards" :key="s.label" class="stat board">
            <span class="stat-icon">{{ s.icon }}</span>
            <div class="stat-body">
              <b class="stat-num">{{ s.value }}</b>
              <small class="stat-label">{{ s.label }}</small>
            </div>
            <span class="stat-trend" :class="s.tone">{{ s.trend }}</span>
          </article>
        </section>

        <!-- ③ 快捷入口 + 公告 -->
        <div class="cols">
          <section class="panel board">
            <h2 class="panel-head">
              <span>⚡ 快捷入口</span>
            </h2>
            <div class="quick">
              <button
                v-for="q in QUICK_ACTIONS"
                :key="q.key"
                class="quick-item"
                type="button"
                @click="onNavigate(q)"
              >
                <span class="qi-icon">{{ q.icon }}</span>
                <b>{{ q.title }}</b>
                <small>{{ q.desc }}</small>
              </button>
            </div>
          </section>

          <section class="panel board">
            <h2 class="panel-head">
              <span>📢 比奇堡公告</span>
              <button class="panel-more" type="button" @click="toast('🚧 公告列表页建设中', 'info')">
                更多 →
              </button>
            </h2>
            <ul class="notice">
              <li v-for="n in notices" :key="n.id">
                <span class="n-icon">{{ n.icon }}</span>
                <span class="n-text">{{ n.text }}</span>
              </li>
              <li v-if="!notices.length" class="empty">🫧 暂无公告</li>
            </ul>
          </section>
        </div>

        <!-- ④ 最近居民 -->
        <section class="panel board">
          <h2 class="panel-head">
            <span>🐚 最近加入的居民</span>
            <button class="panel-more" type="button" @click="onNavigate({ to: '/users', built: true })">
              查看全部 →
            </button>
          </h2>

          <div class="residents">
            <article v-for="u in residents" :key="u.id" class="resident">
              <span class="r-avatar">{{ u.avatar || emojiOf(u.username) }}</span>
              <div class="r-main">
                <b>{{ u.nickname || u.username }}</b>
                <small>@{{ u.username }}</small>
              </div>
              <span class="pk-tag" :class="u.status === 1 ? 'on' : 'off'">
                {{ u.status === 1 ? '正常' : '禁用' }}
              </span>
            </article>
            <p v-if="!residents.length" class="empty">🫧 还没有居民数据</p>
          </div>
        </section>

        <p class="footnote">
          <template v-if="usingMock">
            🫧 部分区域是本地示例数据（<code>/api/home/*</code> 后端接口尚未实现，接口就绪后自动切换）
          </template>
          <template v-else>✅ 全部数据来自后端接口</template>
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
const drawer = ref(false)
const mock = ref({ overview: true, notices: true, residents: true })

/* ---------------- 装饰层（随机但一次生成，避免重渲染抖动） ---------------- */
const bubbles = Array.from({ length: 14 }, (_, i) => {
  const size = 8 + Math.random() * 20
  return {
    id: i,
    style: {
      width: size + 'px',
      height: size + 'px',
      left: Math.random() * 100 + '%',
      animationDuration: 10 + Math.random() * 9 + 's',
      animationDelay: '-' + (Math.random() * 12).toFixed(1) + 's'
    }
  }
})

const weeds = [
  { id: 1, style: { left: '3%', height: '110px', animationDelay: '0s' } },
  { id: 2, style: { left: '9%', height: '76px', animationDelay: '.7s' } },
  { id: 3, style: { left: '88%', height: '132px', animationDelay: '1.2s' } },
  { id: 4, style: { left: '95%', height: '88px', animationDelay: '.4s' } }
]

/* ---------------- 展示数据 ---------------- */
const displayName = computed(() => user.value.nickname || user.value.username || '比奇堡居民')

const hour = new Date().getHours()
const greeting =
  hour < 6 ? '夜深了' : hour < 11 ? '早上好' : hour < 14 ? '中午好' : hour < 18 ? '下午好' : '晚上好'
const today = new Date().toLocaleDateString('zh-CN', {
  month: 'long',
  day: 'numeric',
  weekday: 'long'
})

const statCards = computed(() => [
  { icon: '🐚', label: '比奇堡居民', value: overview.value.residents ?? '-', trend: '在册', tone: 'flat' },
  { icon: '🍔', label: '今日蟹黄堡', value: overview.value.krabby ?? '-', trend: '↑ 12%', tone: 'up' },
  { icon: '🧽', label: '在岗员工', value: overview.value.online ?? '-', trend: '实时', tone: 'flat' },
  { icon: '🌡️', label: '海水温度', value: overview.value.waterTemp ?? '-', trend: overview.value.weather || '舒适', tone: 'flat' }
])

const usingMock = computed(() => Object.values(mock.value).some(Boolean))

// 后端没有 avatar 字段时按用户名给个稳定的小图标
const EMOJI = ['🧽', '⭐', '🦑', '🦀', '🐟', '🐙', '🦐', '🐿️']
function emojiOf(name = '') {
  let sum = 0
  for (const ch of name) sum += ch.charCodeAt(0)
  return EMOJI[sum % EMOJI.length]
}

/* ---------------- 数据加载 ---------------- */
async function loadAll() {
  loading.value = true
  try {
    const [ov, nt, rs] = await Promise.all([
      fetchOverview(),
      fetchNotices(),
      fetchResidents('', 6)
    ])
    overview.value = ov || {}
    mock.value.overview = !!ov?._mock
    notices.value = nt?.list || []
    mock.value.notices = !!nt?._mock
    residents.value = rs?.list || []
    mock.value.residents = !!rs?._mock
  } finally {
    loading.value = false
  }
}

// 受保护接口：校验令牌有效性并同步最新资料
async function syncProfile(silent = false) {
  try {
    const res = await profile()
    if (res.code === 200) {
      user.value = res.data || {}
      localStorage.setItem('bob_user', JSON.stringify(res.data || {}))
      if (!silent) toast('✅ 信息已同步', 'ok')
    } else if (!silent) {
      toast('❌ ' + (res.msg || '获取信息失败'), 'err')
    }
  } catch (e) {
    if (!silent) toast('❌ ' + e.message, 'err')
  }
}

function reload() {
  loadAll()
  syncProfile()
}

onMounted(async () => {
  // 先用本地缓存渲染，避免白屏等接口
  try {
    user.value = JSON.parse(localStorage.getItem('bob_user') || '{}')
  } catch {
    user.value = {}
  }
  await loadAll()
  await syncProfile(true)
})

/* ---------------- 交互 ---------------- */
function onNavigate(item) {
  if (!item) return
  drawer.value = false
  if (item.built === false) {
    toast(`🚧 「${item.title}」页面建设中，敬请期待`, 'info')
    return
  }
  if (item.to && item.to !== router.currentRoute.value.path) router.push(item.to)
}

async function onLogout() {
  try {
    await logout() // 通知后端作废令牌
  } catch {
    /* 后端不可用也要能退出 */
  }
  clearSession()
  router.replace('/login')
}
</script>

<style scoped>
.layout {
  display: flex;
  align-items: flex-start;
  flex: 1;
  width: 100%;
  max-width: 1440px;
  margin: 0 auto;
}

.main {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 18px 22px 48px;
}

/* ---------------- ① 欢迎横幅 ---------------- */
.hero {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 26px 30px;
}
.hero-left { flex: 1; min-width: 0; }
.hero-hi { font-size: 15px; font-weight: 800; color: #6b4a00; }
.hero-hi b { font-size: 17px; }
.wave { display: inline-block; transform-origin: 70% 80%; animation: wave 2.2s ease-in-out infinite; }
@keyframes wave {
  0%, 60%, 100% { transform: rotate(0); }
  70%, 90% { transform: rotate(16deg); }
  80% { transform: rotate(-8deg); }
}
.hero-title {
  margin-top: 2px;
  font-size: 30px;
  font-weight: 800;
  letter-spacing: 2px;
  text-shadow: 2px 2px 0 #fff, 4px 4px 0 rgba(0, 0, 0, .13);
}
.hero-sub { margin-top: 6px; font-size: 13px; color: #7a5400; }
.hero-actions { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 18px; }

.hero-right {
  flex: none;
  display: grid;
  place-items: center;
  width: 168px;
}
/* SpongeBob 组件自带负上边距（为登录页卡片顶部探头设计），这里抵消掉 */
.hero-bob { width: 168px; margin: 0; }
.hero-bob :deep(.bob) { width: 168px; margin: 0; animation-duration: 4.4s; }

/* ---------------- ② 概览数字 ---------------- */
.stats {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
}
.stat {
  display: flex;
  align-items: center;
  gap: 11px;
  padding: 15px 16px;
}
.stat-icon {
  display: grid;
  place-items: center;
  width: 44px; height: 44px;
  flex: none;
  font-size: 22px;
  background: rgba(255, 217, 15, .5);
  border: 3px solid rgba(169, 123, 0, .45);
  border-radius: 14px;
}
.stat-body { display: flex; flex-direction: column; min-width: 0; flex: 1; line-height: 1.2; }
.stat-num { font-size: 25px; font-weight: 800; }
.stat-label { font-size: 12px; font-weight: 700; color: #7a5400; }
.stat-trend {
  flex: none;
  padding: 3px 8px;
  font-size: 11px; font-weight: 800;
  border-radius: 9px;
  background: rgba(169, 123, 0, .14);
  color: #7a5400;
}
.stat-trend.up { background: #c8f0cd; color: var(--green-dark); }

/* ---------------- ③ 面板通用 ---------------- */
.cols {
  display: grid;
  grid-template-columns: 1.15fr 1fr;
  gap: 16px;
  align-items: start;
}
.panel { padding: 16px 18px; }
.panel-head {
  display: flex;
  align-items: center;
  gap: 8px;
  padding-bottom: 11px;
  margin-bottom: 13px;
  font-size: 16px;
  font-weight: 800;
  border-bottom: 3px dashed rgba(169, 123, 0, .45);
}
.panel-more {
  margin-left: auto;
  padding: 4px 11px;
  font-family: inherit;
  font-size: 12px; font-weight: 800;
  color: var(--ocean-1);
  cursor: pointer;
  background: #fff;
  border: 2px solid var(--ocean-1);
  border-radius: 12px;
}
.panel-more:hover { background: var(--ocean-3); }

/* 快捷入口 */
.quick { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; }
.quick-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  padding: 14px 8px;
  font-family: inherit;
  color: var(--ink);
  cursor: pointer;
  background: var(--white);
  border: 3px solid rgba(169, 123, 0, .5);
  border-radius: 16px;
  transition: .15s;
}
.quick-item:hover {
  background: var(--sponge);
  border-color: var(--sponge-border);
  transform: translateY(-2px);
  box-shadow: 0 5px 0 var(--sponge-border);
}
.qi-icon { font-size: 23px; }
.quick-item b { font-size: 13px; }
.quick-item small { font-size: 11px; color: #7a5400; }

/* 公告 */
.notice { list-style: none; display: flex; flex-direction: column; gap: 9px; }
.notice li {
  display: flex;
  gap: 9px;
  align-items: flex-start;
  padding: 10px 12px;
  font-size: 13px;
  line-height: 1.55;
  background: rgba(63, 196, 232, .14);
  border: 2px dashed rgba(169, 123, 0, .4);
  border-radius: 14px;
}
.n-icon { flex: none; font-size: 15px; }
.n-text { flex: 1; }

/* ---------------- ④ 居民 ---------------- */
.residents {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 10px;
}
.resident {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  background: var(--white);
  border: 2px solid rgba(169, 123, 0, .36);
  border-radius: 14px;
  transition: .13s;
}
.resident:hover { border-color: var(--sponge-border); background: rgba(255, 217, 15, .16); }
.r-avatar {
  display: grid;
  place-items: center;
  width: 38px; height: 38px;
  flex: none;
  font-size: 20px;
  background: var(--sponge);
  border: 3px solid var(--sponge-border);
  border-radius: 50%;
}
.r-main { display: flex; flex-direction: column; min-width: 0; flex: 1; line-height: 1.25; }
.r-main b { font-size: 14px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.r-main small { font-size: 11px; color: #7a5400; }

.empty { padding: 20px; font-size: 13px; font-weight: 700; text-align: center; color: #7a5400; }

.footnote {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  font-size: 12px;
  font-weight: 700;
  color: var(--white);
  text-shadow: 0 1px 3px rgba(0, 0, 0, .45);
  padding-bottom: 8px;
}
.footnote code {
  padding: 1px 5px;
  font-family: Consolas, monospace;
  background: rgba(255, 255, 255, .18);
  border-radius: 6px;
}

/* ---------------- 响应式 ---------------- */
@media (max-width: 1180px) {
  .stats { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 900px) {
  .cols { grid-template-columns: 1fr; }
  .hero-title { font-size: 25px; }
  .hero-right { width: 132px; }
  .hero-bob, .hero-bob :deep(.bob) { width: 132px; }
}

@media (max-width: 768px) {
  .main { padding: 14px 13px 36px; gap: 13px; }
  .hero { flex-direction: column-reverse; text-align: center; padding: 22px 18px; gap: 6px; }
  .hero-actions { justify-content: center; }
  .hero-right { width: 116px; }
  .hero-bob, .hero-bob :deep(.bob) { width: 116px; }
  .quick { grid-template-columns: repeat(3, 1fr); }
  .panel { padding: 14px; }
}

@media (max-width: 480px) {
  .hero-title { font-size: 21px; letter-spacing: 1px; }
  .hero-hi { font-size: 13px; }
  .hero-hi b { font-size: 15px; }
  .stats { gap: 10px; }
  .stat { padding: 12px; gap: 8px; }
  .stat-icon { width: 36px; height: 36px; font-size: 18px; border-width: 2px; }
  .stat-num { font-size: 20px; }
  .stat-trend { display: none; }
  .quick { grid-template-columns: repeat(2, 1fr); }
  .residents { grid-template-columns: 1fr; }
}

@media (prefers-reduced-motion: reduce) {
  .wave { animation: none; }
  .quick-item:hover { transform: none; }
}
</style>
