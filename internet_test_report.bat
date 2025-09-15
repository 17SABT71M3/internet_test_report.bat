@echo off & setlocal enabledelayedexpansion
SET FLAG_STAY_OPEN=1

    set counters=0
    for /f "tokens=2* delims=:" %%a in ('netsh wlan show interfaces ^|  findstr "Name.*[:]"') do set /a counters+=1 & set "ifacename[!counters!]=%%a"
    if !counters! LEQ 1 for /f %%i in ("%counters%") do set interfacename=!ifacename[%%i]!
    if !counters! GTR 1 (
    set choices=
    echo Select an interface
    for /l %%i in (1,1,!counters!) do echo %%i^) !ifacename[%%i]! & set choices=!choices!%%i
    choice /c !choices!
    for /f "delims=" %%i in ("!errorlevel!") do set interfacename=!ifacename[%%i]!
    )
    for /f "tokens=* delims= " %%a in ("!interfacename!") do set "interfacename=%%a"

    
    if "!interfacename!" NEQ "" (for /f "delims=" %%i in ("!interfacename!") do echo ^<%%i^>) else (echo: & echo:***No Wireless interface found^!*** & echo: &  PAUSE & GOTO :eof)


echo /-----------------"%~nx0"-----------------\
set /a points=0
set is_connected=0
set is_dhcp=
set FLAG_INTERNET_CONNECTION_GATEWAY=1.1.1.1
for /f "tokens=1,* delims=:" %%i in ('netsh wlan show interfaces ^| findstr /ir "Name.*[:] State.*[:] ssid.*[:]"') do (for /f "tokens=1 delims= " %%b in ("%%i") do if /i "%%b"=="state" for /f "tokens=* delims= " %%a in ("%%j") do if /i "%%a"=="connected" set is_connected=1&set /a points+=1)
if %is_connected%==1 (echo:[V] Interface is connected) else (echo:^<^^^!^> Disconnected)
for /f "tokens=*" %%i in ('netsh  interface ipv4 show addresses name^="!interfacename!"  ^| find "DHCP enabled:"') do for /f "tokens=3 delims=: " %%a in ("%%i") do set is_dhcp=%%a&echo     checking dhcp... %%a
set dns_is_reachable=0
set internet_gateway_is_reachable=0
call :check_ip_settings&call :check_gateway&call :check_internet_connection
goto print_reports
:check_gateway
set gateway_is_reachable=0
if "%gateway%" NEQ "" (ping -n 1 %GATEWAY% | find /i "ttl=" >NUL&&(set /a points+=1&set gateway_is_reachable=1))
exit /b
:check_internet_connection
if "%dns_server%" == "" (ping -n 1 %FLAG_INTERNET_CONNECTION_GATEWAY% | find /i "ttl=" >NUL&&(set /a points+=1&set internet_gateway_is_reachable=1)) else (ping -n 1 %dns_server% | find /i "ttl=" >NUL&&(set /a points+=1&set dns_is_reachable=1))
exit /b
:check_ip_settings
set ip_address=
set gateway=
set dns_server=
set ip_1=
for /f "tokens=1,* delims=:" %%i in ('netsh interface ipv4 show config name^="!interfacename!" ^| findstr /ir "ip address[:] gateway[:]"') do for /f "tokens=1,2 delims= " %%b in ("%%i") do (if /i "%%b %%c"=="ip address" set ip_address=%%j&set /a points+=1)&(if /i "%%b %%c"=="default gateway" set gateway=%%j&set /a points+=1)
for /f "tokens=2  delims=:" %%i in ('netsh interface ipv4 show config name^="!interfacename!" ^| findstr /ir "DNS"') do set dns_server=%%i
if "%dns_server%" NEQ "" for /f  "tokens=1 delims= " %%i in ("%dns_server%") do set dns_server=%%i
if "%gateway%" NEQ "" for /f  "tokens=1 delims= " %%i in ("%gateway%") do set gateway=%%i
if "%ip_address%" NEQ "" for /f  "tokens=1 delims= " %%i in ("%ip_address%") do set ip_address=%%i
if "%ip_address%" NEQ "" for /f  "tokens=1 delims=." %%i in ("%ip_address%") do set ip_1=%%i
exit /b
:print_reports
if "%is_dhcp%"=="Yes" echo     IP Configuration: DHCP
if "%is_dhcp%"=="No" echo     IP Configuration: Static

if "%ip_1%" == "" (echo:^<^^^!^> ERROR: Ip address is not set^!)
if "%ip_1%" NEQ "" if "%ip_1%"=="169" (echo:^<^^^!^> ERROR: I.P address configuration has failed^!) else (echo:[V] IP Address is set as %ip_address%&set /a points+=1)
if "%gateway%"=="" (echo:^<^^^!^> ERROR: Gateway address is empty^!) else (echo:[V] Gateway: %gateway%)
if "%dns_server%"=="" (echo:^<^^^!^> ERROR: DNS address is missing^!) else (if /i "%dns_server%"=="none" ( echo:^<^^^!^> ERROR: DNS address is missing^! ) else (echo:[V] Dns server: %dns_server%))
if %gateway_is_reachable%==1 (echo:[V] Gateway . . . . . . . . : reachable) else (echo:^<^^^!^> ERROR: Gateway is not reachable.)
if "%dns_server%"=="" (if %internet_gateway_is_reachable%==1 (echo:[V] %FLAG_INTERNET_CONNECTION_GATEWAY% is reachable.) else (echo:    DNS Server is missing.&echo:^<^^^!^> ERROR: %FLAG_INTERNET_CONNECTION_GATEWAY% is not reachable.)) else (if %dns_is_reachable%==1 (echo:[V] Dns . . . . . . . . . . : reachable) else (echo:^<^^^!^> ERROR: Dns is not reachable.))
echo:POINTS           ^ =        [%points%/6]
REM if %points% ==6 (call :colors black green "V")
REM if %points% LSS 6 ( call :colors black magenta "X")
if %FLAG_STAY_OPEN%==1 (for /l %%i in (1,1,5) do echo:) & pause >NUL
goto :eof