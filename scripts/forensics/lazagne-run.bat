@echo off
REM lazagne-run.bat - LaZagne portable, dumpt eigene Credentials
REM Nur fuer das aktuelle Benutzerprofil auf eigenem Geraet.

setlocal enabledelayedexpansion

if "%TOOLKIT%"=="" (
    for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        if exist "%%D:\launchers\windows\pentest-menu.bat" set TOOLKIT=%%D:
    )
)

set LAZAGNE=%TOOLKIT%\tools\windows-portable\LaZagne.exe
if not exist "%LAZAGNE%" (
    echo [-] LaZagne.exe nicht gefunden unter %LAZAGNE%
    echo     Download: https://github.com/AlessandroZ/LaZagne/releases
    echo     Nach %TOOLKIT%\tools\windows-portable\LaZagne.exe legen.
    exit /b 1
)

powershell -ExecutionPolicy Bypass -Command ". '%TOOLKIT%\scripts\lib\auth_check.ps1'; Require-Auth -Target '%COMPUTERNAME%'"
if errorlevel 1 exit /b %errorlevel%

set STAMP=%date:~-4%%date:~3,2%%date:~0,2%-%time:~0,2%%time:~3,2%%time:~6,2%
set STAMP=%STAMP: =0%
set OUTDIR=%TOOLKIT%\output\forensics\%COMPUTERNAME%-lazagne-%STAMP%
mkdir "%OUTDIR%" 2>nul

pushd "%OUTDIR%"
"%LAZAGNE%" all -oN
popd

echo [+] Output: %OUTDIR%
endlocal
