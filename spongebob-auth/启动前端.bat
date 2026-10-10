@echo off
chcp 936>nul
setlocal enabledelayedexpansion
cd /d "%~dp0"
title 比奇堡前端启动器 (Vue3 : 5173)

echo ============================================
echo   比奇堡前端启动器   Vue3 + Vite : 5173
echo ============================================
echo.

echo [1/3] 检查 Node 环境...
node -v 2>nul
if errorlevel 1 (
    echo [错误] 没有找到 node，请先安装 Node.js 18 或以上版本。
    goto :fail
)

echo [2/3] 安装依赖(每次开机 node_modules 会被清空)...
if exist "%~dp0node_modules" (
    echo    node_modules 已存在，跳过安装。
    goto :dev
)
if exist "%~dp0package-lock.json" (
    echo    用 npm ci 快速安装(依据 package-lock.json，比 install 快)...
    call npm.cmd ci --no-audit --no-fund
    if not errorlevel 1 goto :dev
    echo    npm ci 未成功，改用 npm install...
)
echo    用 npm install 安装...
call npm.cmd install --no-audit --no-fund
if errorlevel 1 (
    echo [错误] 依赖安装失败，请检查网络。
    goto :fail
)

:dev
echo [3/3] 启动开发服务器...
start "bikini-frontend-5173" cmd /k "npm.cmd run dev"
echo.
echo 启动成功！浏览器打开：
echo     登录页： http://localhost:5173/login
echo     注册页： http://localhost:5173/register
echo.
echo 提示：登录/注册需要后端(8081)同时运行，请先运行后端目录里的 启动后端.bat
echo.
if /i not "%1"=="/nopause" pause
exit /b 0

:fail
echo.
if /i not "%1"=="/nopause" pause
exit /b 1
