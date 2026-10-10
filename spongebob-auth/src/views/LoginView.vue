<template>
  <OceanBg>
    <main class="sponge-card">
      <SpongeBob />
      <h1 class="title">欢迎来到比奇堡</h1>
      <p class="subtitle">🍍 蟹堡王员工通道 · 请出示你的工牌</p>

      <form @submit.prevent="onSubmit">
        <div class="field">
          <label for="username">用户名</label>
          <div class="input-wrap">
            <span class="icon">🧽</span>
            <input id="username" v-model.trim="form.username" type="text" placeholder="请输入用户名" autocomplete="off" />
          </div>
        </div>

        <div class="field">
          <label for="password">密码</label>
          <div class="input-wrap">
            <span class="icon">🔑</span>
            <input id="password" v-model="form.password" type="password" placeholder="请输入密码" />
          </div>
        </div>

        <div class="row">
          <label><input v-model="remember" type="checkbox" /> 记住我</label>
          <a href="javascript:void(0)" @click="forgot">忘记密码？</a>
        </div>

        <button class="btn" type="submit" :disabled="loading">
          {{ loading ? '潜水中...' : '进入蟹堡王 🍔' }}
        </button>

        <div class="tips" :class="tipsType">{{ tips }}</div>
      </form>

      <div class="switch">
        还没有账号？
        <router-link to="/register">去注册</router-link>
      </div>
    </main>
  </OceanBg>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import OceanBg from '../components/OceanBg.vue'
import SpongeBob from '../components/SpongeBob.vue'
import { login } from '../api/auth'

const router = useRouter()
const route = useRoute()
const form = reactive({ username: '', password: '' })
const remember = ref(true)
const loading = ref(false)
const tips = ref('')
const tipsType = ref('')

// 记住我：上次登录的用户名回填
onMounted(() => {
  const saved = localStorage.getItem('bob_username')
  if (saved) form.username = saved
})

async function onSubmit() {
  tips.value = ''
  tipsType.value = ''
  if (!form.username || !form.password) {
    tipsType.value = 'err'
    tips.value = '⚠ 用户名或密码不能为空'
    return
  }
  loading.value = true
  try {
    const res = await login({ username: form.username, password: form.password })
    if (res.code === 200) {
      tipsType.value = 'ok'
      tips.value = '✅ 登录成功，正在潜入比奇堡...'
      const user = res.data || {}
      // 令牌单独存一份，request.js 会自动把它放进 Authorization 请求头
      if (user.token) localStorage.setItem('bob_token', user.token)
      localStorage.setItem('bob_user', JSON.stringify(user))
      if (remember.value) localStorage.setItem('bob_username', form.username)
      // 若之前是被路由守卫拦下来的，登录后回到原目标页
      setTimeout(() => router.push(route.query.redirect || '/home'), 500)
    } else {
      tipsType.value = 'err'
      tips.value = '❌ ' + (res.msg || '登录失败')
    }
  } catch (e) {
    tipsType.value = 'err'
    tips.value = '❌ ' + e.message
  } finally {
    loading.value = false
  }
}

function forgot() {
  tipsType.value = 'err'
  tips.value = '🍤 请找蟹老板重置密码吧~'
}
</script>

<style scoped>
.row {
  display: flex; align-items: center; justify-content: space-between;
  margin-top: 14px; font-size: 13px;
}
.row a { color: #8a5a00; text-decoration: none; font-weight: 700; }
.row a:hover { text-decoration: underline; }
</style>
