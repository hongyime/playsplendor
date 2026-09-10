@echo off
setlocal DisableDelayedExpansion
cd /d "%~dp0" || exit /b 1
python scripts\build_site.py %*
exit /b %errorlevel%
