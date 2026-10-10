import axios from 'axios'

// baseURL 使用 /api，由 vite.config.js 的 proxy 转发到 http://localhost:8081
const request = axios.create({
  baseURL: '/api',
  timeout: 10000,
  headers: { 'Content-Type': 'application/json' }
})

// 清除本地登录态并跳回登录页
export function clearSession() {
  localStorage.removeItem('bob_token')
  localStorage.removeItem('bob_user')
}

// 请求拦截：自动带上登录令牌（后端 TokenInterceptor 校验 Authorization 头）
request.interceptors.request.use((config) => {
  const token = localStorage.getItem('bob_token')
  if (token) {
    config.headers.Authorization = token
  }
  return config
})

// 响应拦截：直接返回业务数据体 { code, msg, data }
request.interceptors.response.use(
  (response) => {
    const data = response.data
    // 401 = 令牌失效（被踢下线 / 后端重启 / 手动改库）
    if (data && data.code === 401) {
      clearSession()
      if (!window.location.pathname.startsWith('/login')) {
        window.location.replace('/login')
      }
    }
    return data
  },
  (error) => {
    let msg = '网络异常，请检查后端是否已启动（localhost:8081）'
    if (error.response) {
      msg = error.response.data?.msg || `请求失败（HTTP ${error.response.status}）`
    } else if (error.code === 'ECONNABORTED') {
      msg = '请求超时，后端可能未启动'
    }
    return Promise.reject(new Error(msg))
  }
)

export default request
