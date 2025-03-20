@echo off
set url='https://raw.githubusercontent.com/MBNpro-ir/All-in-one-spotify/main/Install.all.in.one.ps1'

:: Set TLS 1.2 for secure download (important for HTTPS)
set tls=[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12;

:: Execute PowerShell command to download and run the script directly from raw URL
%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -Command "& { %tls%; Invoke-WebRequest -Uri %url% -UseBasicParsing | Invoke-Expression }"

pause
exit /b