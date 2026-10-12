<template>
  <OceanBg>
    <main class="sponge-card notfound">
      <div class="code">404</div>
      <h1 class="title">🧭 迷路啦</h1>
      <p class="subtitle">这条海沟里没有你要找的页面</p>

      <p class="path">
        你访问的是：<b>{{ path }}</b>
      </p>

      <button class="btn" @click="goHome">回蟹堡王后台 🍔</button>
      <button class="btn ghost" @click="goLogin">去登录页 🧽</button>

      <div class="tips">🫧 提示：检查一下地址有没有拼错，或者从上面的按钮重新出发。</div>
    </main>
  </OceanBg>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import OceanBg from '../components/OceanBg.vue'

const route = useRoute()
const router = useRouter()
const path = computed(() => route.fullPath)

function goHome() {
  // 有令牌才进得去 /home，否则会被路由守卫拦回登录页（带 redirect）
  router.push('/home')
}

function goLogin() {
  router.push('/login')
}
</script>

<style scoped>
.notfound .code {
  text-align: center;
  font-size: 62px;
  font-weight: 800;
  line-height: 1;
  color: var(--sponge-dark);
  text-shadow: 3px 3px 0 #fff, 6px 6px 0 rgba(0, 0, 0, .12);
  letter-spacing: 4px;
}
.path {
  margin-top: 14px;
  text-align: center;
  font-size: 13px;
  color: #7a5400;
  word-break: break-all;
  background: rgba(255, 255, 255, .55);
  border: 3px dashed var(--sponge-border);
  border-radius: 14px;
  padding: 10px 12px;
}
.btn.ghost {
  margin-top: 12px;
  background: linear-gradient(180deg, #ffe95c, var(--sponge-dark));
  box-shadow: 0 7px 0 var(--sponge-border);
}
.btn.ghost:active { box-shadow: 0 2px 0 var(--sponge-border); }
.tips { margin-top: 16px; color: #7a5400; font-weight: 700; }
</style>
