<template>
  <OceanBg>
    <main class="sponge-card home">
      <SpongeBob />
      <h1 class="title">🍔 蟹堡王后台</h1>
      <p class="subtitle">欢迎回来，{{ user.nickname || user.username }}！</p>

      <div class="info">
        <div class="line"><span>用户编号</span><b>{{ user.id ?? '-' }}</b></div>
        <div class="line"><span>用户名</span><b>{{ user.username || '-' }}</b></div>
        <div class="line"><span>昵称</span><b>{{ user.nickname || '-' }}</b></div>
        <div class="line"><span>注册时间</span><b>{{ user.createTime || '-' }}</b></div>
        <div class="line"><span>登录令牌</span><b class="token">{{ shortToken }}</b></div>
        <div class="line"><span>令牌有效期至</span><b>{{ user.tokenExpire || '-' }}</b></div>
      </div>

      <div class="tips" :class="tipsType">
        {{ tips || '🫧 后端连通状态：' + apiStatus }}
      </div>

      <button class="btn" :disabled="loading" @click="loadProfile">
        {{ loading ? '请求中...' : '刷新我的信息（需登录）' }}
      </button>
      <button class="btn ghost" @click="goUsers">查看居民名单 🐚</button>
      <button class="btn ghost" @click="onLogout">退出登录</button>
    </main>
  </OceanBg>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import OceanBg from '../components/OceanBg.vue'
import SpongeBob from '../components/SpongeBob.vue'
import { hello, profile, logout } from '../api/auth'
import { clearSession } from '../api/request'

const router = useRouter()
const user = ref({})
const tips = ref('')
const tipsType = ref('')
const apiStatus = ref('未知')
const loading = ref(false)

// 令牌太长，展示前 8 位即可
const shortToken = computed(() => {
  const t = localStorage.getItem('bob_token') || ''
  return t ? t.substring(0, 8) + '…' : '无'
})

onMounted(async () => {
  const cached = localStorage.getItem('bob_user')
  if (cached) {
    try {
      user.value = JSON.parse(cached)
    } catch {
      user.value = {}
    }
  }
  // 公开接口：验证后端是否活着
  try {
    const res = await hello()
    apiStatus.value = res.code === 200 ? '正常 ✅' : '异常 ⚠'
  } catch (e) {
    apiStatus.value = '不可用 ❌'
    tipsType.value = 'err'
    tips.value = e.message
  }
  await loadProfile()
})

// 受保护接口：带 Authorization 头，后端校验令牌后返回当前用户
async function loadProfile() {
  loading.value = true
  try {
    const res = await profile()
    if (res.code === 200) {
      user.value = res.data
      localStorage.setItem('bob_user', JSON.stringify(res.data))
      tipsType.value = 'ok'
      tips.value = '✅ 令牌校验通过，已同步最新用户信息'
    } else {
      tipsType.value = 'err'
      tips.value = '❌ ' + (res.msg || '获取信息失败')
    }
  } catch (e) {
    tipsType.value = 'err'
    tips.value = '❌ ' + e.message
  } finally {
    loading.value = false
  }
}

function goUsers() {
  router.push('/users')
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
.home .info {
  margin-top: 18px;
  background: rgba(255, 255, 255, .55);
  border: 3px dashed var(--sponge-border);
  border-radius: 18px;
  padding: 14px 16px;
}
.line { display: flex; justify-content: space-between; font-size: 14px; padding: 5px 0; }
.line span { color: #7a5400; }
.line b { color: var(--ink); }
.token { font-family: Consolas, monospace; font-size: 12px; }
.btn.ghost {
  background: linear-gradient(180deg, #ffe95c, var(--sponge-dark));
  box-shadow: 0 7px 0 var(--sponge-border);
  margin-top: 12px;
}
.btn.ghost:active { box-shadow: 0 2px 0 var(--sponge-border); }
</style>
