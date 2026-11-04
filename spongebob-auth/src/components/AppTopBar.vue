<template>
  <header class="topbar">
    <button class="burger" type="button" aria-label="打开菜单" @click="$emit('toggle')">☰</button>

    <div class="brand" @click="$emit('navigate', { to: '/home', built: true })">
      <span class="brand-icon">🍍</span>
      <b>比奇堡 · 蟹堡王</b>
    </div>

    <nav class="nav">
      <button
        v-for="item in NAV_ITEMS"
        :key="item.key"
        class="nav-item"
        :class="{ active: active(item) }"
        type="button"
        @click="$emit('navigate', item)"
      >
        {{ item.title }}
      </button>
    </nav>

    <div class="spacer"></div>

    <!-- 后台管理系统入口 -->
    <button class="admin-btn" type="button" title="进入后台管理系统" @click="$emit('navigate', { to: '/admin/login', built: true })">
      <span class="ab-icon">🦀</span>
      后台管理系统
    </button>

    <div class="user" :title="user?.username">
      <span class="u-avatar">{{ user?.nickname ? user.nickname[0] : '🧽' }}</span>
      <span class="u-name">{{ user?.nickname || user?.username || '居民' }}</span>
    </div>

    <button class="icon-btn" type="button" title="刷新数据" @click="$emit('refresh')">🔄</button>
    <button class="icon-btn" type="button" title="退出登录" @click="$emit('logout')">🚪</button>
  </header>
</template>

<script setup>
import { NAV_ITEMS } from '../config/nav'

defineProps({ user: { type: Object, default: () => ({}) } })
defineEmits(['toggle', 'navigate', 'logout', 'refresh'])

function active(item) {
  return window.location.pathname === item.to
}
</script>

<style scoped>
.topbar {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
  max-width: 1440px;
  margin: 0 auto;
  padding: 12px 22px;
  background: rgba(255, 255, 255, 0.86);
  border-bottom: 3px solid rgba(169, 123, 0, 0.45);
  backdrop-filter: blur(6px);
}
.burger { display: none; }

.brand {
  display: flex;
  align-items: center;
  gap: 7px;
  font-size: 17px;
  font-weight: 800;
  cursor: pointer;
  color: #6b4a00;
  white-space: nowrap;
}
.brand-icon { font-size: 21px; }

.nav { display: flex; gap: 6px; margin-left: 10px; }
.nav-item {
  padding: 7px 15px;
  font-family: inherit;
  font-size: 14px;
  font-weight: 800;
  color: #6b4a00;
  cursor: pointer;
  background: transparent;
  border: 2px solid transparent;
  border-radius: 12px;
  transition: 0.15s;
}
.nav-item:hover { background: rgba(255, 217, 15, 0.4); }
.nav-item.active {
  background: var(--sponge, #ffdf0f);
  border-color: var(--sponge-border, #a97b00);
}

.spacer { flex: 1; }

.admin-btn {
  display: flex;
  align-items: center;
  gap: 7px;
  padding: 8px 16px;
  font-family: inherit;
  font-size: 14px;
  font-weight: 800;
  color: #fff;
  cursor: pointer;
  background: linear-gradient(135deg, #ff7a45, #e8541d);
  border: 3px solid #a63a10;
  border-radius: 14px;
  box-shadow: 0 3px 0 #a63a10;
  transition: 0.15s;
  white-space: nowrap;
}
.admin-btn:hover { transform: translateY(-2px); box-shadow: 0 5px 0 #a63a10; }
.admin-btn:active { transform: translateY(1px); box-shadow: 0 1px 0 #a63a10; }
.ab-icon { font-size: 16px; }

.user {
  display: flex;
  align-items: center;
  gap: 7px;
  padding: 5px 12px 5px 6px;
  background: rgba(255, 217, 15, 0.35);
  border: 2px solid rgba(169, 123, 0, 0.4);
  border-radius: 999px;
}
.u-avatar {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  font-size: 14px;
  font-weight: 800;
  background: var(--sponge, #ffdf0f);
  border: 2px solid var(--sponge-border, #a97b00);
  border-radius: 50%;
}
.u-name { font-size: 13px; font-weight: 800; color: #6b4a00; }

.icon-btn {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  font-size: 16px;
  cursor: pointer;
  background: #fff;
  border: 2px solid rgba(169, 123, 0, 0.45);
  border-radius: 11px;
  transition: 0.15s;
}
.icon-btn:hover { background: rgba(255, 217, 15, 0.4); }

@media (max-width: 900px) {
  .topbar { padding: 10px 14px; gap: 8px; }
  .nav { display: none; }
  .burger {
    display: grid;
    place-items: center;
    width: 36px;
    height: 36px;
    font-size: 17px;
    cursor: pointer;
    background: #fff;
    border: 2px solid rgba(169, 123, 0, 0.45);
    border-radius: 11px;
  }
  .admin-btn { padding: 7px 10px; font-size: 12px; }
  .u-name { display: none; }
}
</style>
