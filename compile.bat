@echo off
setlocal DisableDelayedExpansion
cd /d "%~dp0" || exit /b 1
echo Building Splendor Java Project...

if not exist classes mkdir classes

echo Compiling Java sources...
javac --release 17 -encoding UTF-8 -d classes -sourcepath src ^
src/com/splendor/*.java ^
src/com/splendor/config/*.java ^
src/com/splendor/controller/*.java ^
src/com/splendor/data/*.java ^
src/com/splendor/exception/*.java ^
src/com/splendor/model/*.java ^
src/com/splendor/model/validator/*.java ^
src/com/splendor/network/*.java ^
src/com/splendor/util/*.java ^
src/com/splendor/view/*.java

if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    exit /b %ERRORLEVEL%
)

echo Build successful!
