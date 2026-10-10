@echo off
chcp 936>nul
setlocal
cd /d "%~dp0"
title 一键启动 (后端 + 前端)

rem 本脚本自身全部使用相对路径(%~dp0)。
rem 唯一例外：后端在另一个盘符(D 盘)，无法用相对路径，写在这一行，可直接修改。
if not defined BACKEND_DIR set "BACKEND_DIR=D:\workSpace\springBootTest"

echo [1/2] 启动后端...
if exist "%BACKEND_DIR%\启动后端.bat" (
    call "%BACKEND_DIR%\启动后端.bat" /nopause
    if errorlevel 1 (
        echo [错误] 后端启动失败，前端仍会继续启动，但登录注册会失败。
    )
) else (
    echo [警告] 没找到后端脚本：%BACKEND_DIR%\启动后端.bat
    echo        请修改本文件顶部的 BACKEND_DIR。
)

echo [2/2] 启动前端 (相对路径：%~dp0启动前端.bat)...
call "%~dp0启动前端.bat" /nopause

echo.
echo 全部启动完成。
echo     前端： http://localhost:5173
echo     后端： http://localhost:8081/api/auth/hello
echo     账号： spongebob / 123456
echo.
pause
