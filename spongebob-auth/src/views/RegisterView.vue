<template>
  <OceanBg>
    <main class="sponge-card">
      <SpongeBob />
      <h1 class="title">加入蟹堡王</h1>
      <p class="subtitle">🌊 填写资料，成为比奇堡的新居民</p>

      <form @submit.prevent="onSubmit">
        <div class="field">
          <label for="username">用户名</label>
          <div class="input-wrap">
            <span class="icon">🧽</span>
            <input
              id="username"
              v-model.trim="form.username"
              type="text"
              placeholder="4-20 位字母/数字/下划线"
              autocomplete="off"
              @blur="checkUser"
            />
          </div>
        </div>

        <div class="field">
          <label for="nickname">昵称</label>
          <div class="input-wrap">
            <span class="icon">🐚</span>
            <input id="nickname" v-model.trim="form.nickname" type="text" placeholder="别人怎么称呼你" />
          </div>
        </div>

        <div class="field">
          <label for="password">密码</label>
          <div class="input-wrap">
            <span class="icon">🔑</span>
            <input id="password" v-model="form.password" type="password" placeholder="至少 6 位" />
          </div>
        </div>

        <div class="field">
          <label for="confirm">确认密码</label>
          <div class="input-wrap">
            <span class="icon">✅</span>
            <input id="confirm" v-model="form.confirm" type="password" placeholder="再输入一次密码" />
          </div>
        </div>

        <button class="btn" type="submit" :disabled="loading">
          {{ loading ? '注册中...' : '成为比奇堡居民 🎉' }}
        </button>

        <div class="tips" :class="tipsType">{{ tips }}</div>
      </form>

      <div class="switch">
        已经有账号？
        <router-link to="/login">去登录</router-link>
      </div>
    </main>
  </OceanBg>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import OceanBg from '../components/OceanBg.vue'
import SpongeBob from '../components/SpongeBob.vue'
import { register, checkUsername } from '../api/auth'

const router = useRouter()
const form = reactive({ username: '', nickname: '', password: '', confirm: '' })
const loading = ref(false)
const tips = ref('')
const tipsType = ref('')

// 用户名重复性校验（失焦时触发）
async function checkUser() {
  if (!form.username) return
  try {
    const res = await checkUsername(form.username)
    if (res.code === 200 && res.data === true) {
      tipsType.value = 'err'
      tips.value = '⚠ 该用户名已被占用'
    } else if (tipsType.value === 'err' && tips.value.includes('占用')) {
      tips.value = ''
      tipsType.value = ''
    }
  } catch (e) {
    /* 后端未启动时静默忽略 */
  }
}

async function onSubmit() {
  tips.value = ''
  tipsType.value = ''
  if (!/^[A-Za-z0-9_]{4,20}$/.test(form.username)) {
    tipsType.value = 'err'
    tips.value = '⚠ 用户名需为 4-20 位字母、数字或下划线'
    return
  }
  if (form.password.length < 6) {
    tipsType.value = 'err'
    tips.value = '⚠ 密码至少 6 位'
    return
  }
  if (form.password !== form.confirm) {
    tipsType.value = 'err'
    tips.value = '⚠ 两次输入的密码不一致'
    return
  }
  loading.value = true
  try {
    const res = await register({
      username: form.username,
      password: form.password,
      nickname: form.nickname || form.username
    })
    if (res.code === 200) {
      tipsType.value = 'ok'
      tips.value = '✅ 注册成功，正在跳转到登录页...'
      setTimeout(() => router.push('/login'), 800)
    } else {
      tipsType.value = 'err'
      tips.value = '❌ ' + (res.msg || '注册失败')
    }
  } catch (e) {
    tipsType.value = 'err'
    tips.value = '❌ ' + e.message
  } finally {
    loading.value = false
  }
}
</script>
