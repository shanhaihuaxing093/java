import { createRouter, createWebHistory } from 'vue-router'
import LoginView from '../views/LoginView.vue'
import RegisterView from '../views/RegisterView.vue'
import HomeView from '../views/HomeView.vue'
import UsersView from '../views/UsersView.vue'
import NotFoundView from '../views/NotFoundView.vue'

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
  // 404：不再静默重定向到登录页，而是给一个能看懂的页面
  { path: '/404', name: 'notFound', component: NotFoundView },
  { path: '/:pathMatch(.*)*', name: 'notFoundCatchAll', component: NotFoundView }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  // 切换页面回到顶部，长列表页体验更好
  scrollBehavior: () => ({ top: 0 })
})

/**
 * 路由守卫：需要登录的页面（meta.requiresAuth）必须有本地令牌，
 * 否则踢回登录页并带上 redirect，登录成功后自动回到原目标页。
 * 令牌是否真的有效由后端校验，后端返回 401 时 request.js 会自动清态跳转。
 */
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('bob_token')
  if (to.meta.requiresAuth && !token) {
    return next({ path: '/login', query: { redirect: to.fullPath } })
  }
  next()
})

export default router
