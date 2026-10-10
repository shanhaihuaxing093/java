<template>
  <svg class="bob" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
    <ellipse cx="60" cy="112" rx="34" ry="6" fill="rgba(0,0,0,.18)" />
    <rect x="14" y="18" width="92" height="82" rx="14" fill="#ffd90f" stroke="#a97b00" stroke-width="3" />
    <circle cx="34" cy="40" r="7" fill="#e0a800" />
    <circle cx="78" cy="34" r="5" fill="#e0a800" />
    <circle cx="92" cy="66" r="6" fill="#e0a800" />
    <circle cx="30" cy="84" r="5" fill="#e0a800" />
    <circle cx="62" cy="92" r="4" fill="#e0a800" />
    <circle cx="40" cy="52" r="12" fill="#fff" stroke="#a97b00" stroke-width="2" />
    <circle cx="72" cy="52" r="12" fill="#fff" stroke="#a97b00" stroke-width="2" />
    <circle cx="42" cy="54" r="5" fill="#0b3d6b" />
    <circle cx="74" cy="54" r="5" fill="#0b3d6b" />
    <circle cx="43.5" cy="52.5" r="1.6" fill="#fff" />
    <circle cx="75.5" cy="52.5" r="1.6" fill="#fff" />
    <path d="M40 70 Q56 84 74 70" stroke="#a97b00" stroke-width="3" fill="none" stroke-linecap="round" />
    <path d="M50 72 Q56 76 62 72" fill="#fff" />
    <rect x="48" y="94" width="24" height="10" rx="3" fill="#fff" stroke="#a97b00" stroke-width="2" />
    <path d="M52 104 L60 112 L68 104" fill="#e03b3b" stroke="#a32020" stroke-width="2" />
    <path d="M60 112 L58 122 L62 122 Z" fill="#e03b3b" />
  </svg>
</template>

<script setup>
</script>

<style scoped>
.bob { width: 130px; margin: -92px auto 6px; display: block; animation: float 5s ease-in-out infinite; }
@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}
</style>
