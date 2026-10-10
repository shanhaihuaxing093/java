@echo off
chcp 936>nul
setlocal
cd /d "%~dp0"
title Ò»¼üÍ£Ö¹ (ºó¶Ë + Ç°¶Ë)

if not defined BACKEND_DIR set "BACKEND_DIR=D:\workSpace\springBootTest"

echo [1/2] Í£Ö¹Ç°¶Ë...
call "%~dp0Í£Ö¹Ç°¶Ë.bat" /nopause

echo [2/2] Í£Ö¹ºó¶Ë...
if exist "%BACKEND_DIR%\Í£Ö¹ºó¶Ë.bat" (
    call "%BACKEND_DIR%\Í£Ö¹ºó¶Ë.bat" /nopause
) else (
    echo [¾¯¸æ] Ã»ÕÒµ½ºó¶Ë½Å±¾£º%BACKEND_DIR%\Í£Ö¹ºó¶Ë.bat
)

echo È«²¿ÒÑÍ£Ö¹¡£
pause
