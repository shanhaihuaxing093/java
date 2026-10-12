@echo off
chcp 936>nul
setlocal enabledelayedexpansion
set "APPDIR=%~dp0"
if "%APPDIR:~-1%"=="\" set "APPDIR=%APPDIR:~0,-1%"
cd /d "%APPDIR%"
title 停止比奇堡前端 (Vite)

rem Vite 端口被占用时会自动顺延，所以 5173/5174/5175 一起清

set "FOUND=0"
echo ============================================
echo   停止比奇堡前端   端口 5173 / 5174 / 5175
echo ============================================
echo.

for %%P in (5173 5174 5175) do (
    for /f "tokens=5" %%p in ('netstat -ano ^| findstr /C:":%%P" ^| findstr LISTENING') do (
        echo     [%%P] 结束进程 PID=%%p
        taskkill /F /PID %%p >nul 2>&1
        set "FOUND=1"
    )
)
if "!FOUND!"=="0" (
    echo     没有发现运行中的前端服务，无需停止。
) else (
    echo     前端已停止。
)

rem 服务虽然停了，挂日志的 cmd 窗口可能还开着，顺手关掉
taskkill /F /FI "WINDOWTITLE eq bikini-frontend-*" >nul 2>&1

echo.
if /i not "%1"=="/nopause" pause
exit /b 0
