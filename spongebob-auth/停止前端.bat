@echo off
chcp 936>nul
setlocal enabledelayedexpansion
cd /d "%~dp0"
title 停止前端服务 (5173)

echo 正在停止端口 5173 上的前端服务...
set FOUND=0
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":5173" ^| findstr LISTENING') do (
    echo    结束进程 PID=%%p
    taskkill /F /PID %%p >nul 2>&1
    set FOUND=1
)
if "!FOUND!"=="0" (
    echo 端口 5173 上没有运行中的服务，无需停止。
) else (
    echo 前端已停止。
)
echo.
echo 提示：Vite 有时会占用 5174，若打不开页面可一并结束 5174 端口进程。
echo.
if /i not "%1"=="/nopause" pause
