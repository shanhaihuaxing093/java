@echo off
chcp 936>nul
setlocal enabledelayedexpansion
set "APPDIR=%~dp0"
if "%APPDIR:~-1%"=="\" set "APPDIR=%APPDIR:~0,-1%"
cd /d "%APPDIR%"
title 比奇堡一键启动 (MySQL + 后端 8081 + 前端 5173)

rem ============================================================
rem  比奇堡一键启动：开机后只需要双击这一个
rem
rem  依次做五件事：
rem    1. 定位后端工程（纯相对路径优先，见 :findBackend）
rem    2. 确保 MySQL 服务在跑、spongebob_auth 库存在（不存在就自动建库）
rem    3. 启动后端 8081（target 被清会自动从缓存恢复 jar 或重新打包）
rem    4. 启动前端 5173（node_modules 被清会自动从缓存恢复或联网安装）
rem    5. 自检端口 + 开浏览器
rem
rem  脚本内部路径全部相对脚本自身定位，整个文件夹可以搬走。
rem  唯一无法相对的是「后端在另一个盘符」，按这个顺序找：
rem    1 本项目内的 backend 子目录（推荐，纯相对路径）
rem    2 环境变量 BOB_BACKEND_DIR
rem    3 D:\workSpace\springBootTest（当前实际位置）
rem    4 扫描常见工作区里「有 pom.xml 且有 启动后端.bat」的目录
rem  想固定下来就设环境变量 BOB_BACKEND_DIR，或把后端放进 backend 子目录。
rem ============================================================

set "BACKEND_DIR="
set "MYSQL="

echo ============================================
echo   比奇堡一键启动
echo   MySQL + SpringBoot(8081) + Vue3(5173)
echo   项目目录 %APPDIR%
echo ============================================
echo.

echo [1/5] 定位后端工程...
call :findBackend
if defined BACKEND_DIR (
    echo     找到：!BACKEND_DIR!
) else (
    echo     [警告] 没找到后端工程，前端照常启动，但登录/注册会失败。
    echo             若后端也没了，见 AI-BOOT.md 的「复原」一节。
)
echo.

echo [2/5] 检查 MySQL 与数据库...
call :ensureMysql
echo.

if defined BACKEND_DIR (
    echo [3/5] 启动后端（8081）...
    call "!BACKEND_DIR!\启动后端.bat" /nopause
    if errorlevel 1 echo     [警告] 后端启动失败，前端仍会起，但登录会报网络异常。
) else (
    echo [3/5] 跳过后端。
)
echo.

echo [4/5] 启动前端（5173）...
call "%APPDIR%\启动前端.bat" /nopause
if errorlevel 1 echo     [警告] 前端启动失败，看上面的报错。
echo.

echo [5/5] 自检...
call :waitPort 8081 20 后端
call :waitPort 5173 30 前端

echo.
echo ============================================
echo   启动流程结束
echo     前端   http://localhost:5173/login
echo     后端   http://localhost:8081/api/auth/hello
echo     账号   spongebob / 123456
echo            patrick、squidward 密码相同
echo ============================================
echo.

call :openBrowser "http://localhost:5173/login"

echo 停止服务：双击 停止全部.bat
echo.
if /i not "%1"=="/nopause" pause
exit /b 0

rem ==================== 子过程 ====================

:findBackend
rem 结果写进 BACKEND_DIR，找不到就保持为空
set "BACKEND_DIR="
if exist "%APPDIR%\backend\pom.xml" (
    set "BACKEND_DIR=%APPDIR%\backend"
    exit /b 0
)
if defined BOB_BACKEND_DIR (
    if exist "%BOB_BACKEND_DIR%\pom.xml" (
        set "BACKEND_DIR=%BOB_BACKEND_DIR%"
        exit /b 0
    )
)
if exist "D:\workSpace\springBootTest\pom.xml" (
    set "BACKEND_DIR=D:\workSpace\springBootTest"
    exit /b 0
)
for %%R in ("D:\workSpace" "D:" "%USERPROFILE%\Desktop" "%USERPROFILE%\IdeaProjects") do (
    if not defined BACKEND_DIR (
        if exist "%%~R\" (
            for /d %%d in ("%%~R\*") do (
                if not defined BACKEND_DIR (
                    if exist "%%~d\pom.xml" (
                        if exist "%%~d\启动后端.bat" set "BACKEND_DIR=%%~d"
                    )
                )
            )
        )
    )
)
exit /b 0

:findMysql
set "MYSQL="
if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" (
    set "MYSQL=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
    exit /b 0
)
for /d %%d in ("C:\Program Files\MySQL\*") do (
    if not defined MYSQL (
        if exist "%%~d\bin\mysql.exe" set "MYSQL=%%~d\bin\mysql.exe"
    )
)
if defined MYSQL exit /b 0
where mysql >nul 2>&1
if not errorlevel 1 set "MYSQL=mysql.exe"
exit /b 0

:ensureMysql
netstat -ano | findstr /C:":3306" | findstr LISTENING >nul 2>&1
if errorlevel 1 (
    echo     MySQL 没在运行，尝试启动服务（可能需要管理员权限）...
    net start MySQL80 >nul 2>&1
    if errorlevel 1 net start MySQL >nul 2>&1
    if errorlevel 1 net start mysql80 >nul 2>&1
    call :waitPort 3306 20 MySQL
) else (
    echo     MySQL 已在运行（3306）。
)
call :findMysql
if not defined MYSQL (
    echo     [警告] 没找到 mysql.exe，跳过数据库检查。
    exit /b 0
)
"%MYSQL%" -uroot -p123456 --connect-timeout=5 -e "use spongebob_auth; select 1;" >nul 2>&1
if not errorlevel 1 (
    echo     数据库 spongebob_auth 正常。
    exit /b 0
)
echo     数据库不存在或连不上，正在执行 sql\spongebob_auth.sql ...
"%MYSQL%" -uroot -p123456 --default-character-set=utf8mb4 --connect-timeout=5 < "%APPDIR%\sql\spongebob_auth.sql" >nul 2>&1
if errorlevel 1 (
    echo     [警告] 建库失败。确认 MySQL 已启动、root 密码是 123456。
    echo             手动执行：mysql -uroot -p123456 ^< sql\spongebob_auth.sql
    exit /b 0
)
echo     建库完成，三个内置账号已就位。
exit /b 0

:waitPort
rem 参数1=端口  参数2=最多等几秒  参数3=名称
setlocal enabledelayedexpansion
set /a _n=0
:wp_loop
set /a _n+=1
netstat -ano | findstr /C:":%1" | findstr LISTENING >nul 2>&1
if not errorlevel 1 (
    echo     [OK] %3 就绪（端口 %1，约 !_n! 秒）
    endlocal & exit /b 0
)
if !_n! GEQ %2 (
    echo     [!!] %3 未就绪：等了 %2 秒，端口 %1 还没监听
    endlocal & exit /b 1
)
timeout /t 1 /nobreak >nul 2>&1
if errorlevel 1 ping -n 2 127.0.0.1 >nul 2>&1
goto :wp_loop

:openBrowser
rem 参数1=URL；装了浏览器才打开，没装就只打印地址
set "BROWSER="
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" set "BROWSER=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
if not defined BROWSER if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" set "BROWSER=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if not defined BROWSER if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "BROWSER=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined BROWSER if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "BROWSER=%LocalAppData%\Google\Chrome\Application\chrome.exe"
if defined BROWSER (
    start "" "%BROWSER%" "%~1"
    echo 已用浏览器打开登录页。
) else (
    echo 本机没检测到浏览器，自己打开：%~1
)
exit /b 0
