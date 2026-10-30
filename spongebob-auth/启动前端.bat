@echo off
chcp 936>nul
setlocal enabledelayedexpansion
set "APPDIR=%~dp0"
if "%APPDIR:~-1%"=="\" set "APPDIR=%APPDIR:~0,-1%"
cd /d "%APPDIR%"
title 比奇堡前端启动器 (Vue3 + Vite)

rem ============================================================
rem  比奇堡前端一键启动（提速版）
rem
rem  · 全部路径都从脚本自身所在目录推导，整个文件夹可搬走
rem  · 不依赖 node_modules 里的内容：每次开机它被清空
rem      1 node_modules 完整（vite 真的装好了）  直接用
rem      2 不完整就删掉，先从用户缓存解压恢复    秒级
rem      3 缓存也没有才联网 npm ci / install      1~2 分钟
rem  · 安装成功后自动更新缓存，下次开机秒级恢复
rem  · 端口从 .env 的 VITE_PORT 读，读不到用 5173
rem
rem  用法：双击，或 启动前端.bat /nopause（被别的脚本调用时不暂停）
rem ============================================================

set "PORT=5173"
if exist "%APPDIR%\.env" (
    rem 只取 VITE_PORT 那一行，跳过空行和 # 注释行
    for /f "usebackq tokens=1,* delims==" %%a in ("%APPDIR%\.env") do (
        set "_k=%%a"
        set "_v=%%b"
        if defined _k if not "!_k:~0,1!"=="#" (
            if /i "!_k!"=="VITE_PORT" set "PORT=!_v!"
        )
    )
)
rem 去掉可能残留的空格
for /f "tokens=* delims= " %%p in ("%PORT%") do set "PORT=%%p"

set "CACHEDIR=%USERPROFILE%\.bikini-cache"
set "CACHEZIP=%CACHEDIR%\spongebob-node_modules.zip"

echo ============================================
echo   比奇堡前端启动器   Vue3 + Vite
echo   端口 %PORT%    目录 %APPDIR%
echo ============================================
echo.

echo [1/4] 检查 Node 环境...
node -v >nul 2>&1
if errorlevel 1 (
    echo     [错误] 没有找到 node，请安装 Node.js 18 或以上版本。
    goto :fail
)
node -v
echo.

echo [2/4] 检查端口 %PORT% ...
netstat -ano | findstr /C:":%PORT%" | findstr LISTENING >nul 2>&1
if not errorlevel 1 (
    echo     端口 %PORT% 已在监听，前端可能已在运行。
    echo     要重启就先执行 停止前端.bat
    goto :ready
)
echo     端口空闲。
echo.

echo [3/4] 检查依赖...
rem 判断标准不是「node_modules 目录在不在」，而是「vite 真的装好了」
if exist "%APPDIR%\node_modules\vite\package.json" (
    if exist "%APPDIR%\node_modules\.bin\vite.cmd" (
        echo     node_modules 完整，跳过安装。
        goto :dev
    )
)
if exist "%APPDIR%\node_modules" (
    echo     node_modules 不完整（可能被重置了一半），删掉重来。
    rd /s /q "%APPDIR%\node_modules" >nul 2>&1
)

if exist "%CACHEZIP%" (
    echo     发现依赖缓存，正在解压恢复（通常几秒，比联网快得多）...
    tar -xf "%CACHEZIP%" -C "%APPDIR%" >nul 2>&1
    if exist "%APPDIR%\node_modules\vite\package.json" (
        if exist "%APPDIR%\node_modules\.bin\vite.cmd" (
            echo     缓存恢复成功。
            goto :dev
        )
    )
    echo     [警告] 缓存不可用，删掉后改为联网安装。
    if exist "%APPDIR%\node_modules" rd /s /q "%APPDIR%\node_modules" >nul 2>&1
)

echo     正在联网安装依赖（约 1~2 分钟，取决于网速）...
if exist "%APPDIR%\package-lock.json" (
    call npm.cmd ci --no-audit --no-fund --prefer-offline
    if not errorlevel 1 goto :installed
    echo     npm ci 没成功，改用 npm install ...
)
call npm.cmd install --no-audit --no-fund --prefer-offline
if errorlevel 1 (
    echo     [错误] 依赖安装失败。检查网络，或手动执行 npm install 看具体报错。
    echo             国内网络可以试试：npm install --registry=https://registry.npmmirror.com
    goto :fail
)

:installed
echo     安装成功，顺手更新依赖缓存（下次开机秒级恢复）...
call :updateCache
echo.

:dev
echo [4/4] 启动开发服务器...
start "bikini-frontend-%PORT%" /D "%APPDIR%" cmd /k npm.cmd run dev
call :waitPort %PORT% 40 前端
if errorlevel 1 goto :fail

:ready
echo.
echo ============================================
echo   前端已就绪
echo     登录页   http://localhost:%PORT%/login
echo     注册页   http://localhost:%PORT%/register
echo     首页     http://localhost:%PORT%/home
echo     预览入口 http://localhost:%PORT%/home-preview.html
echo     居民名单 http://localhost:%PORT%/users
echo ============================================
echo.
echo 提示：登录/注册需要后端 8081 同时跑着。想一次搞定就用 启动全部.bat
echo.
if /i not "%1"=="/nopause" pause
exit /b 0

:fail
echo.
if /i not "%1"=="/nopause" pause
exit /b 1

rem ==================== 子过程 ====================

:updateCache
rem 把刚装好的 node_modules 压进用户缓存；机器重置清掉后可秒级恢复
if not exist "%CACHEDIR%" mkdir "%CACHEDIR%" >nul 2>&1
if exist "%CACHEZIP%" del /f /q "%CACHEZIP%" >nul 2>&1
tar -a -cf "%CACHEZIP%" -C "%APPDIR%" node_modules >nul 2>&1
exit /b 0

:waitPort
rem 参数1=端口  参数2=最多等几秒  参数3=名称
setlocal enabledelayedexpansion
set /a _n=0
:wp_loop
set /a _n+=1
netstat -ano | findstr /C:":%1" | findstr LISTENING >nul 2>&1
if not errorlevel 1 (
    echo     端口 %1 已就绪（约 !_n! 秒）。
    endlocal & exit /b 0
)
if !_n! GEQ %2 (
    echo     [警告] 等了 %2 秒，端口 %1 还是没起来。
    echo             看新弹出的窗口里 Vite 的报错。
    echo             Vite 端口被占用时会自动顺延到 5174，也可以顺手看看。
    endlocal & exit /b 1
)
timeout /t 1 /nobreak >nul 2>&1
if errorlevel 1 ping -n 2 127.0.0.1 >nul 2>&1
goto :wp_loop
