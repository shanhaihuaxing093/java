import { createRouter, createWebHistory } from 'vue-router'
import LoginView from '../views/LoginView.vue'
import RegisterView from '../views/RegisterView.vue'
import HomeView from '../views/HomeView.vue'
import UsersView from '../views/UsersView.vue'

const routes = [
  { path: '/', redirect: '/login' },
  { path: '/login', name: 'login', component: LoginView },
  { path: '/register', name: 'register', component: RegisterView },
  {
    path: '/home',
    name: 'home',
    component: HomeView,
    meta: { requiresAuth: true }
  },
  {
    path: '/users',
    name: 'users',
    component: UsersView,
    meta: { requiresAuth: true }
  },
  // 兜底：未匹配的路径回登录页（可换成专门的 404 页面）
  { path: '/:pathMatch(.*)*', redirect: '/login' }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

/**
 * 路由守卫：需要登录的页面（meta.requiresAuth）必须有本地令牌，
 * 否则踢回登录页。令牌是否真的有效由后端校验，后端返回 401 时 request.js 会自动清态跳转。
 */
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('bob_token')
  if (to.meta.requiresAuth && !token) {
    return next({ path: '/login', query: { redirect: to.fullPath } })
  }
  next()
})

export default router
