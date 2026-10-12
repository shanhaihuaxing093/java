@echo off
chcp 936>nul
setlocal enabledelayedexpansion
set "APPDIR=%~dp0"
if "%APPDIR:~-1%"=="\" set "APPDIR=%APPDIR:~0,-1%"
cd /d "%APPDIR%"
title 比奇堡前端启动器 (Vue3 + Vite)

rem ============================================================
rem  比奇堡前端一键启动
rem  · 全部路径都从脚本自身所在目录推导，可整个文件夹搬走
rem  · 不依赖 node_modules：每次开机它会被清空，脚本会自动重装
rem  · 端口从 .env 的 VITE_PORT 读，读不到就用 5173
rem  · 用法：双击，或  启动前端.bat /nopause（被别的脚本调用时不暂停）
rem ============================================================

set "PORT=5173"
if exist "%APPDIR%\.env" (
    for /f "usebackq tokens=1,* delims==" %%a in ("%APPDIR%\.env") do (
        if /i "%%a"=="VITE_PORT" set "PORT=%%b"
    )
)
for /f "tokens=* delims= " %%p in ("%PORT%") do set "PORT=%%p"

echo ============================================
echo   比奇堡前端启动器   Vue3 + Vite
echo   端口 %PORT%    目录 %APPDIR%
echo ============================================
echo.

echo [1/4] 检查 Node 环境...
node -v >nul 2>&1
if errorlevel 1 (
    echo     [错误] 没有找到 node，请先安装 Node.js 18 或以上版本。
    goto :fail
)
node -v
echo.

echo [2/4] 检查端口 %PORT% ...
netstat -ano | findstr /C:":%PORT%" | findstr LISTENING >nul 2>&1
if not errorlevel 1 (
    echo     端口 %PORT% 已经在监听，前端可能已在运行。
    echo     要重启就先执行 停止前端.bat
    goto :ready
)
echo     端口空闲。
echo.

echo [3/4] 检查依赖...
if exist "%APPDIR%\node_modules\vite\package.json" (
    echo     node_modules 完整，跳过安装。
    goto :dev
)
if exist "%APPDIR%\node_modules" (
    echo     node_modules 不完整（可能被重置了一半），重装。
)
echo     每次开机 node_modules 都会被清空，正在安装（首次约 1~2 分钟）...
if exist "%APPDIR%\package-lock.json" (
    call npm.cmd ci --no-audit --no-fund
    if not errorlevel 1 goto :dev
    echo     npm ci 没成功，改用 npm install ...
)
call npm.cmd install --no-audit --no-fund
if errorlevel 1 (
    echo     [错误] 依赖安装失败，检查网络或手动执行 npm install 看具体报错。
    goto :fail
)
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

:waitPort
rem %1=端口  %2=最多等几秒  %3=名称
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
    echo             另外 Vite 端口被占用时会自动顺延到 5174，可以顺手看看。
    endlocal & exit /b 1
)
timeout /t 1 /nobreak >nul 2>&1
if errorlevel 1 ping -n 2 127.0.0.1 >nul 2>&1
goto :wp_loop
