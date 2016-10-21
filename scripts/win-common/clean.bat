echo ==^> Cleaning "%TEMP%" directories >&2

for /d %%i in ("%TEMP%\*.*") do rmdir /q /s "%%~i"

echo ==^> Cleaning "%TEMP%" files >&2

for %%i in ("%TEMP%\*.*") do if /i not "%%~nxi" equ "%~nx0" echo del /f /q /s "%%~i"

echo ==^> Cleaning "%SystemRoot%\TEMP" directories >&2

for /d %%i in ("%SystemRoot%\TEMP\*.*") do rmdir /q /s "%%~i"

echo ==^> Cleaning "%SystemRoot%\TEMP" files >&2

for %%i in ("%SystemRoot%\TEMP\*.*") do if /i not "%%~nxi" equ "%~nx0" echo del /f /q /s "%%~i"

echo ==^> Removing potentially corrupt recycle bin
:: see http://www.winhelponline.com/blog/fix-corrupted-recycle-bin-windows-7-vista/
rmdir /q /s %SystemDrive%\$Recycle.bin

@echo ==^> Script exiting with errorlevel %ERRORLEVEL%
@exit /b %ERRORLEVEL%
