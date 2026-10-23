@echo off
rem Starts Google Chrome with remote debugging for npm run screenshots.
rem Uses a separate profile so the normal Chrome profile is untouched.
set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" set "CHROME=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" (
  echo Google Chrome not found.
  exit /b 1
)
start "" "%CHROME%" --remote-debugging-port=9222 --user-data-dir="%LOCALAPPDATA%\GemEyeShots" http://localhost:3000/admin/login/
