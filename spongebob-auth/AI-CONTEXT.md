# AI-CONTEXT.md —— 机器速读档案（前端 spongebob-auth）

> 作用：本文件是写给我（AI/助手）看的。下次打开这个项目，**先只读这一个文件**，
> 按「固定事实」直接执行，**不要重新探测环境、不要重新设计架构、不要反复确认**。
> 只有事实明显失效（端口连不上、依赖装不上）时才重新检查。

---

## 0. 一句话定位

**海绵宝宝（比奇堡）主题的登录注册前端**：Vue 3 + Vite + Vue Router + Axios。
后端是 `D:\workSpace\springBootTest`（SpringBoot 3.4.5 + MyBatis-Plus + MySQL 8）。

---

## 1. 固定事实（已在本机验证，直接采信）

| 项目 | 值 |
| --- | --- |
| 项目根目录 | `C:\Users\Administrator\Desktop\spongebob-auth` |
| 技术栈 | Vue 3.5 + Vite 5.4 + vue-router 4 + axios 1.7，**无 UI 库**（纯手写 CSS 主题） |
| 开发端口 | **5173**（`vite.config.js`；Vite 端口被占会自动顺延到 5174） |
| 代理规则 | `/api` → `http://localhost:8081`（`vite.config.js` 顶部常量 `BACKEND`） |
| 后端端口 | 8081，**必须先启动后端**，否则登录注册报「网络异常」 |
| Node / npm | v22.22.2 / 10.9.7（PATH 中可用） |
| 数据库 | MySQL 8.0，`root / 123456`，库 `spongebob_auth` |
| 测试账号 | `spongebob / 123456`、`patrick / 123456`、`squidward / 123456` |

**机器每次开机重置**：`node_modules` 会被删除 → 启动脚本自带 `npm install`。

---

## 2. 目录地图

```
spongebobob-auth  (spongebob-auth)
├─ AI-CONTEXT.md              ← 本文件（机器速读 + 人读说明书）
├─ spongebob-login.html       ← 最初的单文件版登录页（视觉基准，可直接双击打开）
├─ package.json               ← 依赖与脚本：dev / build / preview
├─ vite.config.js             ← 端口 5173 + /api 代理到 8081
├─ index.html
├─ 启动前端.bat                ← 一键启动（相对路径，GBK 编码）
├─ 停止前端.bat                ← 一键停止（按端口 5173 杀进程）
├─ 启动全部.bat                ← 前端 + 后端一起启动
├─ 停止全部.bat                ← 前端 + 后端一起停止
├─ sql\spongebob_auth.sql     ← 建库建表脚本（与后端 sql 目录同一份）
└─ src
   ├─ main.js                 ← createApp + router + 全局样式
   ├─ App.vue                 ← 只有 <router-view>
   ├─ router\index.js         ← / → /login，/login，/register，/home
   ├─ api\request.js          ← axios 实例，baseURL=/api，拦截器拆出 {code,msg,data}
   ├─ api\auth.js             ← login / register / checkUsername / hello
   ├─ styles\global.css       ★ 主题全在这里：海洋背景、气泡、海绵卡片、按钮
   ├─ components\OceanBg.vue  ← 海底场景（气泡 + 海床 + 海草），用 <slot> 包内容
   ├─ components\SpongeBob.vue← 海绵宝宝 SVG 头像
   └─ views\
      ├─ LoginView.vue        ← 登录页
      ├─ RegisterView.vue     ← 注册页
      └─ HomeView.vue         ← 登录成功后的首页（展示用户信息 + 后端连通测试）
```

---

## 3. 与后端对接的约定（改前后端要同步改）

| 前端调用 | 后端接口 | 是否需要登录 |
| --- | --- | --- |
| `hello()` | `GET /api/auth/hello` | 否（连通性自检） |
| `checkUsername(u)` | `GET /api/auth/check?username=u`，`data=true` 表示已占用 | 否 |
| `login({username,password})` | `POST /api/auth/login` | 否 |
| `register({username,password,nickname})` | `POST /api/auth/register` | 否 |
| `profile()` | `GET /api/auth/profile` | **是** |
| `logout()` | `POST /api/auth/logout` | **是** |

统一返回体：`{ code, msg, data }`，**`code === 200` 才算成功**；`401` = 令牌失效。

**登录态怎么存的**（本地存储三件套）：
- `localStorage['bob_token']` — 登录令牌，`request.js` 的请求拦截器自动塞进 `Authorization` 头
- `localStorage['bob_user']` — 用户对象（首页先读它秒渲染，再用 `profile()` 校准）
- `localStorage['bob_username']` — 「记住我」回填用户名

`request.js` 响应拦截器发现 `code === 401` 会调用 `clearSession()` 并跳转到 `/login`。

**令牌有效期 2 小时**（后端 `token_expire` 字段）：过期后后端返回 401，前端自动清态跳登录页，
无需前端自己算时间；首页会展示「令牌有效期至」方便观察。

---

## 4. 启动 / 停止（唯一推荐做法）

```bat
启动前端.bat      :: 自动 npm install（若 node_modules 不存在）+ npm run dev
停止前端.bat      :: 按 5173 端口结束进程
启动全部.bat      :: 先启后端（D:\workSpace\springBootTest\启动后端.bat）再启前端
停止全部.bat      :: 两个一起停
```

手工等价命令：
```bash
npm install
npm run dev        # http://localhost:5173
npm run build      # 产物在 dist/
```

---

## 5. 已知坑（遇到了照着做，不要重新排查）

1. **后端没起 → 登录报「网络异常，请检查后端是否已启动」**：先跑后端 `启动后端.bat`。
2. **改后端端口**必须同时改 `vite.config.js` 的 `BACKEND` 常量。
3. **Vite 端口被占用会自动换到 5174**，此时 `停止前端.bat` 只杀 5173 会漏掉，手动再杀一次 5174。
4. **路由守卫**：`router/index.js` 的 `beforeEach` 要求 `meta.requiresAuth` 的路由必须有
   `bob_token`，否则跳 `/login?redirect=<原路径>`，登录成功后自动跳回原目标页。
   （HomeView 里另有一层 `bob_user` 兜底判断，双保险。）
5. **样式全在 `global.css` + 组件内 `<style scoped>`**，没有 Tailwind/Element Plus，别去找 UI 库。
6. 用户名规则 `^[A-Za-z0-9_]{4,20}$`，密码 ≥ 6 位，前后端各校验一次。
7. 密码在后端用 MD5 加盐（`Md5Util`，盐 `bikini_bottom_spongebob`）存储，前端传明文，靠 HTTP 本地传输。

---

## 6. 这个项目目前「缺」的东西（按优先级）

| 优先级 | 缺失项 | 建议 |
| --- | --- | --- |
| ~~高~~ | ~~没有登录凭证~~ | **本次已补**：登录返回 token，`request.js` 自动带 `Authorization` 头 |
| ~~高~~ | ~~没有路由守卫~~ | **本次已补**：`router.beforeEach` + `meta.requiresAuth` |
| ~~中~~ | ~~没有实际业务页面（只有登录注册）~~ | **本次已补**：`/users` 用户列表（分页 + 搜索） |
| ~~中~~ | ~~Token 无过期~~ | **本次已补**：后端 2 小时有效期，过期返回 401 自动跳登录 |
| 中 | Token 是 UUID 而非 JWT（无自解析、无刷新） | 换 JWT，或加刷新令牌机制 |
| 中 | 没有 Pinia 状态管理 | 用户量小可先不做 |
| 中 | 没有 404 页面 / 没有全局 loading | 补一个 NotFound.vue |
| 中 | 没有环境变量文件 `.env.development` | 把 8081 抽到 `.env` |
| 低 | 没有单元测试 | Vitest |
| 低 | 移动端适配只做了最小宽度 | 补媒体查询 |

---

## 7. 本次会话已做过的事（避免重复劳动）

- 由单文件 `spongebob-login.html` 拆成 Vue 组件：`OceanBg` / `SpongeBob` / 三个页面
- 主题 CSS 抽到 `src/styles/global.css`
- 配置 `/api` 代理、axios 拦截器、`api/auth.js`
- 写成 Vue 项目（package.json / vite.config.js / router）
- 写 `启动前端.bat` / `停止前端.bat` / `启动全部.bat` / `停止全部.bat`（GBK + CRLF + 相对路径）
- 补登录凭证：`request.js` 请求/响应拦截器（自动带 token、401 自动清态跳登录）、
  `router.beforeEach` 守卫、`profile()` / `logout()` 接口、首页展示令牌前 8 位
- `启动前端.bat` 优先用 `npm ci`（有 lock 文件时更快），失败再退 `npm install`
- 写本文件
- 首页增加「令牌有效期至」一行，展示后端下发的 `tokenExpire`
- 新增用户列表页：`api/user.js` + `views/UsersView.vue`（海绵宝宝风格表格、分页、关键字搜索），
  路由 `/users`（需登录），首页加了「查看居民名单」入口按钮
- **已实测通过**：`npm run build` 成功；一键启动/停止脚本验证通过；
  后端 token 流程（有效/无/假/过期/退出后）五种情况全部符合预期

**下次会话请直接读本文件 → 执行 启动全部.bat → 不要重复以上步骤、不要重新探测环境。**
