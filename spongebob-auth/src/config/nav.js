// 顶部导航 + 侧边栏共用的导航配置
export const NAV_ITEMS = [
  { key: 'home', icon: '🍍', title: '首页', to: '/home', built: true },
  { key: 'users', icon: '🐚', title: '居民名单', to: '/users', built: true }
]

// 首页快捷入口
export const QUICK_ACTIONS = [
  { key: 'users', icon: '🐚', title: '居民名单', desc: '查看全部居民', to: '/users', built: true },
  { key: 'admin', icon: '🦀', title: '后台管理', desc: '管理首页数据', to: '/admin/login', built: true },
  { key: 'notice', icon: '📢', title: '公告中心', desc: '比奇堡大小事', to: '', built: false }
]
