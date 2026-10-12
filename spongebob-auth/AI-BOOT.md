# AI-BOOT.md —— 开机速读卡

> **这个文件是写给 AI（也就是我）看的。开机第一件事读它，读完直接动手。**
>
> 为什么需要它：**这台机器每次开机都会清掉 `node_modules` 和 `target`**。
> 「上次明明跑通了」不代表这次能跑——每次开机都得重建一遍。
> 所以：**不要重新探测环境，不要重新设计架构，不要 clean 重建，不要反复问用户。**
> 这里写的都是已经在本机验证过的事实。

---

## 0. 三条命令，覆盖 95% 的情况

| 想干什么 | 做什么（都在本项目根目录双击） |
| --- | --- |
| 起服务 | **`启动全部.bat`** ← 开机后通常只需要这一个 |
| 停服务 | **`停止全部.bat`** |
| 全乱了 / 文件都没了 | **`环境复原.bat`** |

**「跑通了」的判定标准**：浏览器打开 `http://localhost:5173/login`，
用 `spongebob / 123456` 能登进首页，`/users` 能看到三个居民。

---

## 1. AI 在 Bash 里怎么验证（先自己验，别先问用户）

```bash
export no_proxy="localhost,127.0.0.1"        # 必须！本机有代理会拦 localhost
curl -s http://localhost:8081/api/auth/hello                 # 期望 {"code":200,...}
curl -s -X POST http://localhost:8081/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"spongebob","password":"123456"}'          # 期望带 token
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:5173/   # 期望 200
bash tools/test-api.sh                        # 28 项接口验收，退出码 = 失败项数
```

> ⚠️ **AI 自己跑不了 .bat**：本机安全策略把 `cmd.exe` / `sc.exe` / `reg.exe` 拉黑了，
> Bash 和 PowerShell 都调不动 cmd。所以 `.bat` 只能让用户双击。
> 我要手工验证时用第 5 节的等价命令。

---

## 2. 固定事实（已验证，不要再测一遍）

| 项目 | 值 |
| --- | --- |
| 前端 | `C:\Users\Administrator\Desktop\spongebob-auth` — Vue 3.5 + Vite 5.4，**无 UI 库** |
| 后端 | `D:\workSpace\springBootTest` — SpringBoot 3.4.5 + MyBatis-Plus 3.5.9 + MySQL 8 |
| 端口 | 前端 **5173**、后端 **8081**、MySQL **3306** |
| 前端地址 | `http://localhost:5173/login`（`/register`、`/users`） |
| 测试账号 | `spongebob` / `patrick` / `squidward`，密码都是 `123456` |
| 密码算法 | `md5( md5(明文) + "bikini_bottom_spongebob" )`，改盐会导致内置账号全登不上 |
| MySQL | 服务 `MySQL80`，`root / 123456`，库 `spongebob_auth` |
| MySQL 客户端 | `C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe`（**不在 PATH**） |
| Node / JDK | Node v22.22.2（在 PATH）；JDK 21（`java` 在 PATH） |
| Maven | 不在 PATH。可用：工程内 `mvnw.cmd`、`~/.m2/wrapper/dists/` 里缓存的发行包、IDEA 内置。脚本会自己按顺序试 |
| 每次开机被清 | 前端 `node_modules`、后端 `target` |
| 不会被清 | `src`、`pom.xml`、`.env`、`package-lock.json`、数据库里的账号 |

### 两个必须知道的坑

1. **本机有 HTTP 代理**（`http_proxy=127.0.0.1:56522`）→ 访问 localhost 会被拦。
   任何 curl 之前先 `export no_proxy="localhost,127.0.0.1"`。
2. **环境变量里有 `SERVER__PORT=56474`** → Spring 的宽松绑定会把它当成 `server.port`，
   后端就绑到 56474 而不是 8081。**启动后端必须显式带 `--server.port=8081`**（脚本已内置）。

---

## 3. 脚本清单与它们的承诺

| 脚本 | 位置 | 承诺 |
| --- | --- | --- |
| `启动全部.bat` | 前端根 | 定位后端 → 确保 MySQL 在跑、库存在 → 起后端 → 起前端 → 自检 → 开浏览器 |
| `停止全部.bat` | 前端根 | 停前端 5173/5174/5175 + 后端 8081（MySQL 不停） |
| `启动前端.bat` | 前端根 | `node_modules` 不在就自动 `npm ci`；端口从 `.env` 的 `VITE_PORT` 读 |
| `停止前端.bat` | 前端根 | 清 5173/5174/5175 |
| `环境复原.bat` | 前端根 | 删 `node_modules`/`dist`/`target` → 重装重编译重建（有 Y/N 确认） |
| `启动后端.bat` | 后端根 | `target` 没了/源码比 jar 新就打包，否则**跳过打包**；起 8081 并等就绪 |
| `停止后端.bat` | 后端根 | 清 8081 |
| `tools/check-build.ps1` | 后端 | 判断 jar 要不要重打（exit 0 跳过 / 1 重打） |
| `tools/bat-to-gbk.py` | 两边都有 | **改完任何 .bat 都要跑一次**：转成 GBK + CRLF |
| `tools/check-bat.py` | 前端 | 静态查 .bat：标签引用、括号配平、引号成对、编码 |
| `tools/test-api.sh` | 前端 | 28 项后端接口验收 |

**脚本约定（改脚本时别破坏）**：
- 一切路径从脚本自身位置推导（`%~dp0`），项目整个文件夹搬走也能用。
- **不读 `node_modules` / `target` 里的内容**——它们随时会被清空，只判断「在不在」。
- 编码必须 **GBK + CRLF + 无 BOM**（cmd 代码页 936）。写 UTF-8 中文会变乱码。
- 所有脚本都接受 `/nopause`：被别的脚本 call 时不要停下来等人按键。

**后端工程在另一个盘符（D 盘）**，无法用相对路径。`启动全部.bat` 按这个顺序找：
① 本项目内的 `backend\` 子目录 → ② 环境变量 `BOB_BACKEND_DIR` → ③ `D:\workSpace\springBootTest`
→ ④ 在 `D:\workSpace`、`D:\`、桌面、IdeaProjects 里扫「有 pom.xml 且有 启动后端.bat」的目录。
**想让一切都变成相对路径，把后端整个搬进 `backend\` 子目录即可，脚本不用改。**

---

## 4. 出问题了，按这个顺序看

| 现象 | 先看这里 |
| --- | --- |
| 登录报「网络异常，请检查后端是否已启动」 | 后端没起。起 `启动后端.bat`；再 `curl http://localhost:8081/api/auth/hello` |
| 后端窗口闪退 / 起来又挂 | 数据库。`mysql -uroot -p123456 -e "use spongebob_auth; select 1;"`；库没了跑 `启动全部.bat`（会自动建库） |
| 后端端口不是 8081 | 少了 `--server.port=8081`（见 §2 坑 2） |
| 前端打不开，5173 没监听 | 看 Vite 窗口报错；端口被占时 Vite 会顺延到 5174 |
| 改了 Java 代码没生效 | `启动后端.bat /force`（强制 clean + 重打包） |
| 报「找不到符号 PaginationInnerInterceptor」 | 少了 `mybatis-plus-jsqlparser` 依赖（3.5.9 起分页插件被拆出去了） |
| 后端启动报循环依赖 | `MybatisPlusInterceptor` 这个 Bean 不能放在 `WebConfig` 里，必须留 `MybatisPlusConfig` |
| `.bat` 里中文变乱码 | 忘了转 GBK：`python tools/bat-to-gbk.py` |

---

## 5. 手工等价命令（AI 在 Bash 里用，或用户手动排查）

```bash
# 建库（幂等）
"/c/Program Files/MySQL/MySQL Server 8.0/bin/mysql.exe" -uroot -p123456 \
  < "/c/Users/Administrator/Desktop/spongebob-auth/sql/spongebob_auth.sql"

# 前端
cd "/c/Users/Administrator/Desktop/spongebob-auth" && npm ci && npm run dev

# 后端打包（Bash 里 mvnw.cmd 跑不起来，用缓存的 maven 发行包直接跑 Launcher）
cd /d/workSpace/springBootTest
MA="/c/Users/Administrator/.m2/wrapper/dists/apache-maven-3.9.9-bin/4nf9hui3q3djbarqar9g711ggc/apache-maven-3.9.9"
java -classpath "$MA/boot/plexus-classworlds-2.8.0.jar" \
  "-Dclassworlds.conf=$MA/bin/m2.conf" "-Dmaven.home=$MA" \
  "-Dmaven.multiModuleProjectDirectory=$(pwd -W)" \
  org.codehaus.plexus.classworlds.launcher.Launcher -B -DskipTests package

# 起后端
cd /d/workSpace/springBootTest
java -jar target/springBootTest-0.0.1-SNAPSHOT.jar --server.port=8081 &
```

---

## 6. 版本库（已 git 管理，别再从头 init）

首次提交 `5941966`，提交身份是**仓库级**占位 `fenglin <fenglin@localhost>`（没有动全局 git 配置）。

**关键：`.bat` 已在 `.gitattributes` 里标成 `binary`。**
本机 `core.autocrlf=true`，若不这么标，git 会把 GBK 的 `.bat` 当文本、把 CRLF 转成 LF 存库，
以后换机器检出的脚本会变 LF 结尾，`goto` / 多行括号块在 cmd 里就坏了。
标了 `binary` 之后 git 完全不碰这些文件，**改完脚本直接 commit 即可，不需要额外操作**。

```bash
cd "C:/Users/Administrator/Desktop/spongebob-auth"
git status --short
git add -A && git commit -m "..."     # .bat 改动照常提交
```

已忽略：`node_modules/` `dist/` `.env.local`。

> ⚠️ 仓库**只在本地磁盘、没有远端** → 磁盘被清则这份历史一起没。
> 真要抗重置，必须推到远端（GitHub / 私有仓库 / 另一块盘上的 bundle）。

---

## 7. 需要更多细节

→ 同目录 **`AI-CONTEXT.md`**：完整目录地图、接口约定、全部已知坑、历次会话做过什么。
   （本文件是它的「开机摘要」，冲突时以 AI-CONTEXT.md 为准，并回来把这里同步掉。）
