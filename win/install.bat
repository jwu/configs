@echo off
setlocal enabledelayedexpansion
:: ========================================

:: version setup
set "AL_VER=v0.17.0"
set "FONT_VER=v3.4.0"
set "CLINK_URL=https://github.com/chrisant996/clink/releases/download/v1.9.18/clink.1.9.18.c01124.zip"
set "CLINK_COMP_VER=0.6.8"
set "STARSHIP_VER=v1.24.2"
set "FZF_VER=0.71.0"
set "Z_VER=0.9.9"
set "FD_VER=10.4.2"
set "BAT_VER=0.26.1"
set "DELTA_VER=0.19.2"
set "RIPGREP_VER=15.1.0"
set "EZA_VER=0.23.4"
set "COREUTILS_VER=0.8.0"

:: error handling
set "ERROR_COUNT=0"

:: target directory
set "TARGET_DIR=%USERPROFILE%\bin"

:: find root dir
for /f "delims=" %%i in ("%~dp0") do (
  set "MY_ROOT=%%~fi"
)
:: remove trailing '\' from %MY_ROOT%
if "%MY_ROOT:~-1%" == "\" set "MY_ROOT=%MY_ROOT:~0,-1%"

:: create target directory
call :CREATE_DIR_IF_NOT_EXISTS "%TARGET_DIR%"

:: ========================================
:: DEBUG
:: ========================================

call :UPDATE_ALACRITTY
call :UPDATE_NERD_FONT
call :UPDATE_CLINK
call :UPDATE_STARSHIP
call :UPDATE_FZF
call :UPDATE_Z
call :UPDATE_FD
call :UPDATE_EZA
call :UPDATE_COREUTILS
call :UPDATE_BAT
call :UPDATE_RIPGREP
call :UPDATE_DELTA
goto:END

:: ========================================
:UPDATE_ALACRITTY
:: ========================================

echo download alacritty.exe
curl https://github.com/alacritty/alacritty/releases/download/%AL_VER%/Alacritty-%AL_VER%-portable.exe ^
  -L --progress-bar ^
  -o %TARGET_DIR%\alacritty.exe
echo alacritty installed successfully
echo ========================================
goto:eof

:: ========================================
:UPDATE_NERD_FONT
:: ========================================

:: create NerdFont directory
set "MY_NERD_FONT=%TARGET_DIR%\NerdFont"
call :CREATE_DIR_IF_NOT_EXISTS "%MY_NERD_FONT%"
call :CREATE_DIR_IF_NOT_EXISTS "%MY_NERD_FONT%\FiraMono"

call :DOWNLOAD_AND_EXTRACT "https://github.com/ryanoasis/nerd-fonts/releases/download/%FONT_VER%/FiraMono.zip" "%MY_NERD_FONT%\FiraMono.zip" "%MY_NERD_FONT%\FiraMono"

echo install FiraMono fonts
call cmds\addfonts.cmd %MY_NERD_FONT%\FiraMono\
echo FiraMono fonts installed successfully
echo ========================================
goto:eof

:: ========================================
:UPDATE_CLINK
:: ========================================

call :CREATE_DIR_IF_NOT_EXISTS "%TARGET_DIR%\clink"
call :DOWNLOAD_AND_EXTRACT "%CLINK_URL%" "%TARGET_DIR%\clink.zip" "%TARGET_DIR%\clink"
call :DOWNLOAD_AND_EXTRACT "https://github.com/vladimir-kotikov/clink-completions/archive/refs/tags/v%CLINK_COMP_VER%.zip" "%TARGET_DIR%\clink-completions.zip" "%TARGET_DIR%"

cd %TARGET_DIR%
if exist clink-completions (
  echo remove existing clink-completions directory
  rd /s /q clink-completions
)
if exist clink-completions-%CLINK_COMP_VER% (
  ren clink-completions-%CLINK_COMP_VER% clink-completions
) else (
  echo clink-completions-%CLINK_COMP_VER% directory not found after extraction
  set /a "ERROR_COUNT+=1"
)
cd ..
echo clink and clink-completions installed successfully
echo ========================================
goto:eof

:: ========================================
:UPDATE_STARSHIP
:: ========================================

call :DOWNLOAD_AND_EXTRACT "https://github.com/starship/starship/releases/download/%STARSHIP_VER%/starship-x86_64-pc-windows-msvc.zip" "%TARGET_DIR%\starship.zip" "%TARGET_DIR%"

echo starship installed successfully
echo ========================================
goto:eof

:: ========================================
:UPDATE_FZF
:: ========================================

call :DOWNLOAD_AND_EXTRACT "https://github.com/junegunn/fzf/releases/download/v%FZF_VER%/fzf-%FZF_VER%-windows_amd64.zip" "%TARGET_DIR%\fzf.zip" "%TARGET_DIR%"

echo fzf installed successfully
echo ========================================
goto:eof

:: ========================================
:UPDATE_Z
:: ========================================

call :DOWNLOAD_AND_EXTRACT "https://github.com/ajeetdsouza/zoxide/releases/download/v%Z_VER%/zoxide-%Z_VER%-x86_64-pc-windows-msvc.zip" "%TARGET_DIR%\zoxide.zip" "%TARGET_DIR%"

echo zoxide installed successfully
echo ========================================
goto:eof

:: ========================================
:UPDATE_FD
:: ========================================

set "FD_DIR_NAME=fd-v%FD_VER%-x86_64-pc-windows-msvc"
set "FD_ZIP_URL=https://github.com/sharkdp/fd/releases/download/v%FD_VER%/%FD_DIR_NAME%.zip"

call :DOWNLOAD_EXTRACT_AND_MOVE "%FD_ZIP_URL%" "%FD_DIR_NAME%" "fd"
echo fd installed successfully
echo ========================================
goto:eof

:: ========================================
:UPDATE_EZA
:: ========================================

set "EZA_ZIP_URL=https://github.com/eza-community/eza/releases/download/v%EZA_VER%/eza_x86_64-pc-windows-gnu.zip"

call :DOWNLOAD_AND_EXTRACT "%EZA_ZIP_URL%" "%TARGET_DIR%\eza.zip" "%TARGET_DIR%"
echo eza installed successfully
echo ========================================
goto:eof

:: ========================================
:UPDATE_COREUTILS
:: ========================================

set "COREUTILS_DIR_NAME=coreutils-%COREUTILS_VER%-x86_64-pc-windows-msvc"
set "COREUTILS_ZIP_URL=https://github.com/uutils/coreutils/releases/download/%COREUTILS_VER%/%COREUTILS_DIR_NAME%.zip"

call :DOWNLOAD_EXTRACT_AND_MOVE "%COREUTILS_ZIP_URL%" "%COREUTILS_DIR_NAME%" "coreutils"
echo coreutils installed successfully
echo ========================================
goto:eof

:: ========================================
:UPDATE_BAT
:: ========================================

set "BAT_DIR_NAME=bat-v%BAT_VER%-x86_64-pc-windows-msvc"
set "BAT_ZIP_URL=https://github.com/sharkdp/bat/releases/download/v%BAT_VER%/%BAT_DIR_NAME%.zip"

call :DOWNLOAD_EXTRACT_AND_MOVE "%BAT_ZIP_URL%" "%BAT_DIR_NAME%" "bat"
echo bat installed successfully
echo ========================================
goto:eof

:: ========================================
:UPDATE_RIPGREP
:: ========================================

set "RIPGREP_DIR_NAME=ripgrep-%RIPGREP_VER%-x86_64-pc-windows-msvc"
set "RIPGREP_ZIP_URL=https://github.com/BurntSushi/ripgrep/releases/download/%RIPGREP_VER%/%RIPGREP_DIR_NAME%.zip"

call :DOWNLOAD_EXTRACT_AND_MOVE "%RIPGREP_ZIP_URL%" "%RIPGREP_DIR_NAME%" "rg"
echo ripgrep installed successfully
echo ========================================
goto:eof

:: ========================================
:UPDATE_DELTA
:: ========================================

set "DELTA_DIR_NAME=delta-%DELTA_VER%-x86_64-pc-windows-msvc"
set "DELTA_ZIP_URL=https://github.com/dandavison/delta/releases/download/%DELTA_VER%/%DELTA_DIR_NAME%.zip"

call :DOWNLOAD_EXTRACT_AND_MOVE "%DELTA_ZIP_URL%" "%DELTA_DIR_NAME%" "delta"
echo delta installed successfully
echo ========================================
goto:eof

:: ========================================
:UTILITY_FUNCTIONS
:: ========================================

:CREATE_DIR_IF_NOT_EXISTS
if not exist "%~1" (
  echo create dir %~1
  mkdir "%~1" || (
    echo Failed to create directory: %~1
    set /a "ERROR_COUNT+=1"
    exit /b 1
  )
)
exit /b 0

:DOWNLOAD_AND_EXTRACT
set "URL=%~1"
set "ZIP_FILE=%~2"
set "EXTRACT_DIR=%~3"

echo download from %URL%
curl "%URL%" -L --progress-bar -o "%ZIP_FILE%" || (
  echo Failed to download: %URL%
  set /a "ERROR_COUNT+=1"
  exit /b 1
)

echo extract %ZIP_FILE% to %EXTRACT_DIR%
tar -xf "%ZIP_FILE%" -C "%EXTRACT_DIR%" || (
  echo Failed to extract: %ZIP_FILE%
  set /a "ERROR_COUNT+=1"
  exit /b 1
)

del "%ZIP_FILE%"
exit /b 0

:DOWNLOAD_EXTRACT_AND_MOVE
set "URL=%~1"
set "DIR_NAME=%~2"
set "EXE_NAME=%~3"

echo download from %URL%
curl "%URL%" -L --progress-bar -o "%TARGET_DIR%\%EXE_NAME%.zip" || (
  echo Failed to download: %URL%
  set /a "ERROR_COUNT+=1"
  exit /b 1
)

echo extract to %TARGET_DIR%
tar -xf "%TARGET_DIR%\%EXE_NAME%.zip" -C "%TARGET_DIR%" || (
  echo Failed to extract: %EXE_NAME%.zip
  set /a "ERROR_COUNT+=1"
  exit /b 1
)

if exist "%TARGET_DIR%\%DIR_NAME%\%EXE_NAME%.exe" (
  echo move %EXE_NAME%.exe to bin
  move /y "%TARGET_DIR%\%DIR_NAME%\%EXE_NAME%.exe" "%TARGET_DIR%\" || (
    echo Failed to move: %EXE_NAME%.exe
    set /a "ERROR_COUNT+=1"
    exit /b 1
  )
  echo clean up %DIR_NAME% dir
  rd /s /q "%TARGET_DIR%\%DIR_NAME%"
) else (
  echo Error: %EXE_NAME%.exe not found in extracted directory
  set /a "ERROR_COUNT+=1"
  exit /b 1
)

del "%TARGET_DIR%\%EXE_NAME%.zip"
exit /b 0

:: ========================================
:END
:: ========================================

if %ERROR_COUNT% equ 0 (
  echo Done
) else (
  echo Update completed with %ERROR_COUNT% error(s)
)
exit /b %ERROR_COUNT%
