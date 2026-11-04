<template>
  <OceanBg>
    <main class="sponge-card admin-card">
      <SpongeBob />
      <h1 class="title">后台管理系统</h1>
      <p class="subtitle">🦀 蟹堡王内部通道 · 仅限管理层登入</p>

      <form @submit.prevent="onSubmit">
        <div class="field">
          <label for="admin-username">管理员账号</label>
          <div class="input-wrap">
            <span class="icon">🦀</span>
            <input id="admin-username" v-model.trim="form.username" type="text" placeholder="请输入账号" autocomplete="off" />
          </div>
        </div>

        <div class="field">
          <label for="admin-password">密码</label>
          <div class="input-wrap">
            <span class="icon">🔑</span>
            <input id="admin-password" v-model="form.password" type="password" placeholder="请输入密码" />
          </div>
        </div>

        <button class="btn" type="submit" :disabled="loading">
          {{ loading ? '核验身份中...' : '进入后台 🦀' }}
        </button>

        <div class="tips" :class="tipsType">{{ tips }}</div>
      </form>

      <div class="switch">
        <router-link to="/home">← 返回首页</router-link>
      </div>
    </main>
  </OceanBg>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import OceanBg from '../../components/OceanBg.vue'
import SpongeBob from '../../components/SpongeBob.vue'
import { login } from '../../api/auth'
import { toast } from '../../utils/toast'

const router = useRouter()

const form = reactive({ username: '', password: '' })
const loading = ref(false)
const tips = ref('🫧 请出示蟹堡王管理层工牌')
const tipsType = ref('')

onMounted(() => {
  // 已有令牌则免登录直达
  if (localStorage.getItem('bob_token')) router.replace('/admin')
})

async function onSubmit() {
  if (!form.username || !form.password) {
    tipsType.value = 'warn'
    tips.value = '⚠️ 账号和密码都不能为空'
    return
  }
  loading.value = true
  tipsType.value = ''
  tips.value = '🫧 正在核验身份…'
  try {
    const res = await login({ username: form.username, password: form.password })
    if (res.code === 200 && res.data?.token) {
      localStorage.setItem('bob_token', res.data.token)
      localStorage.setItem('bob_user', JSON.stringify(res.data.userInfo || { username: form.username }))
      tipsType.value = 'ok'
      tips.value = '✅ 身份核验通过，正在进入后台…'
      toast('🦀 欢迎回来，管理员', 'ok')
      router.replace(res.redirect || '/admin')
    } else {
      tipsType.value = 'warn'
      tips.value = '❌ ' + (res.msg || '账号或密码错误')
    }
  } catch (e) {
    tipsType.value = 'warn'
    tips.value = '❌ ' + e.message
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.admin-card { max-width: 400px; }
.title {
  margin: 10px 0 2px;
  font-size: 25px;
  font-weight: 800;
  letter-spacing: 2px;
  color: #6b4a00;
}
.subtitle { margin: 0 0 18px; font-size: 13px; color: #7a5400; }

.field { margin-bottom: 13px; text-align: left; }
.field label {
  display: block;
  margin-bottom: 5px;
  font-size: 13px;
  font-weight: 800;
  color: #6b4a00;
}
.input-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 12px;
  background: #fff;
  border: 3px solid rgba(169, 123, 0, 0.45);
  border-radius: 13px;
  transition: 0.15s;
}
.input-wrap:focus-within { border-color: var(--ocean-1, #3fc4e8); }
.icon { font-size: 15px; }
.input-wrap input {
  flex: 1;
  height: 40px;
  font-family: inherit;
  font-size: 14px;
  color: var(--ink, #3a2c00);
  background: transparent;
  border: none;
  outline: none;
}

.btn {
  width: 100%;
  margin-top: 6px;
  padding: 12px;
  font-family: inherit;
  font-size: 16px;
  font-weight: 800;
  letter-spacing: 1px;
  color: #fff;
  cursor: pointer;
  background: linear-gradient(135deg, #ff7a45, #e8541d);
  border: 3px solid #a63a10;
  border-radius: 14px;
  box-shadow: 0 4px 0 #a63a10;
  transition: 0.15s;
}
.btn:hover:not(:disabled) { transform: translateY(-2px); box-shadow: 0 6px 0 #a63a10; }
.btn:disabled { opacity: 0.65; cursor: not-allowed; }

.tips {
  min-height: 20px;
  margin-top: 10px;
  font-size: 13px;
  font-weight: 700;
  color: #7a5400;
}
.tips.warn { color: #c0392b; }
.tips.ok { color: #2e7d32; }

.switch { margin-top: 14px; font-size: 13px; font-weight: 700; }
.switch a {
  color: var(--ocean-dark, #1b6f8c);
  text-decoration: none;
}
.switch a:hover { text-decoration: underline; }
</style>
