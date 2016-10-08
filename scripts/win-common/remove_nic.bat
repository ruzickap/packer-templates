echo "*** Downloading devcon64.exe from https://github.com/PlagueHO/devcon-choco-package/raw/master/devcon.portable/devcon64.exe"
powershell -command "$client = new-object System.Net.WebClient; $client.DownloadFile('https://github.com/PlagueHO/devcon-choco-package/raw/master/devcon.portable/devcon64.exe', 'c:\devcon64.exe')"

echo "*** Removing the NICs"
for /f "tokens=1 delims=: " %%G in ('c:\devcon64.exe findall ^=net ^| findstr /c:"Red Hat VirtIO Ethernet Adapter"') do ( c:\devcon64.exe remove "@%%G" )

echo "*** Remove c:\devcon64.exe"
del c:\devcon64.exe

echo "*** Remove Registry HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles"
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles" /f
