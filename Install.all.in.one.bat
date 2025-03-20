@echo off
set param=
set url='https://github.com/MBNpro-ir/All-in-one-spotify/blob/main/Install.all.in.one.ps1'

:: mirror URL
set url2='https://raw.githubusercontent.com/MBNpro-ir/All-in-one-spotify/main/Install.all.in.one.ps1'

:: Set TLS 1.2 for secure download (important for HTTPS)
set tls=[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12;

:: Execute PowerShell command to download and run the script
%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe ^
-Command %tls% $p='%param%'; """ & { $(try { iwr -useb %url% } catch { $p+= ' -m'; iwr -useb %url2% })} $p """" | iex

pause
exit /b