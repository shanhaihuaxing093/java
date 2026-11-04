<template>
  <div class="toast-host" aria-live="polite">
    <transition-group name="toast">
      <div v-for="t in items" :key="t.id" class="toast" :class="t.type">{{ t.msg }}</div>
    </transition-group>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { toastBus } from '../utils/toast'

const items = ref([])
let off

onMounted(() => {
  off = toastBus.push((msg, type) => {
    const id = Date.now() + Math.random()
    items.value.push({ id, msg, type })
    setTimeout(() => {
      items.value = items.value.filter((t) => t.id !== id)
    }, 2200)
  })
})
onBeforeUnmount(() => off && off())
</script>

<style scoped>
.toast-host {
  position: fixed;
  right: 18px;
  bottom: 22px;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  gap: 8px;
  pointer-events: none;
}
.toast {
  max-width: 340px;
  padding: 10px 16px;
  font-size: 13px;
  font-weight: 700;
  border-radius: 12px;
  border: 2px solid var(--sponge-border, #a97b00);
  background: #fff3b0;
  color: var(--ink, #5a3d00);
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.18);
}
.toast.ok {
  border-color: rgba(63, 156, 79, 0.8);
  background: #c8f0cd;
  color: var(--green-dark, #1f7a2e);
}
.toast.err {
  border-color: rgba(210, 80, 80, 0.8);
  background: #ffd9d9;
  color: #8a1f1f;
}
.toast-enter-active,
.toast-leave-active { transition: all 0.25s ease; }
.toast-enter-from,
.toast-leave-to { opacity: 0; transform: translateY(8px); }
</style>
