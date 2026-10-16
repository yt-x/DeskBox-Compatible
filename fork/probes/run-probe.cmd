@echo off
REM ============================================================
REM  DeskBox 17763 readiness probe runner  (run on TARGET machine)
REM  Runs the read-only probe under Windows PowerShell 5.1 and
REM  writes the report to this user's Desktop.
REM ============================================================
setlocal
set "HERE=%~dp0"

set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS%" set "PS=powershell.exe"

set "OUT=%USERPROFILE%\Desktop\17763-readiness-report.txt"

echo Running DeskBox readiness probe...
echo.

"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%HERE%17763-readiness.ps1" -OutFile "%OUT%"

if errorlevel 1 (
  echo.
  echo [WARN] The probe reported a failure. Falling back to %%TEMP%%.
  set "OUT=%TEMP%\17763-readiness-report.txt"
  "%PS%" -NoProfile -ExecutionPolicy Bypass -File "%HERE%17763-readiness.ps1" -OutFile "%OUT%"
)

echo.
echo ============================================================
echo  Report: %OUT%
echo  Copy that file back to the build machine.
echo ============================================================
echo.
pause
