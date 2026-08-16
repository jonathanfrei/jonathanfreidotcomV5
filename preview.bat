@echo off
setlocal EnableExtensions
title jonathanfrei.com preview

rem Always run from this repo, even when launched from a Desktop shortcut.
cd /d "%~dp0"

set PORT=4000
set URL=http://127.0.0.1:%PORT%/
set IMAGE_OPTIMIZE=true

rem Toggle: 1 = incremental rebuilds after the first build. 0 = full rebuilds.
rem A command-line argument overrides this: incremental  or  full
set INCREMENTAL=0
if /I "%~1"=="incremental" set INCREMENTAL=1
if /I "%~1"=="--incremental" set INCREMENTAL=1
if /I "%~1"=="-I" set INCREMENTAL=1
if /I "%~1"=="/I" set INCREMENTAL=1
if /I "%~1"=="fast" set INCREMENTAL=1
if /I "%~1"=="full" set INCREMENTAL=0
if /I "%~1"=="--full" set INCREMENTAL=0

echo.
echo  jonathanfrei.com - local preview
echo  Repo: %CD%
echo  URL:  %URL%
if "%INCREMENTAL%"=="1" (
  echo  Mode: incremental - faster rebuilds after the first build.
  echo        Run preview.bat full if lists, tags, or images look stale.
) else (
  echo  Mode: full build
  echo        For faster rebuilds: preview.bat incremental
)
echo.
echo  First build can take a couple of minutes. The browser
echo  opens when the homepage is ready. Close this window
echo  or press Ctrl+C to stop the server.
echo.

rem Double-click PATH is sometimes missing RubyInstaller.
if exist "C:\Ruby33-x64\bin\ruby.exe" set "PATH=C:\Ruby33-x64\bin;%PATH%"
if exist "C:\Ruby34-x64\bin\ruby.exe" set "PATH=C:\Ruby34-x64\bin;%PATH%"

where ruby >nul 2>&1
if errorlevel 1 (
  echo Ruby was not found. Install Ruby 3.3 from https://rubyinstaller.org/
  echo and reopen this window.
  goto fail
)

where bundle >nul 2>&1
if errorlevel 1 (
  echo Bundler was not found. Try:  gem install bundler
  goto fail
)

rem If a preview is already running, just open it.
netstat -ano ^| findstr /R /C:":%PORT% .*LISTENING" >nul 2>&1
if not errorlevel 1 (
  echo Port %PORT% is already in use - opening the existing preview.
  start "" "%URL%"
  goto end
)

echo Checking gems...
call bundle check >nul 2>&1
if errorlevel 1 (
  echo Installing gems, one-time...
  call bundle install
  if errorlevel 1 goto fail
)

set JEKYLL_FLAGS=--host 127.0.0.1 --port %PORT% --open-url --livereload
if "%INCREMENTAL%"=="1" set JEKYLL_FLAGS=%JEKYLL_FLAGS% --incremental

echo Building and serving. IMAGE_OPTIMIZE=true so images match production.
echo.

rem call is required: bundle is a .bat, and running a .bat without call
rem exits this script as soon as that .bat returns.
call bundle exec jekyll serve %JEKYLL_FLAGS%
if errorlevel 1 goto fail
goto end

:fail
echo.
echo Preview failed. See the messages above.
pause
exit /b 1

:end
echo.
echo Server stopped.
pause
endlocal
