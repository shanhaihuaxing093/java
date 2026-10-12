<template>
  <div class="loading-bar" :class="{ active: loadingState.pending > 0 }">
    <div class="loading-inner"></div>
    <span class="loading-text">🌊 潜水中…</span>
  </div>
</template>

<script setup>
// 全局请求进度条：挂在 App.vue 上，由 utils/loading.js 的计数器驱动
import { loadingState } from '../utils/loading'
</script>

<style scoped>
.loading-bar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 0;
  z-index: 999;
  overflow: hidden;
  pointer-events: none;
  transition: height .18s ease;
}
.loading-bar.active { height: 26px; }

.loading-inner {
  position: absolute;
  top: 0;
  left: 0;
  height: 5px;
  width: 100%;
  transform-origin: left center;
  background: linear-gradient(90deg, var(--sponge, #ffd90f), var(--green, #2ea24a), var(--ocean-3, #3fc4e8));
  box-shadow: 0 2px 8px rgba(0, 0, 0, .35);
  animation: slide 1.05s ease-in-out infinite;
}
@keyframes slide {
  0%   { transform: translateX(-100%) scaleX(.35); }
  50%  { transform: translateX(10%)   scaleX(.7); }
  100% { transform: translateX(100%)  scaleX(.35); }
}

.loading-text {
  position: absolute;
  top: 6px;
  left: 50%;
  transform: translateX(-50%);
  font-size: 12px;
  font-weight: 700;
  color: #fffdf5;
  background: rgba(4, 55, 107, .85);
  border: 2px solid var(--sponge-border, #a97b00);
  border-radius: 12px;
  padding: 2px 12px;
  white-space: nowrap;
}

@media (prefers-reduced-motion: reduce) {
  .loading-inner { animation: none; transform: none; }
}
</style>
