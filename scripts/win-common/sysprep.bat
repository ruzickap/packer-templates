mkdir %WINDIR%\Setup\Scripts
echo wmic useraccount where "name='vagrant'" set passwordexpires=false > %WINDIR%\Setup\Scripts\SetupComplete.cmd
echo wmic useraccount where "name='Administrator'" set passwordexpires=false >> %WINDIR%\Setup\Scripts\SetupComplete.cmd

%WINDIR%\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:A:\unattend.xml
