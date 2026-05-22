@echo off

:: init start
:: ========================================

set __INIT_START__=%time%

:: debug config
set __DBG_INFO__=0

:: cmd config
:: ========================================

:: change lang to utf8
set LANG=en_US.utf8

:: change chcp to utf8
chcp 65001
cls

:: find root dir
if not defined MY_ROOT (
  for /f "delims=" %%i in ("%~dp0\..") do (
    set "MY_ROOT=%%~fi"
  )
)
:: remove trailing '\' from %MY_ROOT%
if "%MY_ROOT:~-1%" == "\" set "MY_ROOT=%MY_ROOT:~0,-1%"

set "MY_CONFIGS=%MY_ROOT%\win"
set "MY_BIN=%USERPROFILE%\bin"

:: add aliases
:: ========================================

call "%MY_CONFIGS%\cmds\aliases.cmd"

:: add %USERPROFILE%\bin\ to environment path
:: ========================================

if exist "%MY_BIN%" (
  set "PATH=%PATH%;%MY_BIN%"
)

:: set starship config path before clink
:: ========================================

set "STARSHIP_CONFIG=%MY_CONFIGS%\starship.toml"

:: set fzf option before clink
:: ========================================

set "FZF_COMPLETE_OPTS=-e"

:: set pi nerdfonts
:: ========================================

set "PI_NERD_FONTS=1"

:: inject clink
:: ========================================

:: pick right version of clink
if "%PROCESSOR_ARCHITECTURE%"=="x86" (
  set CLINK_ARCH=x86
) else (
  set CLINK_ARCH=x64
)

"%MY_BIN%\clink\clink_%CLINK_ARCH%.exe" inject --quiet --profile "%MY_CONFIGS%\clink_profile" --scripts "%MY_CONFIGS%\clink_scripts"

:: init end
:: ========================================

set __INIT_END__=%time%

:: show debug info
if %__DBG_INFO__% gtr 0 (
  "%MY_CONFIGS%\cmds\timer.cmd" "%__INIT_START__%" "%__INIT_END__%"
  echo ----------------------------------------
  echo PROCESSOR_ARCHITECTURE = %PROCESSOR_ARCHITECTURE%
  echo LANG = %LANG%
  echo MY_ROOT = %MY_ROOT%
  echo MY_CONFIGS = %MY_CONFIGS%
)

exit /b
