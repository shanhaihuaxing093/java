<template>
  <transition name="drawer">
    <div v-if="open" class="side-wrap" @click.self="$emit('close')">
      <aside class="side">
        <div class="side-head">
          <span class="s-avatar">{{ user?.nickname ? user.nickname[0] : '🧽' }}</span>
          <div class="s-main">
            <b>{{ user?.nickname || user?.username || '居民' }}</b>
            <small>@{{ user?.username || 'guest' }}</small>
          </div>
        </div>

        <nav class="side-nav">
          <button
            v-for="item in NAV_ITEMS"
            :key="item.key"
            class="s-item"
            type="button"
            @click="$emit('navigate', item)"
          >
            <span class="s-icon">{{ item.icon }}</span>
            {{ item.title }}
          </button>
          <button class="s-item admin" type="button" @click="$emit('navigate', { to: '/admin/login', built: true })">
            <span class="s-icon">🦀</span>
            后台管理系统
          </button>
        </nav>

        <button class="s-close" type="button" @click="$emit('close')">收起菜单 ×</button>
      </aside>
    </div>
  </transition>
</template>

<script setup>
import { NAV_ITEMS } from '../config/nav'

defineProps({
  open: { type: Boolean, default: false },
  user: { type: Object, default: () => ({}) }
})
defineEmits(['navigate', 'close'])
</script>

<style scoped>
.side-wrap {
  position: fixed;
  inset: 0;
  z-index: 60;
  background: rgba(0, 20, 40, 0.35);
}
.side {
  display: flex;
  flex-direction: column;
  gap: 12px;
  width: 232px;
  height: 100%;
  padding: 16px 14px;
  background: #fffdf2;
  border-right: 3px solid rgba(169, 123, 0, 0.45);
  box-shadow: 6px 0 18px rgba(0, 0, 0, 0.18);
}
.side-head {
  display: flex;
  align-items: center;
  gap: 9px;
  padding: 10px;
  background: rgba(255, 217, 15, 0.3);
  border: 2px solid rgba(169, 123, 0, 0.4);
  border-radius: 14px;
}
.s-avatar {
  display: grid;
  place-items: center;
  width: 40px;
  height: 40px;
  font-size: 18px;
  font-weight: 800;
  background: var(--sponge, #ffdf0f);
  border: 2px solid var(--sponge-border, #a97b00);
  border-radius: 50%;
}
.s-main { display: flex; flex-direction: column; line-height: 1.3; min-width: 0; }
.s-main b { font-size: 14px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.s-main small { font-size: 11px; color: #7a5400; }

.side-nav { display: flex; flex-direction: column; gap: 6px; }
.s-item {
  display: flex;
  align-items: center;
  gap: 9px;
  padding: 11px 13px;
  font-family: inherit;
  font-size: 14px;
  font-weight: 800;
  color: #6b4a00;
  text-align: left;
  cursor: pointer;
  background: transparent;
  border: 2px solid transparent;
  border-radius: 13px;
  transition: 0.15s;
}
.s-item:hover { background: rgba(255, 217, 15, 0.4); }
.s-item.admin {
  color: #b23c0e;
  background: rgba(255, 122, 69, 0.14);
  border-color: rgba(255, 122, 69, 0.55);
}
.s-item.admin:hover { background: rgba(255, 122, 69, 0.3); }
.s-icon { font-size: 17px; }

.s-close {
  margin-top: auto;
  padding: 9px;
  font-family: inherit;
  font-size: 13px;
  font-weight: 800;
  color: #6b4a00;
  cursor: pointer;
  background: #fff;
  border: 2px solid rgba(169, 123, 0, 0.45);
  border-radius: 12px;
}

.drawer-enter-active,
.drawer-leave-active { transition: opacity 0.2s; }
.drawer-enter-active .side,
.drawer-leave-active .side { transition: transform 0.22s ease; }
.drawer-enter-from,
.drawer-leave-to { opacity: 0; }
.drawer-enter-from .side,
.drawer-leave-to .side { transform: translateX(-100%); }
</style>
