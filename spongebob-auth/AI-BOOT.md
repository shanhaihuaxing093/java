# AI-BOOT.md —— 开机速读卡（写给 AI 看的，读完直接动手）

> **这份文件是写给 AI（也就是我）看的。开机第一件事读它，读完直接动手。**
> 不要重新探测环境，不要重新设计架构，不要 clean 重建，不要反复问用户。
> 下面写的都是**已经在本机实测过**的事实。冲突时以本文件为准。
>
> 最后验证时间：**2026-10-30 16:45**（本轮：**首页重做**，110 模块构建通过 1.11s；认证 28 项 + 增删改 25 项 = 51 项接口验收全通过）

---

## 0. 三十秒看懂现状

| 部分 | 状态 |
| --- | --- |
| 前端 `D:\workSpace\java\spongebob-auth` | ✅ **首页已重做**：搜索栏 + 顶部导航 + 左侧导航 + 仪表盘 |
| 后端 `D:\workSpace\springBootTest` | ✅ 认证 + 增删改全部就位，51 项接口验收全通过 |
| MySQL `spongebob_auth` | ✅ 库和 **3 个内置账号**都在 |
| 启停脚本 | ✅ 前后端各一套，GBK + CRLF，静态检查全通过 |
| 加速缓存 `%USERPROFILE%\.bikini-cache` | ✅ 已生成（node_modules.zip 13MB + jar 29MB，jar 含增删改） |

**一句话：登录后进入的 `/home` 是完整仪表盘 —— 顶部有品牌/导航/搜索/用户菜单，左侧有导航，右侧是欢迎横幅、4 个概览数字、快捷入口、公告、最近居民。**

首页样式**全部对齐登录页**：同一套 CSS 变量、同样的「厚边框 + 实心投影 + 珊瑚黄凹点」物料，
地图式的蓝色渐变海水背景 + 上浮气泡 + 海床海草。`src/styles/home.css` 是这套物料的放大版。

**后端接口目前全部是"保留"状态**：首页调 `/api/home/overview`、`/api/home/notices`、
`/api/home/search` 三个**还没实现**的接口，失败自动降级到本地示例数据（并显示提示），
后端一旦实现就自动切过去，**前端不用改**。居民区走的是已实现的 `/api/user/page`，是真实数据。

⚠️ **本轮教训仍然有效**：验证前端别只看 HTTP 200，必须查 `Failed to resolve import`：
```bash
curl -s --noproxy '*' http://localhost:5173/src/views/HomeView.vue | grep -c "Failed to resolve"
# 输出 0 才算真的好了
```

---

## 1. 唯一要记住的操作

| 想干什么 | 做什么 |
| --- | --- |
| **起服务** | 双击 `D:\workSpace\java\spongebob-auth\启动全部.bat` ← **95% 的情况只需要这个** |
| 停服务 | 双击 `停止全部.bat` |
| 只起前端 | 双击 `启动前端.bat` |
| 全乱了 | 双击 `环境复原.bat` |

`启动全部.bat` 会自己搞定：定位后端 → 检查/启动 MySQL → 建库（缺就建）→ 起后端（target 没了自动从缓存恢复或打包）→ 起前端（node_modules 没了自动从缓存恢复或安装）→ 自检 → 开浏览器。

**"跑通了"的判定标准：**
- 前端 OK = `http://localhost:5173` 打开不白屏
- 后端 OK = `http://localhost:8081/api/auth/hello` 返回 `code:200`
- **登录 OK = `spongebob / 123456` 能进首页，`/users` 能看到三个居民**
- **增删改 OK = 在 `/users` 里能给 `patrick` 改昵称、能禁用它、能删除它**（已验证）

⚠️ **验证前端千万别只看 HTTP 200**。正确的验法是查 Vite 有没有 `Failed to resolve import`：
```bash
curl -s --noproxy '*' http://localhost:5173/src/App.vue | grep -c "Failed to resolve"
# 输出 0 才算真的好了
```

---

## 2. 固定事实（已实测，不要再测一遍）

| 项目 | 值 |
| --- | --- |
| 前端目录 | `D:\workSpace\java\spongebob-auth` — Vue 3.5 + Vite 5.4，**没有任何 UI 库** |
| 后端目录 | `D:\workSpace\springBootTest` — SpringBoot 3.4.5，包名 `com.fenglin.springboottest` |
| 端口 | 前端 **5173**、后端 **8081**、MySQL **3306** |
| Node / JDK | Node v22.22.2 ✓；JDK 21.0.10 ✓；**Maven 不在 PATH**（用 `mvnw.cmd`） |
| Maven 镜像 | `.m2` 已配阿里云，打包 16.8 秒 |
| MySQL | 服务 `MySQL80`，`root/123456`，库 `spongebob_auth` |
| mysql.exe | `C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe`（不在 PATH） |
| 测试账号 | `spongebob` / `patrick` / `squidward`，密码都是 `123456` |
| 每次开机被清 | 前端 `node_modules`、后端 `target` |
| 不会被清 | `src`、`pom.xml`、`package-lock.json`、`.m2`、`%USERPROFILE%\.bikini-cache` |
| git | 前端挂在**别人的仓库** `shanhaihuaxing093/java`（历史全是 snake-game），本项目文件只是其中一部分；**后端没有 git** |

### ⭐ 启动加速缓存（本轮已建好并实测）

`%USERPROFILE%\.bikini-cache\`（开机重置清不掉）：

| 文件 | 作用 | 实测 |
| --- | --- | --- |
| `spongebob-node_modules.zip` | 13MB，node_modules 被清后解压恢复 | 压缩 2.0s / **恢复 0.36s**（代替 47s 的 npm ci） |
| `springBootTest-0.0.1-SNAPSHOT.jar` | 22MB 成品 jar，target 被清后复制恢复 | 秒级（代替 16.8s 打包） |

**脚本已内置三级兜底**：现成 → 缓存恢复 → 联网装/打包，成功后自动更新缓存。
AI **不需要**手动维护缓存，除非用户说缓存坏了（那就删掉目录让脚本重建）。

### 三个必须知道的坑（踩过的，别再踩）

1. **HTTP 代理是动态端口** —— 之前记录是 56522，本轮实测是 **62237**。
   curl localhost 前必须 `export no_proxy="localhost,127.0.0.1"`，或者直接 `curl --noproxy '*'`。
   **不要写死代理端口**，它每次都变。
2. **环境变量 `SERVER__PORT` 会抢端口** —— Spring 宽松绑定会认这个变量，
   所以起后端**必须**显式 `--server.port=8081`（脚本已内置，别手漏）。
3. **PowerShell 的 .ps1 不能写中文** —— Windows PowerShell 5.1 把无 BOM 的 .ps1 按 GBK 读，
   UTF-8 中文会变成乱码并导致「字符串缺少终止符」解析失败。
   `tools\check-build.ps1` 因此**故意全用英文**，改动时保持 ASCII。

---

## 3. AI 在 Bash 里怎么验证（先自己验，别问用户）

```bash
export no_proxy="localhost,127.0.0.1"      # 必须！代理端口每次都变

# 前端活着 = 200（但这只说明 HTML 回来了，不说明页面能用）
curl -s --noproxy '*' -o /dev/null -w "%{http_code}\n" http://localhost:5173/

# 前端真能用 = 下面输出 0（没有解析失败的模块）
curl -s --noproxy '*' http://localhost:5173/src/App.vue | grep -c "Failed to resolve"

# 后端活着
curl -s --noproxy '*' http://localhost:8081/api/auth/hello

# 登录拿令牌（然后所有 /api/user/* 都要带这个头）
TK=$(curl -s --noproxy '*' -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"spongebob","password":"123456"}' \
  | python -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
curl -s --noproxy '*' "http://localhost:8081/api/user/page?current=1&size=10" \
  -H "Authorization: Bearer $TK"

# 数据库
"/c/Program Files/MySQL/MySQL Server 8.0/bin/mysql.exe" -uroot -p123456 \
  -e "select username from spongebob_auth.sys_user;"
```

验收脚本（会自己登录、自己造测试用户、**跑完自己物理清理**）：
```bash
bash tools/test-api.sh          # 认证 28 项
bash tools/test-crud.sh         # 增删改 25 项
```

⚠️ 跑之前后端必须活着。**AI 在同一个 Bash 调用里"起后端 → 跑脚本 → kill"**，
否则沙箱回收进程后脚本全部返回空（会看到 24 项 FAIL、实际值全空 —— 那不是代码问题）：

```bash
cd /d/workSpace/springBootTest
"/c/Program Files/Zulu/zulu-21/bin/java.exe" -jar target/*.jar --server.port=8081 > /tmp/b.log 2>&1 &
JPID=$!
for i in $(seq 1 30); do R=$(curl -s --noproxy '*' -m 2 http://localhost:8081/api/auth/hello); \
  [ -n "$R" ] && break; sleep 1; done
cd /d/workSpace/java/spongebob-auth && bash tools/test-crud.sh
kill $JPID
```

⚠️ **JDK 真实路径是 `C:\Program Files\Zulu\zulu-21`，不是 `jdk-21`**（`jdk-17` 那个目录是旧的）。
⚠️ **`--noproxy '*'` 必须显式写**，只设 `no_proxy` 环境变量在 Git Bash 下不生效（实测返回空）。

⚠️ **AI 跑不了 .bat**（安全策略拉黑 cmd.exe），只能静态检查 + 让用户双击。
⚠️ **AI 在 Bash 里 `nohup`/`&` 起的后端会被回收**（沙箱进程生命周期），
日志里能看到 `Started ... in 1.7s` 但之后 netstat 就没了 —— **这不是启动失败**，
是进程被回收了。要常驻必须让用户双击 `.bat`（那个 cmd 窗口会一直挂着）。

改任何 `.bat` 之后必跑：
```bash
python tools/bat-to-gbk.py      # 转 GBK + CRLF（幂等）
python tools/check-bat.py       # 静态自检
```

**bat 硬约束**：GBK + CRLF + 无 BOM；路径全从脚本自身推导；**不读 node_modules/target 里的内容**（只判断在不在）；`rem` 注释里别写 `%` 号。

---

## 4. 脚本清单

### 前端 `D:\workSpace\java\spongebob-auth\`

| 脚本 | 承诺 |
| --- | --- |
| `启动全部.bat` | 定位后端 → 确保 MySQL/库 → 起后端 → 起前端 → 自检 → 开浏览器 |
| `停止全部.bat` | 停前端 5173/5174/5175 + 后端 8081（MySQL 不停） |
| `启动前端.bat` | 依赖三级兜底，判断标准是 `node_modules/.bin/vite.cmd` 存在（不只看目录） |
| `停止前端.bat` | 清 5173 / 5174 / 5175 |
| `环境复原.bat` | 删 node_modules/dist/target → 重装重编译重建（有 Y/N 确认） |
| `tools\bat-to-gbk.py` | 转 GBK + CRLF（幂等） |
| `tools\check-bat.py` | bat 静态自检（标签/括号/引号/编码） |
| `tools\test-api.sh` | 28 项认证接口验收 |
| `tools\test-crud.sh` | 23 项增删改验收（改昵称/改密码/禁用/删除 + 越权防护） |

### 后端 `D:\workSpace\springBootTest\`（本轮新建）

| 脚本 | 承诺 |
| --- | --- |
| `启动后端.bat` | JDK 检查 → 端口检查 → jar 三级兜底 → 起 8081 → 等端口 |
| `启动后端.bat /force` | 强制重新打包（改完代码没生效时用） |
| `停止后端.bat` | 按 8081 结束进程 + 关窗口 |
| `tools\check-build.ps1` | exit 0 跳过打包 / 1 重打（**只比时间戳，不读 target 内容**，全英文） |
| `tools\bat-to-gbk.py`、`tools\check-bat.py` | 同上，两份工程各一份 |

---

## 5. 后端有什么 / 还缺什么

### ✅ 缺口 1：认证代码已补完（2026-10-30）

`source` 下现在共 **17 个 Java 文件**：

```
com.fenglin.springboottest
├─ SpringBootTestApplication.java
├─ UserController.java              ← 原有 Thymeleaf 教学示例，勿删（/user/test 仍可用）
├─ common\
│  ├─ R.java                        ← 统一返回体 {code,msg,data}
│  └─ GlobalExceptionHandler.java   ← 异常统一转 JSON
├─ config\
│  ├─ WebConfig.java                ← 注册拦截器 + CORS
│  └─ MybatisPlusConfig.java        ← 分页插件（必须独立！）
├─ controller\
│  ├─ AuthController.java           ← 登录/注册/退出/资料
│  └─ SysUserController.java        ← 列表 + 增删改
├─ dto\ LoginDTO / RegisterDTO / UpdateNicknameDTO / UpdatePasswordDTO
├─ entity\SysUser.java
├─ interceptor\TokenInterceptor.java
├─ mapper\SysUserMapper.java
├─ service\AuthService.java
└─ util\Md5Util.java
```

`pom.xml` 已加 `mybatis-plus-spring-boot3-starter` + `mybatis-plus-jsqlparser` + `mysql-connector-j`。
`application-dev.properties` 已加数据源 + MyBatis-Plus + 令牌有效期配置。

### ✅ 缺口 2：用户增删改已补完（2026-10-30）

后端 4 个接口 + 前端 `UsersView.vue` 操作列，**23 项验收全通过**。

**验收：`bash tools/test-crud.sh` → 通过 23 项，失败 0 项。**

接口全表（`code===200` 才算成功；**令牌失效返回 HTTP 200 + `code:401`**）：

| 接口 | 说明 | 权限约束 |
| --- | --- | --- |
| `GET /api/auth/hello` | 连通性测试 | 免登录 |
| `GET /api/auth/check?username=` | 用户名是否已占用，`data=true` = 已占用 | 免登录 |
| `POST /api/auth/login` | 登录，返回体含 `token`（**不是** JWT，是 UUID） | 免登录 |
| `POST /api/auth/register` | 注册 | 免登录 |
| `GET /api/auth/profile` | 当前用户 | 需令牌 |
| `POST /api/auth/logout` | 退出 | 需令牌 |
| `GET /api/user/page` | 分页列表，`data` 是 IPage 形状 | 需令牌 |
| `PUT /api/user/{id}/nickname` | 改昵称，body `{nickname}` | **只能改自己**，越权 → 403 |
| `PUT /api/user/{id}/password` | 改密码，body `{oldPassword,newPassword}` | **只能改自己**；成功后清 token 强制下线 |
| `PUT /api/user/{id}/status?status=` | `1` 启用 / `0` 禁用 | 不能禁用自己；禁用时清 token |
| `DELETE /api/user/{id}` | 逻辑删除 | 不能删除自己；删后搜不到、不能登录 |

**安全约束（实测过，别改坏）：**
- 越权改别人 → `code:403`「没有权限修改其他用户的信息」
- 禁自己 / 删自己 → 被拦
- 改密码后旧令牌立刻失效（`code:401`），必须重新登录
- 禁用后不能登录（提示「已被禁用」）
- 未登录调增删改 → 全部 `code:401`

**密码算法（改了就登不上）**：`md5( md5(明文) + "bikini_bottom_spongebob" )`，
见 `util/Md5Util.java`。`md5(md5("123456")+盐) = 54a66656018f3b1f43e2eef4bd608053`，与 sql 脚本一致。

### 中

- Token 是 UUID 不是 JWT（无自解析、无刷新）
- 没有 Pinia（前端状态靠 localStorage + 组件内 ref，够用但别搞复杂）
- **`/api/home/*` 三个接口还没实现**（用户明确要求先保留、先不做后端）：
  `GET /api/home/overview`、`GET /api/home/notices`、`GET /api/home/search?keyword=`
  前端已按约定路径写好，失败降级到 `src/api/home.js` 里的示例数据，**实现后自动切换、前端不用改**。
  响应结构约定（照这个写就能接通）：
  ```
  overview → { residents, krabby, online, waterTemp, weather }
  notices  → { list: [{ id, icon, text }] }
  search   → { list: [{ title, icon, desc, to, built }] }
  ```

### 低

- 没有单元测试
- 没有接口文档（springdoc）
- 过期 token 只在被访问时清，没有定时任务
- 没有生产部署方案（SpringBoot 托管 `dist`）
- **前端只有 `home` 和 `users` 是真页面**：`/menu`、`/orders`、`/report`、`/settings`
  都是 `built: false` 占位，点击只弹「建设中」toast（不跳转、不 404）。用户明确说其他页面先不做。

---

## 6. 前端文件地图（白屏排查专用）

`App.vue` 依赖下面这些文件，**少任何一个整个页面白屏**。
本轮就是因为缺了后 6 个才白屏的，排查时直接对着这张表 `ls`：

| 文件 | 作用 | 谁在用 |
| --- | --- | --- |
| `src/main.js` | 挂载 + 注册路由 + **引入 global.css / home.css** | — |
| `src/App.vue` | 布局外壳 + `<router-view>` | — |
| `src/router/index.js` | 路由 + 登录守卫 | — |
| `src/api/request.js` | axios 封装，**401 在成功分支判断** | 所有 api |
| `src/api/user.js` | 登录/分页/**增删改 4 个方法** | UsersView |
| `src/api/home.js` | 首页数据，失败降级 Mock（带 `_mock`） | HomeView / AppTopBar |
| `src/views/LoginView.vue` | 登录页 | 路由 `/login` |
| `src/views/RegisterView.vue` | 注册页 | 路由 `/register` |
| `src/views/HomeView.vue` | **首页（2026-10-30 重做）**：欢迎横幅 + 概览 + 快捷入口 + 公告 + 居民 | 路由 `/home` |
| `src/views/UsersView.vue` | 用户管理，**带操作列和 3 个弹窗** | 路由 `/users` |
| `src/components/ToastHost.vue` | 全局提示渲染 | App.vue ⚠️ |
| `src/components/AppTopBar.vue` | **顶栏：菜单按钮 + 品牌 + 顶部导航 + 搜索栏 + 用户菜单** | HomeView ⚠️ |
| `src/components/AppSideBar.vue` | **左侧导航（≤900px 变抽屉，靠顶栏菜单按钮打开）** | HomeView ⚠️ |
| `src/config/nav.js` | `NAV_ITEMS`/`QUICK_ACTIONS`/`SEARCH_HINTS` | TopBar/SideBar/home.js ⚠️ |
| `src/utils/toast.js` | `toast()` / `toasts` / `closeToast()` | ToastHost + 各视图 ⚠️ |
| `src/styles/home.css` | **首页皮肤层**：把登录页物料放大成整页布局 | main.js |
| `src/components/OceanBg.vue` | 登录/注册页的海底背景 | Login/Register/Users |
| `src/components/SpongeBob.vue` | 海绵宝宝 SVG（**自带 -92px 上边距**，复用时必须重置） | Login/Home |
| `.env` | `VITE_PORT` / `VITE_BACKEND_URL` 等 | vite.config.js ⚠️ |

⚠️ 标了叹号的是本轮新补的。**改 `App.vue` 引用前先 `ls` 确认文件真的在。**

---

## 7. 需要更多细节

→ 同目录 **`AI-CONTEXT.md`**：完整目录地图、接口约定、全部已知坑、历次会话记录、机器重置复原步骤。
→ 本文档只写"现在是什么状态 + 怎么最快跑起来"，不写历史。

---

## 8. 每次会话结束前该做的

如果这次动了代码或脚本：

1. `python tools/bat-to-gbk.py && python tools/check-bat.py`（两个工程都跑）
2. **动过后端代码 → 重打 jar 并刷新缓存**，否则下次开机用的还是旧 jar：
   ```bash
   cd /d/workSpace/springBootTest && ./mvnw.cmd -q clean package -DskipTests
   cp target/springBootTest-0.0.1-SNAPSHOT.jar "$USERPROFILE/.bikini-cache/"
   ```
3. **跑过验收脚本 → 清测试数据**，`sys_user` 必须只剩 3 个内置账号
4. 更新本文档 **第 0 节的"最后验证时间"和状态表**
5. 重要变动追加到 `AI-CONTEXT.md` 第 7 节"历次会话"
