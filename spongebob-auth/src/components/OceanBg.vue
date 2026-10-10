<template>
  <div class="ocean">
    <!-- 气泡 -->
    <div class="bubbles">
      <div
        v-for="b in bubbles"
        :key="b.id"
        class="bubble"
        :style="b.style"
      ></div>
    </div>

    <!-- 海床 -->
    <div class="floor"></div>
    <!-- 海草 -->
    <div
      v-for="w in seaweeds"
      :key="w.id"
      class="seaweed"
      :style="w.style"
    ></div>

    <!-- 内容插槽 -->
    <slot />
  </div>
</template>

<script setup>
const rand = (min, max) => min + Math.random() * (max - min)

const bubbles = Array.from({ length: 22 }, (_, i) => {
  const size = rand(6, 32)
  return {
    id: i,
    style: {
      width: size + 'px',
      height: size + 'px',
      left: rand(0, 100) + '%',
      animationDuration: rand(7, 16) + 's',
      animationDelay: -rand(0, 12) + 's'
    }
  }
})

const seaweeds = [
  { id: 1, style: { left: '8%', height: '120px', animationDelay: '0s' } },
  { id: 2, style: { left: '16%', height: '90px', animationDelay: '.6s' } },
  { id: 3, style: { left: '52%', height: '70px', animationDelay: '1.6s' } },
  { id: 4, style: { left: '78%', height: '140px', animationDelay: '1.1s' } },
  { id: 5, style: { left: '88%', height: '100px', animationDelay: '.3s' } }
]
</script>
