// 首页数据层（概览 / 公告 / 居民）
// 说明：后端 /api/home/* 尚未实现，这里用 localStorage 作为本地数据源，
// 带 _mock 标记；后台管理页（/admin）读写的也是同一份数据，改动即时反映到首页。
// 后端接口就绪后，把 fetch*/save* 换成 request 调用即可，页面无需改动。

const KEY = 'bikini_home_data_v1'

const DEFAULT_DATA = {
  overview: {
    residents: 0, // 会随居民列表长度自动校正
    krabby: 128,
    online: 3,
    waterTemp: '26℃',
    weather: '晴 · 微浪'
  },
  notices: [
    { id: 1, icon: '🍔', text: '本周三蟹黄堡买一送一，海苔条额外加赠！' },
    { id: 2, icon: '🧽', text: '海绵宝宝提醒：请勿在戴夫·琼斯 locker 附近游泳。' },
    { id: 3, icon: '🦀', text: '蟹老板宣布：本月员工之星是章鱼哥（他本人对此很失望）。' }
  ],
  residents: [
    { id: 1, username: 'spongebob', nickname: '海绵宝宝', status: 1, avatar: '🧽' },
    { id: 2, username: 'patrick', nickname: '派大星', status: 1, avatar: '⭐' },
    { id: 3, username: 'squidward', nickname: '章鱼哥', status: 1, avatar: '🦑' },
    { id: 4, username: 'mrcrabs', nickname: '蟹老板', status: 1, avatar: '🦀' },
    { id: 5, username: 'plankton', nickname: '痞老板', status: 0, avatar: '🦐' }
  ]
}

function load() {
  try {
    const raw = localStorage.getItem(KEY)
    if (raw) return JSON.parse(raw)
  } catch {
    /* 数据损坏则重置 */
  }
  const seed = JSON.parse(JSON.stringify(DEFAULT_DATA))
  seed.overview.residents = seed.residents.length
  localStorage.setItem(KEY, JSON.stringify(seed))
  return seed
}

function save(data) {
  data.overview.residents = data.residents.length
  localStorage.setItem(KEY, JSON.stringify(data))
}

const delay = (ms = 120) => new Promise((r) => setTimeout(r, ms))

/* ---------------- 首页读取接口 ---------------- */

export async function fetchOverview() {
  await delay()
  const d = load()
  return { ...d.overview, _mock: true }
}

export async function fetchNotices(page = 1, size = 6) {
  await delay()
  const d = load()
  const start = (page - 1) * size
  return { list: d.notices.slice(start, start + size), total: d.notices.length, _mock: true }
}

export async function fetchResidents(keyword = '', size = 6) {
  await delay()
  const d = load()
  const kw = String(keyword).trim().toLowerCase()
  const filtered = kw
    ? d.residents.filter(
        (r) => r.username?.toLowerCase().includes(kw) || r.nickname?.includes(keyword)
      )
    : d.residents
  return { list: filtered.slice(0, size), total: filtered.length, _mock: true }
}

/* ---------------- 后台管理接口 ---------------- */

export function getHomeData() {
  return JSON.parse(JSON.stringify(load()))
}

export function saveOverview(overview) {
  const d = load()
  d.overview = { ...d.overview, ...overview }
  save(d)
  return { ...d.overview }
}

export function addNotice(notice) {
  const d = load()
  const id = Date.now()
  d.notices.unshift({ id, icon: notice.icon || '📢', text: notice.text })
  save(d)
  return { id, ...notice }
}

export function updateNotice(id, patch) {
  const d = load()
  const i = d.notices.findIndex((n) => n.id === id)
  if (i > -1) d.notices[i] = { ...d.notices[i], ...patch }
  save(d)
  return i > -1
}

export function removeNotice(id) {
  const d = load()
  d.notices = d.notices.filter((n) => n.id !== id)
  save(d)
}

export function addResident(resident) {
  const d = load()
  const id = d.residents.reduce((m, r) => Math.max(m, r.id), 0) + 1
  d.residents.push({ id, status: 1, avatar: '🐟', ...resident })
  save(d)
  return id
}

export function updateResident(id, patch) {
  const d = load()
  const i = d.residents.findIndex((r) => r.id === id)
  if (i > -1) d.residents[i] = { ...d.residents[i], ...patch }
  save(d)
  return i > -1
}

export function removeResident(id) {
  const d = load()
  d.residents = d.residents.filter((r) => r.id !== id)
  save(d)
}

// 重置为出厂示例数据
export function resetHomeData() {
  localStorage.removeItem(KEY)
  return load()
}
