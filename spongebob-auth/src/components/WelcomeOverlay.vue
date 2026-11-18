<template>
  <teleport to="body">
    <div class="welcome-overlay" role="dialog" aria-modal="true" aria-label="欢迎来到比奇堡">
      <!-- 海底气泡背景 -->
      <div class="welcome-bubbles">
        <span
          v-for="b in bubbles"
          :key="b.id"
          class="welcome-bubble"
          :style="b.style"
        ></span>
      </div>

      <div class="welcome-card">
        <div class="bob-stage">
          <div class="bob-dance"><SpongeBob /></div>
          <span class="sparkle s1">✨</span>
          <span class="sparkle s2">⭐</span>
          <span class="sparkle s3">✨</span>
        </div>

        <h1 class="welcome-title">欢迎来到比奇堡！</h1>
        <p class="welcome-name">{{ nickname }}</p>
        <p class="welcome-line">海绵宝宝热烈欢迎你加入蟹堡王！🍍</p>

        <div class="speech-chip" :class="{ active: speaking }">
          <span class="speech-icon">{{ speaking ? '🔊' : '💬' }}</span>
          <span>{{ speaking ? speechText : '欢迎语音准备中…' }}</span>
        </div>

        <div class="progress-track">
          <div class="progress-fill" :style="{ width: progress + '%' }"></div>
        </div>

        <div class="welcome-actions">
          <button class="wbtn skip" @click="finish">跳过</button>
          <button class="wbtn go" @click="finish">去登录 🎉</button>
        </div>
        <p class="auto-tip">{{ countdown > 0 ? countdown + ' 秒后自动前往登录页' : '正在前往登录页…' }}</p>

        <!--
          可选视频：把欢迎视频放到 public/media/spongebob-welcome.mp4
          然后把下面的 videoUrl 默认值改成 '/media/spongebob-welcome.mp4'
          即可改为优先播放视频（视频结束后自动跳转）。
        -->
        <video
          v-if="videoUrl"
          ref="videoEl"
          class="welcome-video"
          :src="videoUrl"
          autoplay
          playsinline
          @ended="finish"
          @error="videoUrl = ''"
        ></video>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import SpongeBob from './SpongeBob.vue'

const props = defineProps({
  nickname: { type: String, default: '新居民' }
})
const emit = defineEmits(['done'])

const speaking = ref(false)
const speechText = ref('')
const progress = ref(0)
const countdown = ref(7)
// 默认用「语音 + 动画」方案；如需视频，改成 '/media/spongebob-welcome.mp4'
const videoUrl = ref('')

const rand = (min, max) => min + Math.random() * (max - min)
const bubbles = Array.from({ length: 16 }, (_, i) => {
  const size = rand(6, 26)
  return {
    id: i,
    style: {
      width: size + 'px',
      height: size + 'px',
      left: rand(0, 100) + '%',
      animationDuration: rand(6, 14) + 's',
      animationDelay: -rand(0, 10) + 's'
    }
  }
})

const TOTAL = 7000
let startTs = 0
let tickTimer = null
let hardTimer = null
let speechTimer = null
let finished = false

function tick() {
  const elapsed = Date.now() - startTs
  progress.value = Math.min(100, (elapsed / TOTAL) * 100)
  countdown.value = Math.max(0, Math.ceil((TOTAL - elapsed) / 1000))
}

function speak() {
  if (!('speechSynthesis' in window)) return
  try {
    window.speechSynthesis.cancel()
    const text = `欢迎来到比奇堡，${props.nickname}！我是海绵宝宝，欢迎你加入蟹堡王！嘿嘿嘿！`
    const u = new SpeechSynthesisUtterance(text)
    u.lang = 'zh-CN'
    u.rate = 1.05
    u.pitch = 1.5 // 尖细的嗓音，模仿海绵宝宝
    u.volume = 1
    const voices = window.speechSynthesis.getVoices() || []
    const zh = voices.find((v) => /zh/i.test(v.lang))
    if (zh) u.voice = zh
    u.onend = () => {
      speaking.value = false
      speechTimer = setTimeout(finish, 700) // 说完后稍作停留再跳转
    }
    u.onerror = () => {
      speaking.value = false
    }
    speaking.value = true
    speechText.value = text
    window.speechSynthesis.speak(u)
  } catch (e) {
    speaking.value = false
  }
}

function finish() {
  if (finished) return
  finished = true
  clearInterval(tickTimer)
  clearTimeout(hardTimer)
  clearTimeout(speechTimer)
  try { window.speechSynthesis && window.speechSynthesis.cancel() } catch (e) {}
  emit('done')
}

onMounted(() => {
  startTs = Date.now()
  tickTimer = setInterval(tick, 100)
  hardTimer = setTimeout(finish, TOTAL) // 兜底：无论语音是否可用都能自动跳转
  if (videoUrl.value) {
    speechText.value = '欢迎视频播放中…'
  } else {
    speak()
  }
})

onBeforeUnmount(() => {
  clearInterval(tickTimer)
  clearTimeout(hardTimer)
  clearTimeout(speechTimer)
  try { window.speechSynthesis && window.speechSynthesis.cancel() } catch (e) {}
})
</script>

<style scoped>
.welcome-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  background: radial-gradient(circle at 50% 30%, rgba(13, 109, 163, .85), rgba(4, 55, 107, .96));
  backdrop-filter: blur(4px);
  animation: fadein .35s ease both;
}
@keyframes fadein { from { opacity: 0; } to { opacity: 1; } }

.welcome-bubbles { position: absolute; inset: 0; overflow: hidden; pointer-events: none; }
.welcome-bubble {
  position: absolute;
  bottom: -60px;
  border-radius: 50%;
  background: radial-gradient(circle at 30% 30%, rgba(255, 255, 255, .95), rgba(255, 255, 255, .15) 60%, rgba(255, 255, 255, .02));
  border: 1px solid rgba(255, 255, 255, .4);
  animation: wrise linear infinite;
}
@keyframes wrise {
  0%   { transform: translateY(0) scale(.6); opacity: 0; }
  12%  { opacity: .8; }
  100% { transform: translateY(-110vh) translateX(24px) scale(1.1); opacity: 0; }
}

.welcome-card {
  position: relative;
  width: 100%;
  max-width: 440px;
  padding: 20px 26px 24px;
  text-align: center;
  background:
    radial-gradient(circle at 18% 26%, var(--sponge-deep) 0 6px, transparent 7px),
    radial-gradient(circle at 76% 20%, var(--sponge-deep) 0 5px, transparent 6px),
    radial-gradient(circle at 84% 70%, var(--sponge-deep) 0 8px, transparent 9px),
    linear-gradient(160deg, #ffe95c, var(--sponge) 55%, var(--sponge-dark));
  border: 5px solid var(--sponge-border);
  border-radius: 28px;
  box-shadow: 0 16px 0 var(--sponge-border), 0 26px 50px rgba(0, 0, 0, .5);
  animation: pop .45s cubic-bezier(.2, .8, .3, 1.3) both;
}
@keyframes pop {
  from { transform: scale(.7) translateY(30px); opacity: 0; }
  to   { transform: scale(1) translateY(0); opacity: 1; }
}

.bob-stage { position: relative; height: 116px; }
.bob-dance :deep(.bob) { animation: bobdance .9s ease-in-out infinite !important; }
@keyframes bobdance {
  0%, 100% { transform: translateY(0) rotate(-3deg); }
  50%      { transform: translateY(-12px) rotate(3deg); }
}
.sparkle { position: absolute; font-size: 20px; animation: twinkle 1.4s ease-in-out infinite; }
.s1 { left: 22%; top: 8px; }
.s2 { right: 20%; top: 30px; animation-delay: .4s; }
.s3 { left: 30%; bottom: 4px; animation-delay: .8s; }
@keyframes twinkle {
  0%, 100% { transform: scale(.6); opacity: .3; }
  50%      { transform: scale(1.2); opacity: 1; }
}

.welcome-title {
  margin-top: 4px;
  font-size: 25px;
  font-weight: 800;
  letter-spacing: 1px;
  text-shadow: 2px 2px 0 #fff, 4px 4px 0 rgba(0, 0, 0, .15);
}
.welcome-name {
  display: inline-block;
  margin-top: 8px;
  padding: 3px 14px;
  font-size: 17px;
  font-weight: 800;
  color: #fff;
  background: var(--ocean-2);
  border: 2px solid var(--ocean-1);
  border-radius: 14px;
}
.welcome-line { margin-top: 10px; font-size: 14px; color: #7a5400; font-weight: 700; }

.speech-chip {
  margin: 14px auto 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-height: 40px;
  padding: 8px 14px;
  font-size: 13px;
  font-weight: 700;
  line-height: 1.4;
  background: var(--white);
  color: var(--ink);
  border: 3px solid var(--sponge-border);
  border-radius: 16px;
}
.speech-chip.active { animation: chipPulse 1s ease-in-out infinite; }
@keyframes chipPulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(46, 162, 74, .35); }
  50%      { box-shadow: 0 0 0 8px rgba(46, 162, 74, 0); }
}
.speech-icon { font-size: 18px; }

.progress-track {
  margin: 16px 0 6px;
  height: 10px;
  border-radius: 10px;
  background: rgba(0, 0, 0, .12);
  border: 2px solid var(--sponge-border);
  overflow: hidden;
}
.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #7ee081, var(--green));
  border-radius: 8px;
  transition: width .1s linear;
}

.welcome-actions { display: flex; gap: 12px; margin-top: 14px; }
.wbtn {
  flex: 1;
  padding: 12px;
  font-size: 15px;
  font-weight: 800;
  font-family: inherit;
  cursor: pointer;
  border-radius: 16px;
  transition: .12s;
}
.wbtn.skip {
  color: var(--ink);
  background: var(--white);
  border: 3px solid var(--sponge-border);
  box-shadow: 0 5px 0 var(--sponge-border);
}
.wbtn.go {
  color: #fff;
  background: linear-gradient(180deg, #7ee081, var(--green));
  border: 3px solid var(--green-dark);
  box-shadow: 0 5px 0 var(--green-dark);
}
.wbtn:active { transform: translateY(4px); box-shadow: none; }

.auto-tip { margin-top: 10px; font-size: 12px; color: #7a5400; font-weight: 700; }

.welcome-video { position: absolute; width: 1px; height: 1px; opacity: 0; pointer-events: none; }

@media (max-width: 480px) {
  .welcome-card { padding: 18px 16px 20px; border-width: 4px; }
  .welcome-title { font-size: 21px; }
  .speech-chip { font-size: 12px; }
}

@media (prefers-reduced-motion: reduce) {
  .welcome-overlay, .welcome-card, .bob-dance :deep(.bob), .sparkle { animation: none !important; }
}
</style>
