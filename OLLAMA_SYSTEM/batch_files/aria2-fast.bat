@echo off
REM Aria2 Speed-Up Protocol Wrapper
REM Automatically uses optimized configuration regardless of workspace

REM Get APPDATA path
set "ARIA2_CONF=%APPDATA%\aria2\aria2.conf"

REM Check if config exists, if not use default location
if not exist "%ARIA2_CONF%" (
    set "ARIA2_CONF=E:\AI_Tools\Central_Repository\aria2.conf"
)

REM Run aria2c with speed-up configuration
aria2c --conf-path="%ARIA2_CONF%" %*

