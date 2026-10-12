@echo off
chcp 936>nul
setlocal enabledelayedexpansion
set "APPDIR=%~dp0"
if "%APPDIR:~-1%"=="\" set "APPDIR=%APPDIR:~0,-1%"
cd /d "%APPDIR%"
title 比奇堡环境复原（重装依赖 + 重编译 + 重建库）

rem ============================================================
rem  环境复原：把「每次开机被清掉的东西」一次性重做一遍
rem  只删构建产物（node_modules / dist / target），不动 src 和你的代码
rem  数据库脚本可重复执行，不会清掉已有账号
rem ============================================================

set "BACKEND_DIR="

echo ============================================================
echo   比奇堡环境复原
echo ============================================================
echo.
echo 将要做：
echo   1. 删除前端 node_modules 和 dist        （构建产物）
echo   2. 删除后端 target                      （构建产物）
echo   3. 重新执行 sql\spongebob_auth.sql      （幂等，不删已有账号）
echo   4. 重装依赖 + 重新编译后端 + 启动前后端
echo.
echo 不会动：src、pom.xml、.env、数据库里的账号数据
echo.

set "Y="
set /p "Y=确定继续吗？(Y/N) "
if /i not "%Y%"=="Y" (
    echo 已取消，什么都没动。
    echo.
    if /i not "%1"=="/nopause" pause
    exit /b 0
)
echo.

if exist "%APPDIR%\backend\pom.xml" set "BACKEND_DIR=%APPDIR%\backend"
if not defined BACKEND_DIR if exist "D:\workSpace\springBootTest\pom.xml" set "BACKEND_DIR=D:\workSpace\springBootTest"
if not defined BACKEND_DIR if defined BOB_BACKEND_DIR if exist "%BOB_BACKEND_DIR%\pom.xml" set "BACKEND_DIR=%BOB_BACKEND_DIR%"

echo [1/4] 删除前端 node_modules 与 dist ...
if exist "%APPDIR%\node_modules" (
    rd /s /q "%APPDIR%\node_modules"
    if exist "%APPDIR%\node_modules" (echo     [警告] node_modules 没删干净) else (echo     node_modules 已删除)
) else (
    echo     node_modules 本来就不在。
)
if exist "%APPDIR%\dist" rd /s /q "%APPDIR%\dist"

echo [2/4] 删除后端 target ...
if defined BACKEND_DIR (
    if exist "!BACKEND_DIR!\target" (
        rd /s /q "!BACKEND_DIR!\target"
        if exist "!BACKEND_DIR!\target" (echo     [警告] target 没删干净) else (echo     target 已删除)
    ) else (
        echo     target 本来就不在。
    )
) else (
    echo     [警告] 没找到后端目录，跳过。
)

echo [3/4] 重建数据库（交给 启动全部.bat 里的检查逻辑）...
echo [4/4] 启动全部（会自动装依赖、重新打包、自检）...
echo.

call "%APPDIR%\启动全部.bat" /nopause

echo.
echo 复原流程结束。
echo.
if /i not "%1"=="/nopause" pause
exit /b 0
