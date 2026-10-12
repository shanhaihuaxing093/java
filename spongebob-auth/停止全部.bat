@echo off
chcp 936>nul
setlocal enabledelayedexpansion
set "APPDIR=%~dp0"
if "%APPDIR:~-1%"=="\" set "APPDIR=%APPDIR:~0,-1%"
cd /d "%APPDIR%"
title 比奇堡一键停止 (前端 + 后端)

rem ============================================================
rem  比奇堡一键停止：停掉前端 5173 和后端 8081
rem  MySQL 服务不在这里停（它跟着系统走，停了下回还得手动起）
rem ============================================================

set "BACKEND_DIR="

echo ============================================
echo   比奇堡一键停止
echo ============================================
echo.

echo [1/2] 停止前端...
call "%APPDIR%\停止前端.bat" /nopause
echo.

echo [2/2] 停止后端（8081）...
if exist "%APPDIR%\backend\pom.xml" set "BACKEND_DIR=%APPDIR%\backend"
if not defined BACKEND_DIR if exist "D:\workSpace\springBootTest\pom.xml" set "BACKEND_DIR=D:\workSpace\springBootTest"
if not defined BACKEND_DIR if defined BOB_BACKEND_DIR if exist "%BOB_BACKEND_DIR%\pom.xml" set "BACKEND_DIR=%BOB_BACKEND_DIR%"

if defined BACKEND_DIR (
    if exist "!BACKEND_DIR!\停止后端.bat" (
        call "!BACKEND_DIR!\停止后端.bat" /nopause
    ) else (
        echo     后端目录里没有 停止后端.bat，改为按端口结束。
        call :killPort 8081
    )
) else (
    echo     没找到后端目录，改为按端口结束。
    call :killPort 8081
)

echo.
echo ============================================
echo   全部已停止
echo ============================================
echo.
if /i not "%1"=="/nopause" pause
exit /b 0

rem ==================== 子过程 ====================

:killPort
rem %1=端口
setlocal enabledelayedexpansion
set "F=0"
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /C:":%1" ^| findstr LISTENING') do (
    echo     结束端口 %1 上的进程 PID=%%p
    taskkill /F /PID %%p >nul 2>&1
    set "F=1"
)
if "!F!"=="0" echo     端口 %1 上没有运行中的服务。
endlocal & exit /b 0
