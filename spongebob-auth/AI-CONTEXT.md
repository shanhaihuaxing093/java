# AI-CONTEXT.md —— 机器速读档案（比奇堡登录注册项目）

> 作用：本文件是写给我（AI/助手）看的。下次打开这个项目，**先只读这一个文件**，
> 按「固定事实」直接执行，**不要重新探测环境、不要重新设计架构、不要反复确认**。
> 只有事实明显失效（端口连不上、依赖装不上、文件不存在）时才重新检查。
>
> ⚠️ **重要前提**：这台机器「每次开机重置」，`node_modules`、`target`、以及 D 盘里的后端工程
> 都可能被清掉。真出现文件缺失时，直接看第 8 节「机器重置后的复原步骤」。
>
> 🚀 **开机后先看 `AI-BOOT.md`**（同目录）：那是本文件的「开机摘要版」，
> 只讲怎么用脚本三十秒把前后端拉起来，避免每次开机重复排查一遍。
> 本文件是完整档案，两者冲突时以本文件为准（并记得回头把 AI-BOOT.md 同步掉）。

---

## 0. 一句话定位

**海绵宝宝（比奇堡）主题的登录注册全栈项目**，前后端分别在两个目录：

| 端 | 目录 | 技术栈 |
| --- | --- | --- |
| 前端 | `D:\workSpace\java\spongebob-auth`（WorkBuddy 工作区有同步副本） | Vue 3.5 + Vite 5.4 + vue-router 4 + axios 1.7，**无 UI 库**（纯手写 CSS 主题） |
| 后端 | `D:\workSpace\springBootTest` | SpringBoot 3.4.5 + MyBatis-Plus 3.5.9 + MySQL 8（**⚠️ 2026-10-28 起认证代码被重置清空，待复原**） |

> **当前状态速览**：前端四页（登录/注册/首页/用户列表）已完成；
> 后端只剩 `SpringBootTestApplication` + `UserController`，`/api/auth/*`、`/api/user/page` 全 404；
> 启动脚本已含三级兜底 + 秒级缓存恢复（`%USERPROFILE%\.bikini-cache`）。
> 开机先看 `AI-BOOT.md` 第 0 节。

---

## 1. 固定事实（已在本机验证，直接采信）

| 项目 | 值 |
| --- | --- |
| 前端目录 | `D:\workSpace\java\spongebob-auth`（脚本用脚本自身位置定位，搬走也能跑） |
| 后端目录 | `D:\workSpace\springBootTest`（**认证代码 2026-10-28 被重置清空，待复原**） |
| 依赖缓存 | `%USERPROFILE%\.bikini-cache\`：`spongebob-node_modules.zip`（恢复 0.5s）+ 后端成品 jar（robocopy 秒级恢复），开机重置**不会**清掉它，启动脚本自动用、自动更新 |
| 前端开发端口 | **5173**（`VITE_PORT`；被占用时 Vite 自动顺延 5174） |
| 代理规则 | `/api` → `http://localhost:8081`（`vite.config.js` 读 `.env` 的 `VITE_BACKEND_URL`） |
| 后端端口 | **8081**（`application-dev.properties` 的 `server.port`；`spring.profiles.active=dev`） |
| **后端必须先启动** | 否则前端登录注册报「网络异常，请检查后端是否已启动」 |
| Node / npm | v22.22.2 / 10.9.7（PATH 可用） |
| JDK | Zulu **21**（`JAVA_HOME=C:\Program Files\Zulu\zulu-21\`），工程 `java.version=17`，用 21 编译运行正常 |
| Maven | 系统 PATH **没有** mvn；可用的是 `mvnw.cmd`（wrapper 发行包已缓存在 `~/.m2/wrapper/dists/apache-maven-3.9.9-bin/`）+ IDEA 内置 `D:\IntelliJ IDEA 2024.3.2.2\plugins\maven\lib\maven3\bin\mvn.cmd` |
| MySQL | 8.0，服务已随系统启动，监听 3306；`root / 123456`，库 `spongebob_auth` |
| MySQL 客户端 | `C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe`（**不在 PATH**，要用全路径） |
| 测试账号 | `spongebob / 123456`、`patrick / 123456`、`squidward / 123456`（密码密文见 sql 脚本） |
| 密码算法 | `md5( md5(明文) + "bikini_bottom_spongebob" )`，即 `Md5Util.encrypt()`，**改盐会让内置账号全部登不上** |

**机器每次开机重置**：前端 `node_modules` 会被删除 → 启动脚本自带 `npm ci / npm install`。

### ⚠️ 本机环境的两个坑（Agent 调试时必看）

1. **环境变量里有 HTTP 代理**：`http_proxy=http://127.0.0.1:56522`。
   用 `curl` 访问 localhost 会被代理拦掉，报 `upstream connect failed`。
   先 `export no_proxy="localhost,127.0.0.1"` 再 curl。
2. **环境变量 `SERVER__PORT=56474`**：Spring 的宽松绑定会把 `SERVER__PORT` 当成
   `server.port`，导致 Tomcat 绑到 56474 而不是 8081。
   所以启动后端时**显式带 `--server.port=8081`**（命令行参数优先级最高），各脚本已内置。

---

## 2. 目录地图

```
D:\workSpace\java\spongebob-auth\   （前端，曾位于桌面，已迁移）
├─ AI-BOOT.md                 ★ 开机速读卡：先读它（专治「每次开机重建」）
├─ AI-CONTEXT.md              ← 本文件（完整档案）
├─ home-preview.html          ★ 仅本地开发用：写假令牌绕守卫直达 /home 预览首页
├─ .env                       ★ 端口/后端地址/超时（dev 和 build 都读）
├─ .env.example               ← 模板，复制成 .env.local 覆盖
├─ .gitignore                 ← 忽略 node_modules / dist / .env.local
├─ .gitattributes             ★ 把 *.bat 标成 binary（否则换行会被 git 转换，见第 5 节第 15 条）
├─ package.json               ← dev / build / preview
├─ vite.config.js             ← 读 .env，端口 + /api 代理
├─ index.html
├─ sql\spongebob_auth.sql     ← 建库建表脚本（与后端 sql 目录同一份）
├─ 启动全部.bat / 停止全部.bat  ★ 一键启停；自动定位后端 + 检查 MySQL / 自动建库
├─ 启动前端.bat / 停止前端.bat
├─ 环境复原.bat               ← 全乱了一键重置（删 node_modules/dist/target 重来，带确认）
├─ docs\
│  └─ 原型-登录页.html        ← 最初的单文件版登录页（视觉基准，可直接双击打开）
├─ tools\
│  ├─ test-api.sh             ← 28 项后端接口验收（退出码 = 失败项数）
│  ├─ bat-to-gbk.py           ← .bat 转 GBK+CRLF，**改完任何 .bat 必跑**
│  └─ check-bat.py            ← .bat 静态自检（标签引用 / 括号配平 / 引号 / 编码）
└─ src
   ├─ main.js                 ← createApp + router + 全局样式
   ├─ App.vue                 ← <router-view> + <GlobalLoading> + <ToastHost>
   ├─ router\index.js         ← 守卫 + 404 兜底；根路径「有令牌进 /home，无令牌进 /login」
   ├─ utils\loading.js        ★ 全局请求计数器（顶栏进度条用）
   ├─ utils\toast.js          ← 极轻量全局提示（无 UI 库 / 无 Pinia）
   ├─ api\request.js          ← axios 实例、令牌注入、401 清态跳登录、进度条开关
   ├─ api\auth.js             ← login / register / checkUsername / hello / profile / logout
   ├─ api\user.js             ← userPage（分页 + 关键字）
   ├─ api\home.js             ★ 首页接口层：预留 /api/home/*，失败自动降级本地 Mock
   ├─ config\nav.js           ★ 首页静态数据：导航 / 蟹堡菜单 / 快捷入口 / 公告 / Mock
   ├─ styles\global.css       ★ 主题全在这里（海洋背景、气泡、海绵卡片、按钮、响应式）
   ├─ components\OceanBg.vue  ← 海底场景（气泡 + 海床 + 海草），用 <slot> 包内容
   ├─ components\SpongeBob.vue← 海绵宝宝 SVG 头像
   ├─ components\GlobalLoading.vue ← 顶部加载进度条
   ├─ components\AppTopBar.vue ← 顶部导航栏：品牌 + 全局搜索栏 + 用户菜单
   ├─ components\AppSideBar.vue← 左侧导航（≤768px 变抽屉）
   ├─ components\ToastHost.vue ← 全局提示渲染（挂 App.vue）
   └─ views\
      ├─ LoginView.vue        ← 登录页（成功后跳 /home）
      ├─ RegisterView.vue     ← 注册页
      ├─ HomeView.vue         ★ 首页仪表盘：欢迎横幅 + 概览卡片 + 快捷入口 + 公告 + 最近居民
      ├─ UsersView.vue        ← 用户列表（分页 + 搜索）
      └─ NotFoundView.vue     ← 404 页

D:\workSpace\springBootTest\                    （后端，⚠️ 2026-10-28 被重置回滚过一轮）
├─ AI-BOOT.md                 ★ 后端开机速读卡（2026-10-28 重写，含待复原清单）
├─ .gitattributes / .gitignore ← 忽略 target/log/.idea；`*.bat` 标 binary 防换行转换
├─ pom.xml                    ← ⚠️ 目前是回滚后的旧版（web+thymeleaf），**缺** mybatis-plus 两件套
├─ mvnw / mvnw.cmd / .mvn     ← Maven wrapper
├─ sql\spongebob_auth.sql     ← 2026-10-28 从前端镜像过来，与前端同一份建库脚本
├─ 启动后端.bat / 停止后端.bat   ← 2026-10-28 重建；jar 三级兜底（现成/缓存/打包）+ /force + /nopause
├─ HELP.md                    ← Spring Initializr 模板
├─ tools\
│  ├─ check-build.ps1         ← 判断 jar 要不要重打（exit 0 跳过 / 1 重打）
│  ├─ bat-to-gbk.py          ← 与前端同一份
│  └─ check-bat.py           ← 与前端同一份
└─ src\main\
   ├─ java\com\fenglin\springboottest\   ← ⚠️ 只剩下面两个，其余 13 个业务文件待复原
   │  ├─ SpringBootTestApplication.java
   │  ├─ UserController.java        ← 项目原有的 Thymeleaf 教学示例（勿删）
   │  └─ （common\Result.java、GlobalExceptionHandler、config\WebConfig、config\MybatisPlusConfig、
   │     interceptor\TokenInterceptor、controller\AuthController、controller\SysUserController、
   │     service\AuthService、mapper\SysUserMapper、entity\SysUser、dto\LoginDTO/RegisterDTO、
   │     util\Md5Util 全部待复原，接口约定见第 3 节）
   └─ resources\
      ├─ application.properties     ← 激活 dev、日志（⚠️ 日志格式里的中文注释是乱码，待修）
      └─ application-dev.properties ★ 目前只剩 server.port=8081；**数据源等配置待复原**
```

---

## 3. 与后端对接的约定（改前后端要同步改）

| 前端调用 | 后端接口 | 需要令牌 |
| --- | --- | --- |
| `hello()` | `GET /api/auth/hello` | 否 |
| `checkUsername(u)` | `GET /api/auth/check?username=u`，`data=true` = 已占用 | 否 |
| `login({username,password})` | `POST /api/auth/login` | 否 |
| `register({username,password,nickname})` | `POST /api/auth/register` | 否 |
| `profile()` | `GET /api/auth/profile` | **是** |
| `logout()` | `POST /api/auth/logout` | **是** |
| `userPage({page,size,keyword})` | `GET /api/user/page`，`data` 是 IPage 形状 | **是** |

统一返回体：`{ code, msg, data }`，**`code === 200` 才算成功**。
`code`：200 成功 / 400 业务失败 / 401 令牌失效 / 403 账号禁用 / 500 服务端异常。

### 3.1 登录态怎么存的（localStorage 三件套）
- `bob_token` — 登录令牌，`request.js` 请求拦截器自动塞进 `Authorization` 头（**裸令牌，不带 Bearer**；后端也兼容 `Bearer ` 前缀）
- `bob_user` — 用户对象（首页先读它秒渲染，再用 `profile()` 校准）
- `bob_username` — 「记住我」回填用户名

### 3.2 令牌规则
UUID 存 `sys_user.token`，有效期 **2 小时**（`token_expire`）；同一账号再登录会顶掉旧令牌（单点登录）；
`validateToken()` 发现过期会顺手把脏令牌清掉。首页展示「令牌有效期至」。

### 3.3 ⚠️ 令牌失效为什么返回「HTTP 200 + code 401」
前端 `request.js` 是在**响应成功分支**里判断 `data.code === 401` 来做清态跳转的。
如果后端直接返回 HTTP 401，axios 会走 reject 分支，前端就清不了登录态。
所以 `TokenInterceptor` 故意 `setStatus(200)` + 手写 JSON 体。
`request.js` 的 error 分支另外兜了一层真实 HTTP 401，两边都安全。

---

## 4. 启动 / 停止（唯一推荐做法）

**开机后只需要双击 `启动全部.bat`。** 它会依次：定位后端工程 → 确保 MySQL 在跑、库存在
→ 起后端（target 没了自动打包）→ 起前端（node_modules 没了自动 `npm ci`）→ 自检 → 开浏览器。

```bat
:: 前端目录
启动全部.bat      :: ★ 一键：MySQL + 后端 8081 + 前端 5173 + 自检 + 开浏览器
停止全部.bat      :: 停前端 5173/5174/5175 + 后端 8081（MySQL 不停）
启动前端.bat      :: node_modules 不在就自动装；端口读 .env 的 VITE_PORT
停止前端.bat      :: 按 5173 / 5174 / 5175 端口结束进程
环境复原.bat      :: 删 node_modules/dist/target → 重装重编译重建（有 Y/N 确认）

:: 后端目录
启动后端.bat      :: 检查 JDK/端口 → 判断要不要打包（jar 是最新就跳过）→ java -jar 起 8081
启动后端.bat /force  :: 强制 clean + 重新打包（改完 Java 代码没生效时用）
停止后端.bat      :: 按 8081 端口结束进程
```

### 脚本的硬约定（改脚本时必须守住）

1. **路径全部从脚本自身推导**（`%~dp0`），项目文件夹整体搬走也能跑。
2. **绝不读 `node_modules` / `target` 里的内容**——它们每次开机都被清空，
   脚本只能判断「在不在」和「比源码新不新」。
3. **编码必须 GBK + CRLF + 无 BOM**。写完后跑 `python tools/bat-to-gbk.py`。
   带 UTF-8 BOM 的 .bat 会让 cmd 把第一行 `@echo off` 读坏。
4. 所有脚本接受 `/nopause`：被别的脚本 `call` 时不要停下来等人按键。
5. 注释里**不要出现 `%` 号**（比如 `%~dp0`），cmd 在 `rem` 行也会试着展开百分号。

### 后端在另一个盘符怎么办

C 盘到 D 盘没法用相对路径。`启动全部.bat` 里的 `:findBackend` 按这个顺序自动找：

1. 本项目内的 `backend\` 子目录（**想要纯相对路径就把后端整个搬进来，脚本不用改**）
2. 环境变量 `BOB_BACKEND_DIR`
3. `D:\workSpace\springBootTest`（当前实际位置）
4. 扫描 `D:\workSpace`、`D:\`、桌面、IdeaProjects 下「有 `pom.xml` 且有 `启动后端.bat`」的目录


手工等价命令：
```bash
# 前端
npm ci && npm run dev      # http://localhost:5173
npm run build              # 产物在 dist/

# 后端（Bash / 终端里）
java -jar target/springBootTest-0.0.1-SNAPSHOT.jar --server.port=8081
```

---

## 5. 已知坑（遇到了照着做，不要重新排查）

1. **后端没起 → 登录报「网络异常，请检查后端是否已启动」**：先跑后端 `启动后端.bat`。
2. **改后端端口**要同时改两处：`application-dev.properties` 的 `server.port` 和前端 `.env` 的
   `VITE_BACKEND_URL`。前端不用改源码。
3. **MyBatis-Plus 从 3.5.9 起把分页插件拆走了**：只引 `mybatis-plus-spring-boot3-starter`
   会编译报「找不到符号 `PaginationInnerInterceptor`」，**必须再加**
   `com.baomidou:mybatis-plus-jsqlparser`（同版本号）。pom 里已加并写了注释。
4. **循环依赖**：`MybatisPlusInterceptor` 这个 Bean 不能放在 `WebConfig` 里
   （`WebConfig → TokenInterceptor → AuthService → SysUserMapper → MybatisPlusAutoConfiguration → WebConfig` 会成环，
   启动直接失败）。已单独放进 `MybatisPlusConfig`。
5. **Vite 端口被占用会自动换到 5174**，`停止前端.bat` 只杀 5173 会漏掉，手动再杀 5174。
6. **路由守卫**：`meta.requiresAuth` 的路由必须有 `bob_token`，否则跳
   `/login?redirect=<原路径>`，登录成功后自动跳回原目标页。`request.js` 的 401 跳转也带上 `redirect`。
7. **样式全在 `global.css` + 组件内 `<style scoped>`**，没有 Tailwind / Element Plus，别去找 UI 库。
8. 用户名规则 `^[A-Za-z0-9_]{4,20}$`，密码 ≥ 6 位，前后端各校验一次。
9. **`.bat` 必须 GBK + CRLF 且不能带 UTF-8 BOM**（cmd 代码页 936）。
   转码命令：`python tools/bat-to-gbk.py`（不带参数就转项目根目录下全部 .bat，幂等）。
   带 BOM 的话 cmd 会把第一行 `@echo off` 读坏，症状是启动时莫名弹报错。
10. **`SysUser.token` 千万不要加 `@JsonIgnore`**：登录页要靠响应体里的 `user.token` 存 localStorage。
    用户列表接口是在 Controller 里手动 `setToken(null)` 来防止泄漏他人令牌的。
11. **改完代码没生效？用 `启动后端.bat /force`**：曾出现「改了实体但 jar 里还是旧类」的情况
    （增量编译判断依赖变化导致的），clean 一次即可。
12. **`rem` 注释行里不要写 `%~dp0` / `%%~d` 这类百分号**：cmd 在 rem 行也会尝试做百分号展开，
    可能报「命令语法不正确」。注释里就写「脚本自身所在目录」这种大白话。
13. **`启动全部.bat` 里的 `net start MySQL80` 需要管理员权限**：非管理员双击会失败并打印警告，
    此时 MySQL 通常已经跟着系统起来了，脚本会继续往下走，不用管这条警告。
14. **本机没装浏览器**：`启动全部.bat` 结尾会检测 Edge/Chrome 路径，检测不到就只打印地址，
    不会弹「用什么打开」的窗口。装了浏览器之后它就自动帮你打开登录页。
15. **git 现状（2026-10-30 核对）**：前端目录属于**别人的仓库** `shanhaihuaxing093/java`
    （历史里是 snake-game 等无关内容），本项目文件只是其中一部分，**不要盲目 `git add .` 后提交**；
    后端**完全没有 git**。两边都没有本项目自己的版本控制 → 源码只在本机磁盘上，被重置就没了。
16. **`*.bat` 必须在 `.gitattributes` 里标成 `binary`** —— 本机 `core.autocrlf=true`，
    否则 git 会把 GBK 的 `.bat` 当文本、把 CRLF 规范化成 LF，
    检出后脚本变 LF 结尾，`goto` 和多行括号块直接失效。本轮已给后端补上这个标记。
17. **PowerShell 5.1 按 GBK 读无 BOM 的 `.ps1`**：如果 `.ps1` 存成 UTF-8 且含中文，
    会报「字符串缺少终止符」解析失败（本轮真实踩到）。
    所以 `tools/check-build.ps1` **故意全用英文纯 ASCII**，改动时保持 ASCII。
18. **代理端口是动态的**：旧记录写的 `56522` 已失效，本轮实测是 `62237`。
    不要写死端口，curl 一律 `--noproxy '*'`（或先 `export no_proxy="localhost,127.0.0.1"`）。
19. **`SysUser.password` 必须 `@JsonIgnore`**：只 `setPassword(null)` 不够，
    响应体里仍会出现 `"password":null`，验收脚本会判定为泄漏密码。
20. **AI 在 Bash 里 `&`/`nohup` 起的后端会被沙箱回收**：日志明明有 `Started in 1.7s`，
    但随后 netstat 就没了。这**不代表启动失败**，常驻必须让用户双击 `.bat`。
    同理 `cmd.exe` 从 PowerShell 工具调用会被安全策略拦截，所以 AI 无法实测 `.bat`，只能静态检查。

---

## 6. 这个项目目前「缺」的东西（按优先级）

| 优先级 | 缺失项 | 状态 |
| --- | --- | --- |
| ~~高~~ | ~~没有登录凭证~~ | ✅ 已补：登录返回 token，`request.js` 自动带 `Authorization` |
| ~~高~~ | ~~没有路由守卫~~ | ✅ 已补：`router.beforeEach` + `meta.requiresAuth` |
| ~~高~~ | ~~后端工程丢失（AuthController / MyBatis-Plus / MySQL 全没了）~~ | ✅ 第一轮已复原，见第 8 节 |
| ~~高~~ | ~~每次开机都要手工重建一遍（装依赖 / 打包 / 建库）~~ | ✅ **本轮已补**：`启动全部.bat` 一键搞定，见第 4 节 |
| ~~高~~ | ~~没有「给 AI 的开机速读卡」，每次都要重新排查环境~~ | ✅ **本轮已补**：`AI-BOOT.md` |
| ~~中~~ | ~~没有实际业务页面~~ | ✅ 已补：`/users` 用户列表（分页 + 搜索） |
| ~~中~~ | ~~Token 无过期~~ | ✅ 已补：2 小时有效期，过期 401 自动跳登录 |
| ~~中~~ | ~~没有 404 页面~~ | ✅ 已补：`NotFoundView.vue` + 路由兜底 |
| ~~中~~ | ~~没有全局 loading~~ | ✅ 已补：`utils/loading.js` + `GlobalLoading.vue` |
| ~~中~~ | ~~后端地址硬编码~~ | ✅ 已补：抽到 `.env` |
| ~~中~~ | ~~自检脚本放在项目目录外（重装就没了）~~ | ✅ **本轮已补**：`tools/test-api.sh` |
| ~~中~~ | ~~`.env.example` 用 `//` 当注释（dotenv 不认 `//`）~~ | ✅ **本轮已修**：改成 `#` |
| ~~中~~ | ~~`application.properties` 中文注释变 `?`、`logging.pattern.file` 值写错~~ | ✅ **本轮已修** |
| ~~低~~ | ~~移动端适配只做了最小宽度~~ | ✅ 已补：768 / 480 / 360 三档断点 |
| ~~低~~ | ~~没有 `.gitignore`~~ | ✅ 已补 |
| ~~低~~ | ~~每次启动都 full build，浪费 10~60 秒~~ | ✅ **本轮已补**：`check-build.ps1` 比时间戳，jar 最新就跳过打包 |
| ~~高~~ | ~~后端认证代码整包丢失（2026-10-28 机器重置回滚）：只剩 Application + UserController，pom 也没有 mybatis-plus 了，登录注册全 404~~ | ✅ **2026-10-30 已复原**：15 个 Java 文件 + pom 依赖 + 数据源配置，**28 项验收全通过** |
| ~~高~~ | ~~两个工程都没进 git，源码只存在本地磁盘~~ | ⚠️ 仍未解决：后端**没有 git**；前端挂在别人的仓库 `shanhaihuaxing093/java` 下，不建议盲目提交 |
| ~~中~~ | ~~后端只有「查列表」，没有增删改~~ | ✅ **2026-10-30 已补**：改昵称 / 改密码 / 禁用启用 / 删除，后端 4 接口 + 前端操作列，**25 项验收全通过** |
| ~~高~~ | ~~前端白屏：`App.vue` 引用了 6 个不存在的文件~~ | ✅ **2026-10-30 已补**：`ToastHost` / `AppTopBar` / `AppSideBar` / `nav.js` / `home.js` / `toast.js` 全部重建 |
| 中 | `/api/home/overview`、`/notices`、`/search` 三个接口未实现 | **用户明确要求先保留、不做后端**。前端已按约定路径调用，失败降级示例数据，实现后自动切换 |
| 中 | Token 是 UUID 而非 JWT（无自解析、无刷新） | 换 JWT，或加刷新令牌机制 |
| 中 | 没有 Pinia 状态管理 | 用户量小可先不做（全局 loading 用 reactive 单例代替） |
| 低 | 其他页面（蟹黄堡菜单 / 订单流水 / 营业报表 / 系统设置）都没做 | **用户明确说先不做**，导航里标 `built: false`，点击只弹「建设中」 |
| 低 | 没有单元测试 | 前端 Vitest；后端可先用 `Md5Util.main()` 冒烟 |
| 低 | 没有接口文档 | 加 springdoc-openapi（Swagger UI） |
| 低 | 过期 token 只在被人访问时才清 | 加个 `@Scheduled` 定时清理 |
| 低 | 生产部署只有前端 `dist/`，没有让 SpringBoot 托管前端的方案 | 需要时把 `dist` 产物放进后端 `resources/static/` |

---

## 7. 历次会话已做过的事（避免重复劳动）

**第一轮**
- 由单文件 `spongebob-login.html` 拆成 Vue 组件：`OceanBg` / `SpongeBob` / 三个页面
  （原型已归档到 `docs\原型-登录页.html`）
- 主题 CSS 抽到 `src/styles/global.css`；配置 `/api` 代理、axios 拦截器、`api/auth.js`
- 写成 Vue 项目（package.json / vite.config.js / router）
- 写 `启动前端.bat` / `停止前端.bat` / `启动全部.bat` / `停止全部.bat`（GBK + CRLF + 相对路径）
- 补登录凭证：请求/响应拦截器、路由守卫、`profile()` / `logout()`、首页展示令牌
- 新增用户列表页 `api/user.js` + `views/UsersView.vue`，路由 `/users`
- 写本文件

**第二轮**
- **复原后端**：机器重置把 `D:\workSpace\springBootTest` 里的认证代码全清了，
  重新补上 pom 依赖 + 15 个 Java 文件 + 数据源配置 + `启动后端.bat` / `停止后端.bat`
- 重建数据库：执行 `sql/spongebob_auth.sql`，三个内置账号回归
- **后端 28 项接口验收全部通过**（脚本见第 9 节）
- 前端补 404 页、全局 loading 进度条、`.env` 抽配置、三档响应式断点
- `npm run build` 通过；前端各模块经 Vite 转译全部 200，无编译错误

**第三轮（本次 · 针对「每次开机重置」做工程化）**
- 诊断出「开机要重复手工重建」这个真实痛点，把整套启停脚本重写：
  - `启动全部.bat` 新增：自动定位后端工程（4 级兜底）、检查/启动 MySQL 服务、**库不存在自动建库**、结尾自检 + 检测到浏览器才打开登录页
  - `启动后端.bat` 新增：**jar 是最新就跳过打包**（`tools/check-build.ps1` 比对源码时间戳，实测跳过 ✓ / 源码变新重打 ✓ / jar 缺失重打 ✓）、Maven 探测改为「每个候选先 `-v` 试跑」、启动后等端口就绪
  - `启动前端.bat` 新增：`node_modules` 完整性判断（不只看目录在不在，看 `vite` 是否装好）、端口从 `.env` 读
  - `停止前端.bat` 新增：一并清 5174 / 5175（Vite 端口顺延）
  - 新增 `环境复原.bat`：一键删构建产物重来（带 Y/N 确认）
- 所有 `.bat` 统一为 **GBK + CRLF + 无 BOM**；新增 `tools/bat-to-gbk.py` 做转换（幂等）
- 新增 **`AI-BOOT.md`**（前端 + 后端各一份）——给 AI 的开机速读卡
- 新增 `tools/test-api.sh`（28 项验收脚本从工作区收进项目）
- 修掉两个小毛病：`.env.example` 的 `//` 注释、`application.properties` 的中文注释变 `?` 及 `logging.pattern.file` 值写错

**第四轮（2026-10-28 · 首页 + 提速）**
- 前端从桌面迁到 `D:\workSpace\java\spongebob-auth`，并复制了一份到 WorkBuddy 工作区开发
- **首页改版**：HomeView 重写为仪表盘（欢迎横幅 + 概览卡片 + 快捷入口 + 公告 + 最近居民）；
  新增 `AppTopBar`（品牌 + 全局搜索栏 + 用户菜单）、`AppSideBar`（≤768px 抽屉）、
  `ToastHost` + `utils/toast.js`、`config/nav.js`、`api/home.js`（预留 /api/home/*，失败降级 Mock）
- 新增 `home-preview.html`（本地开发预览首页用：写假令牌绕守卫）
- 路由根路径改为「有令牌进 /home，无令牌进 /login」；`npm run build` 通过
- 改动已同步回 D 盘原项目（旧文件备份在其 `backup-20261028-首页改版前/`）

**第五轮（2026-10-28 · 一键启动提速 + 后端脚本复原）**
- 发现后端整包被重置回滚：启动脚本、tools、sql、AI 文档、**认证 Java 代码**全没了
- 重建 `启动后端.bat` / `停止后端.bat` / `tools/check-build.ps1`，镜像 `bat-to-gbk.py` / `check-bat.py` / sql 到后端
- **启动提速**：新增 `%USERPROFILE%\.bikini-cache`（node_modules 压缩包 + 成品 jar，重置清不掉）。
  `启动前端.bat` / `启动后端.bat` 改为三级兜底（现成 → 解缓存秒级恢复 → 联网/打包），
  装好/打包成功自动更新缓存。实测：依赖压缩 2.2s、恢复 0.5s（代替 45s+ npm ci）
- 重写前后端两份 `AI-BOOT.md`（当前状态、缓存机制、验证命令、待复原清单）

**第六轮（2026-10-30 · 后端认证代码复原 + 脚本补齐 + 提速实测）**

- 发现后端**又**被重置：`启动后端.bat`、`停止后端.bat`、`tools/`、`sql/`、`AI-BOOT.md`、
  **全部认证 Java 代码**都不见了；`spongebob_auth` 库也不存在；`~/.bikini-cache` 缓存目录不存在；`.env` 也没了
- 重建数据库：执行 `sql/spongebob_auth.sql`，三个内置账号回归
- **复原后端认证代码（15 个 Java 文件）**：
  `common/R`、`common/GlobalExceptionHandler`、`config/WebConfig`、`config/MybatisPlusConfig`、
  `controller/AuthController`、`controller/SysUserController`、`dto/LoginDTO`、`dto/RegisterDTO`、
  `entity/SysUser`、`interceptor/TokenInterceptor`、`mapper/SysUserMapper`、`service/AuthService`、`util/Md5Util`
- `pom.xml` 补 `mybatis-plus-spring-boot3-starter` + `mybatis-plus-jsqlparser` + `mysql-connector-j`
- `application-dev.properties` 补数据源 / Hikari / MyBatis-Plus / 令牌有效期；`application.properties` 修好中文注释乱码和 `logging.pattern.file` 写错的值
- **密码算法验证**：`md5(md5("123456") + "bikini_bottom_spongebob") = 54a66656018f3b1f43e2eef4bd608053`，与 sql 脚本密文精确一致
- **`SysUser.password` 加 `@JsonIgnore`、`deleted` 也隐藏**：验收脚本会判定响应体里出现 `password` 为泄漏
- 新建后端 `启动后端.bat` / `停止后端.bat` / `tools/check-build.ps1`（**全英文纯 ASCII**）/ `AI-BOOT.md`
- `启动后端.bat` 三级兜底：现成 jar → 缓存 jar → 打包；成功后自动更新缓存
- 重写前端 `启动全部.bat` / `启动前端.bat`：依赖完整性判断改为查 `node_modules/.bin/vite.cmd`
- 新建 `.env`（此前缺失）
- 补齐 `.gitattributes`：`*.bat binary`（GBK 脚本被 git 转成 LF 会导致 goto 失效）
- **实测数据**：打包 9~16.8s、后端启动 1.76s、Vite 0.85s、node_modules 缓存恢复 **0.36s**（对比 npm ci 47s）
- **28 项接口验收全部通过（0 失败）**

**第七轮（2026-10-30 · 用户增删改全链路 + 白屏真凶）**

- **发现严重问题：前端一直白屏，而之前的记录写着"已完成"是错的。**
  `App.vue` 引用了 6 个不存在的文件，Vite 报 `Failed to resolve import`：
  `components/ToastHost.vue`、`components/AppTopBar.vue`、`components/AppSideBar.vue`、
  `config/nav.js`、`api/home.js`、`utils/toast.js` —— 全部重建。
  **教训：前端 HTTP 200 只代表 HTML 回来了，必须查 `.vue` 模块有没有 `Failed to resolve`。**

- **用户增删改（后端 + 前端一起）**
  - 后端新增 4 接口：`PUT /api/user/{id}/nickname`、`PUT /api/user/{id}/password`、
    `PUT /api/user/{id}/status`、`DELETE /api/user/{id}`
  - 新增 DTO：`UpdateNicknameDTO`、`UpdatePasswordDTO`
  - `AuthService` 新增 `findById` / `updateNickname` / `updatePassword` / `setStatus` / `remove`
  - **安全约束**：只能改自己（越权 → 403）；不能禁自己、不能删自己（→ 400 + 明确中文）；
    改密码后清 token 强制下线；禁用时清 token
  - 前端 `api/user.js` 加 4 个方法；`UsersView.vue` 重写为带操作列的表格，
    自己的行显示「改昵称 / 改密码 / 本人」，他人行显示「禁用或启用 / 删除」，三个弹窗
  - 新增 `tools/test-crud.sh`：25 项验收，**跑完自动物理清理测试数据**

- **接口返回码分级（本轮确立，别改）**
  - 越权改别人 → `code:403`
  - 拒自己（禁/删）、参数非法、原密码错 → `code:400` + 明确中文
  - 未登录 / 令牌失效 → HTTP 200 + `code:401`
  - 目标不存在 → `code:400`「用户不存在」

- **按错点清单**
  - JDK 真实路径是 `C:\Program Files\Zulu\zulu-21`，`C:\Program Files\Java\jdk-21` 不存在（只有 `jdk-17`）
  - `no_proxy` 环境变量在 Git Bash 下不生效，**必须显式 `curl --noproxy '*'`**
  - Bash 里 `&` 起的后端会被沙箱回收，跑验收必须"起后端 → 跑脚本 → kill"在**同一次 Bash 调用**内完成
  - 用管道接 `grep` 判断命令成败会误判（`grep` 无匹配返回 1），要用命令自身退出码
  - 逻辑删除会在库里留 `deleted=1` 的行，清测试数据要 `delete ... where deleted=1`

- **清理**：数据库恢复为 3 个内置账号、`auto_increment=4`；jar 缓存刷新为含增删改的新版
- **验收：认证 28 项 + 增删改 25 项 = 53 项全通过，0 失败**

**第八轮（2026-10-30 · 首页重做，只做前端）**

用户要求：登录后跳首页，首页要有**搜索栏 + 导航栏**，风格参照**登录页**；
**只做前端，不做后端功能，后端接口先保留**；其他页面先不做。

- **新增 `src/styles/home.css`（首页皮肤层）**
  把登录页 `.sponge-card` / `.ocean` / `.btn` / `.field input` 这套物料，
  拆成可整页复用的类：`.shell`（海底外壳）、`.skin`（海绵卡片皮肤）、`.board`（奶油面板）、
  `.pk-btn` / `.pk-input` / `.pk-title` / `.pk-tag`。**不新增颜色，全部沿用 global.css 的 CSS 变量。**
  `main.js` 里 `import './styles/home.css'`。
- **`AppTopBar.vue` 重写**：品牌（🍍 比奇堡）→ **顶部导航条**（NAV_ITEMS，≤1180px 只留图标、≤900px 收进抽屉）
  → **搜索栏**（聚焦弹「试试这些」标签、输入 260ms 防抖、下拉结果、Esc 清空、点空白收起）
  → 用户菜单（头像 + 昵称 + 在岗状态，下拉含回到前台/居民名单/同步信息/退出）
- **`AppSideBar.vue` 重写**：顶部用户小卡（头像+昵称+在岗标签）+ 导航列表（图标/标题/副标题/建设中徽标）
  ≤900px 变抽屉（遮罩 + 滑入）
- **`HomeView.vue` 重写**：海底装饰层 → 顶栏 → 侧栏 + 主区（欢迎横幅 / 4 个概览数字 /
  快捷入口 + 公告双栏 / 最近居民卡片网格 / 数据来源脚注）
- **`config/nav.js` 扩充**：6 个导航项（home、residents、menu、orders、report、settings），
  只有前两个 `built: true`，其余点击只弹「建设中」toast
- **`api/home.js` 重写**：三个 `/api/home/*` 接口**保持调用但不做后端实现**，
  失败自动降级到示例数据并带 `_mock` 标记；`searchAll` 增加了「本地导航项模糊匹配 + 真实居民搜索」组合兜底
- **踩坑记录**：`SpongeBob.vue` 自带 `margin: -92px auto 6px`（为登录页卡片顶部探头设计），
  在首页横幅里复用时必须 `margin: 0` 覆盖，否则整个 SVG 会被顶出容器
- **自查补上的移动端缺陷**：第一版顶栏在 ≤900px 把导航条 `display:none` 收进抽屉，
  但**没有给抽屉留任何入口** —— `drawer` 状态无人触发，窄屏下用户等于没有菜单。
  已补：`.hamburger` 按钮（默认 `display:none`，≤900px 显示）+ `defineEmits` 加 `toggle`
  + HomeView `@toggle="drawer = !drawer"`；并给抽屉打开时锁 `body` 滚动
- 验证：110 个模块构建通过（1.11s）；产物 188.91 kB / gzip 72.10 kB
- 用户随后要求停止前后端，已按端口 5173/5174/5175/8081 结束进程并确认端口释放

---

## 8. 机器重置后的复原步骤（重要！）

开机发现后端目录空了 / 库没了，按这个顺序来：

```bash
# 0) 最快路径：缓存都在 %USERPROFILE%\.bikini-cache，直接解压/复制即可，不用联网
FE="D:/workSpace/java/spongebob-auth"
CACHE="/c/Users/Administrator/.bikini-cache"

# 1) 数据库（MySQL 服务要已启动，监听 3306）
"/c/Program Files/MySQL/MySQL Server 8.0/bin/mysql.exe" -uroot -p123456 \
  < "$FE/sql/spongebob_auth.sql"

# 2) 前端依赖：优先从缓存解压（秒级），缓存没有再 npm ci
[ -f "$CACHE/spongebob-node_modules.zip" ] && tar -xf "$CACHE/spongebob-node_modules.zip" -C "$FE" \
  || (cd "$FE" && npm ci)

# 3) 后端：优先从缓存复制 jar（秒级），缓存没有再打包（Bash 里 mvnw.cmd 跑不通，
#    用缓存的 maven 发行包跑 Launcher）
cd /d/workSpace/springBootTest
[ -f "$CACHE/springBootTest-0.0.1-SNAPSHOT.jar" ] && cp "$CACHE/springBootTest-0.0.1-SNAPSHOT.jar" target/ || {
  MA="C:/Users/Administrator/.m2/wrapper/dists/apache-maven-3.9.9-bin/4nf9hui3q3djbarqar9g711ggc/apache-maven-3.9.9"
  java -classpath "$MA/boot/plexus-classworlds-2.8.0.jar" \
    "-Dclassworlds.conf=$MA/bin/m2.conf" "-Dmaven.home=$MA" \
    "-Dmaven.multiModuleProjectDirectory=$(pwd -W)" \
    org.codehaus.plexus.classworlds.launcher.Launcher -B -DskipTests clean package
}

# 4) 起后端（必须显式指定端口，见 1.坑 2）
java -jar target/springBootTest-0.0.1-SNAPSHOT.jar --server.port=8081 &

# 5) 起前端
cd "$FE" && npm run dev &
```

> 日常给用户用的话，直接双击 `启动全部.bat` 就行（它会调两边的脚本）；
> 只有在我（AI）的 Bash 里，因为跑不了 cmd，才需要上面这套手工命令。

后端 Java 源码若也被清空，需要重建的文件清单见第 2 节目录地图中
`java\com\fenglin\springboottest\` 下的 15 个文件（业务逻辑照第 3 节的接口约定实现即可）。

---

## 9. Agent 自检 / 验收方法（Bash 里可用）

```bash
export no_proxy="localhost,127.0.0.1"        # 必须！否则被本机代理拦掉

# 后端是否活着
curl -s http://localhost:8081/api/auth/hello

# 登录拿令牌
curl -s -X POST http://localhost:8081/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"spongebob","password":"123456"}'

# 通过 Vite 代理访问（验证前后端链路）
curl -s http://localhost:5173/api/auth/hello
```

完整验收脚本（28 项：连通性 / 用户名占用 / 登录 / 令牌三态 / 分页搜索 / 注册校验 / 退出）
就在项目里：`bash tools/test-api.sh`，退出码 = 失败项数。
`.bat` 转 GBK 的小工具：`python tools/bat-to-gbk.py`（幂等，可反复跑）。

### 日常最快路径

开机后**什么都别探测**，直接：

```bat
启动全部.bat          :: 用户双击
```

AI 要确认状态，就三条 curl（见本节最上面）+ `bash tools/test-api.sh`。
要手工起后端（因为 AI 跑不了 .bat），用第 8 节第 3~4 步那套命令。
