import { reactive, readonly } from 'vue'

/**
 * 全局加载状态：request.js 每发一个请求 +1，响应回来 -1。
 * 只要 pending > 0，页面顶部的进度条（GlobalLoading）就会出现。
 * 刻意不引入 Pinia：项目规模小，一个 reactive 对象足够，
 * 而且模块级单例在拦截器里可以直接 import 使用。
 */
const state = reactive({ pending: 0 })

export const loadingState = readonly(state)

export function startLoading() {
  state.pending += 1
}

export function stopLoading() {
  state.pending = Math.max(0, state.pending - 1)
}
