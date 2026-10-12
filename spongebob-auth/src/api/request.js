import axios from 'axios'
import { startLoading, stopLoading } from '../utils/loading'

// 参数全部来自 .env.development（见 .env.example），改后端地址不用动源码
const BASE_URL = import.meta.env.VITE_API_BASE || '/api'
const TIMEOUT = Number(import.meta.env.VITE_API_TIMEOUT || 10000)
const BACKEND_HINT = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8081'

const request = axios.create({
  baseURL: BASE_URL,
  timeout: TIMEOUT,
  headers: { 'Content-Type': 'application/json' }
})

// 令牌失效时只跳一次，避免多个并发请求同时触发刷新
let redirecting = false

// 清除本地登录态
export function clearSession() {
  localStorage.removeItem('bob_token')
  localStorage.removeItem('bob_user')
}

// 清态 + 回登录页，并记住原路径，登录成功后自动跳回
export function redirectToLogin() {
  clearSession()
  if (redirecting) return
  const current = window.location.pathname + window.location.search
  if (current.startsWith('/login')) return
  redirecting = true
  window.location.replace('/login?redirect=' + encodeURIComponent(current))
}

// 请求拦截：开进度条 + 自动带令牌（后端 TokenInterceptor 校验 Authorization 头）
request.interceptors.request.use(
  (config) => {
    startLoading()
    const token = localStorage.getItem('bob_token')
    if (token) {
      config.headers.Authorization = token
    }
    return config
  },
  (error) => {
    stopLoading()
    return Promise.reject(error)
  }
)

// 响应拦截：关进度条 + 直接返回业务数据体 { code, msg, data }
request.interceptors.response.use(
  (response) => {
    stopLoading()
    const data = response.data
    // 401 = 令牌失效（被踢下线 / 后端重启 / 手动改库）
    if (data && data.code === 401) {
      redirectToLogin()
    }
    return data
  },
  (error) => {
    stopLoading()
    let msg = `网络异常，请检查后端是否已启动（${BACKEND_HINT}）`
    if (error.response) {
      // 后端拦截器返回的是 HTTP 200 + code 401，这里再兜一层，
      // 万一以后改成标准 HTTP 401 也能正确清态跳登录
      if (error.response.status === 401) {
        redirectToLogin()
      }
      msg = error.response.data?.msg || `请求失败（HTTP ${error.response.status}）`
    } else if (error.code === 'ECONNABORTED' || error.message?.includes('timeout')) {
      msg = '请求超时，后端可能未启动'
    }
    return Promise.reject(new Error(msg))
  }
)

export default request
