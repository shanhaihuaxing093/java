# AI-BOOT.md —— 开机速读卡（写给 AI 看的，读完直接动手）

> **这个文件是写给 AI（也就是我）看的。开机第一件事读它，读完直接动手。**
> 不要重新探测环境，不要重新设计架构，不要 clean 重建，不要反复问用户。
> 这里写的都是已经在本机验证过的事实；冲突时以 `AI-CONTEXT.md` 为准（并回头同步这里）。

---

## 0. 一句话现状（2026-10-28）

**前端（登录/注册/首页/用户列表）已完成且能跑；后端被机器重置回滚，认证 Java 代码全没了，
一键脚本能把服务拉起来，但登录接口目前是 404 —— 这属预期，不是脚本坏了。**

当前最大的待办：**复原后端认证代码**（接口约定见前端 `AI-CONTEXT.md` 第 3 节；清单见后端 `AI-BOOT.md`）。

## 1. 三条命令，覆盖 95% 的情况（都在前端项目根目录双击）

| 想干什么 | 做什么 |
| --- | --- |
| 起服务 | **`启动全部.bat`** ← 开机后通常只需要这一个（MySQL + 后端 8081 + 前端 5173 + 自检 + 开浏览器） |
| 停服务 | **`停止全部.bat`** |
| 全乱了 / 文件都没了 | **`环境复原.bat`** |

「跑通了」的判定：`http://localhost:5173` 打开不白屏；
后端代码复原前**登录不进去是预期**，看首页用 `http://localhost:5173/home-preview.html`。
后端复原后：`spongebob / 123456` 能登进首页，`/users` 能看到三个居民。

## 2. 固定事实（已验证，不要再测一遍）

| 项目 | 值 |
| --- | --- |
| 前端（原始） | `D:\workSpace\java\spongebob-auth` — Vue 3.5 + Vite 5.4，**无 UI 库** |
| 前端（工作区副本） | `C:\Users\Administrator\WorkBuddy\<会话目录>\spongebob-auth`，与 D 盘已同步 |
| 后端 | `D:\workSpace\springBootTest` — SpringBoot 3.4.5（**认证代码待复原，见第 0 节**） |
| 端口 | 前端 **5173**、后端 **8081**、MySQL **3306** |
| 测试账号 | `spongebob` / `patrick` / `squidward`，密码都是 `123456`（后端复原后有效） |
| 首页预览 | `http://localhost:5173/home-preview.html`（写假令牌绕守卫，仅本地开发用） |
| 首页预留接口 | `GET /api/home/overview`、`/api/home/notices`、`/api/home/search`（后端未实现，前端自动降级 Mock） |
| MySQL | 服务 `MySQL80`，`root / 123456`，库 `spongebob_auth`，客户端在 `C:\Program Files\MySQL\MySQL Server 8.0\bin\`（不在 PATH） |
| Node / JDK | Node v22 在 PATH；JDK 21（Zulu）在 PATH；Maven 不在 PATH |
| 每次开机被清 | 前端 `node_modules`、后端 `target`（有时整个后端工程被回滚，2026-10-28 就发生了） |
| 不会被清 | `src`、`pom.xml`、`package-lock.json`、`%USERPROFILE%\.bikini-cache`、`~\.m2` |

### ⭐ 启动加速缓存（2026-10-28 新增，已实测）

`%USERPROFILE%\.bikini-cache\` 里存了两样东西（开机重置清不掉它）：

| 缓存文件 | 作用 | 实测 |
| --- | --- | --- |
| `spongebob-node_modules.zip` | 前端依赖压缩包，`node_modules` 被清后解压恢复 | 压缩 2.2s / 恢复 0.5s，代替 45s+ 的 npm ci |
| `springBootTest-0.0.1-SNAPSHOT.jar` | 后端成品 jar，`target` 被清后 robocopy 恢复（保留时间戳） | 秒级，代替 1~3 分钟打包 |

**启动脚本已内置**：node_modules/jar 在就直接用 → 没了先解缓存 → 缓存也没有才联网装/打包，
且装好/打包成功后会**自动更新缓存**。AI 不需要手动维护缓存，除非用户说缓存坏了。
两个工程共用这份缓存（依赖锁相同、jar 与工程绑定），D 盘和 WorkBuddy 副本谁先启动谁用/更新。

### 两个必须知道的坑

1. **本机有 HTTP 代理**（127.0.0.1:56522）→ curl localhost 前必须 `export no_proxy="localhost,127.0.0.1"`。
2. **环境变量 `SERVER__PORT=56474`** → Spring 宽松绑定会抢端口，**起后端必须显式 `--server.port=8081`**（脚本已内置）。

## 3. AI 在 Bash 里怎么验证（先自己验，别问用户）

```bash
export no_proxy="localhost,127.0.0.1"        # 必须！
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:5173/   # 前端活着=200
curl -s http://localhost:8081/user/test                         # 后端活着（认证复原后改用 /api/auth/hello）
```

⚠️ **AI 自己跑不了 .bat**（安全策略拉黑 cmd.exe），只能静态检查 + 让用户双击验证。
改任何 .bat 之后必跑：`python tools/bat-to-gbk.py`（前端/后端根目录都行，工具两边都有），
再跑 `python tools/check-bat.py` 静态自检。bat 硬约束：**GBK + CRLF + 无 BOM；路径全从脚本自身推导；
不读 node_modules/target 内容；rem 注释里别写百分号对**。

## 4. 脚本清单

| 脚本 | 位置 | 承诺 |
| --- | --- | --- |
| `启动全部.bat` | 前端根 | 定位后端 → 确保 MySQL/库 → 起后端 → 起前端 → 自检 → 开浏览器 |
| `停止全部.bat` | 前端根 | 停前端 5173/5174/5175 + 后端 8081（MySQL 不停） |
| `启动前端.bat` | 前端根 | 依赖三级兜底（现成/缓存/联网），端口读 .env，装完自动更新缓存 |
| `停止前端.bat` | 前端根 | 清 5173 / 5174 / 5175 |
| `环境复原.bat` | 前端根 | 删 node_modules/dist/target → 重装重编译重建（有 Y/N 确认） |
| `启动后端.bat` | 后端根 | jar 三级兜底（现成/缓存/打包），支持 `/force`、`/nopause`，打包完自动存缓存 |
| `停止后端.bat` | 后端根 | 结束监听 8081 的进程 |
| `tools\check-build.ps1` | 后端 | exit 0 跳过打包 / 1 重打（比对 src 与 jar 时间戳） |
| `tools\bat-to-gbk.py` | 两边都有 | **改完任何 .bat 必跑一次**：转 GBK + CRLF（幂等） |
| `tools\check-bat.py` | 两边都有 | bat 静态自检（标签/括号/引号/编码） |
| `tools\test-api.sh` | 前端 | 28 项后端接口验收（**后端代码复原后才全过**） |

## 5. 项目还缺什么（按优先级，详细版见 AI-CONTEXT.md 第 6 节）

| 优先级 | 缺失项 |
| --- | --- |
| **高** | **后端认证代码整包丢失**（AuthController/Service/Mapper/拦截器/MyBatis 配置 + pom 依赖），登录注册全 404 |
| 中 | Token 是 UUID 非 JWT；后端只有查列表没有增删改；没有 Pinia |
| 低 | 单元测试、接口文档（springdoc）、定时清理过期 token |

## 6. 需要更多细节

→ 同目录 **`AI-CONTEXT.md`**：完整目录地图、接口约定、全部已知坑、历次会话做过什么。
→ 后端 `D:\workSpace\springBootTest\AI-BOOT.md`：后端速读卡 + 待复原文件清单。
