@echo off
setlocal enabledelayedexpansion
REM Move to project root
cd /d "%~dp0.." || exit /b 1

echo === Splendor Test Suite ===
echo.

set "COVERAGE="
set "VERBOSE="
set "CATEGORY="
set "SPECIFIC_CLASS="
set "EXCLUDE_PACKAGE="
set "INCLUDE_NETWORK="

:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="--coverage" set "COVERAGE=true" & shift & goto parse_args
if /i "%~1"=="--verbose" set "VERBOSE=--details verbose" & shift & goto parse_args
if /i "%~1"=="--category" (
    if "%~2"=="" goto missing_value
    set "CATEGORY=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--class" (
    if "%~2"=="" goto missing_value
    set "SPECIFIC_CLASS=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--exclude-package" (
    if "%~2"=="" goto missing_value
    set "EXCLUDE_PACKAGE=!EXCLUDE_PACKAGE! "%~2""
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--include-network" set "INCLUDE_NETWORK=true" & shift & goto parse_args
echo Unknown parameter passed: %~1
exit /b 1
:missing_value
echo Missing value for %~1
exit /b 2
:args_done

REM Compile main sources first
echo 1. Compiling main sources...
if not exist classes mkdir classes
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
    echo ERROR: Main source compilation failed!
    exit /b 1
)
echo    Main sources compiled OK.

REM Copy resources
if exist src\resources (
    xcopy /s /y /q src\resources\* classes\ >nul 2>&1
)

REM Compile test sources
echo 2. Compiling test sources...
if not exist test-classes mkdir test-classes

REM Find all test Java files
set "TEST_FILES="
for /r test %%f in (*.java) do (
    set "FILE_PATH=%%f"
    if defined INCLUDE_NETWORK (
        set "TEST_FILES=!TEST_FILES! "%%f""
    ) else (
        set "WITHOUT_NETWORK=!FILE_PATH:\test\com\splendor\network\=!"
        if /I "!WITHOUT_NETWORK!"=="!FILE_PATH!" (
            set "TEST_FILES=!TEST_FILES! "%%f""
        )
    )
)

if not defined INCLUDE_NETWORK (
    echo    Network tests excluded from compilation. Use --include-network to include them.
)

if not defined TEST_FILES (
    echo    No test files found in test/
    exit /b 1
)

javac --release 17 -encoding UTF-8 -d test-classes ^
  -cp "classes;lib/junit-platform-console-standalone-1.10.2.jar" ^
  -sourcepath test ^
  !TEST_FILES!

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Test compilation failed!
    exit /b 1
)
echo    Test sources compiled OK.

REM Run tests
echo 3. Running tests...
echo.

set "JUNIT_CMD=java -jar lib/junit-platform-console-standalone-1.10.2.jar execute --class-path "test-classes;classes" --fail-if-no-tests"

if defined VERBOSE (
    set "JUNIT_CMD=!JUNIT_CMD! !VERBOSE!"
)

if defined SPECIFIC_CLASS (
    set "JUNIT_CMD=!JUNIT_CMD! --select-class "!SPECIFIC_CLASS!""
) else if defined CATEGORY (
    set "JUNIT_CMD=!JUNIT_CMD! --select-package "!CATEGORY!""
) else (
    set "JUNIT_CMD=!JUNIT_CMD! --scan-class-path test-classes"
)

if defined EXCLUDE_PACKAGE (
    for %%p in (!EXCLUDE_PACKAGE!) do (
        set "JUNIT_CMD=!JUNIT_CMD! --exclude-package "%%~p""
    )
)

REM Network integration tests are opt-in to keep local and CI-like runs deterministic.
if not defined INCLUDE_NETWORK (
    set "JUNIT_CMD=!JUNIT_CMD! --exclude-package com.splendor.network"
)

if defined COVERAGE (
    echo [Note: Coverage requires JaCoCo agent which might not be configured. Proceeding with standard run.]
)

!JUNIT_CMD!
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: One or more tests failed.
    exit /b %ERRORLEVEL%
)

echo.
echo === Test run complete ===
