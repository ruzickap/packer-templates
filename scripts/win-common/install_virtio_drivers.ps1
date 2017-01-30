Write-Host "*** Install Virtio drivers for better compatibility with KVM hypervisor"

Write-Host "*** Download virtio-win.iso"
$client = new-object System.Net.WebClient
$client.DownloadFile('https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso', 'c:\virtio-win.iso')

Write-Host "*** Mount virtio-win.iso"
Mount-DiskImage -ImagePath 'c:\virtio-win.iso'
$driveLetter = (Get-DiskImage 'c:\virtio-win.iso' | Get-Volume).DriveLetter

Write-Host "*** Export certificate"
$cert = (Get-AuthenticodeSignature "${driveLetter}:\Balloon\2k12R2\amd64\blnsvr.exe").SignerCertificate
[System.IO.File]::WriteAllBytes('c:\redhat.cer', $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))

Write-Host "*** Install RH certificate to TrustedPublisher certificate store"
certutil.exe -f -addstore 'TrustedPublisher' c:\redhat.cer

Write-Host "*** Install the VirtIO SCSI pass-through controller Driver (vioscsi)"
pnputil -i -a "${driveLetter}:\vioscsi\$Env:VIRTIO_DRIVER_DIRECTORY\amd64\*.inf"

Write-Host "*** Install the Baloon Driver (Balloon)"
pnputil -i -a "${driveLetter}:\Balloon\$Env:VIRTIO_DRIVER_DIRECTORY\amd64\*.inf"

Write-Host "*** Install Virtio RNG driver (viorng)"
pnputil -i -a "${driveLetter}:\viorng\$Env:VIRTIO_DRIVER_DIRECTORY\amd64\*.inf"

Write-Host "*** Install Virtio serial driver (vioserial)"
pnputil -i -a "${driveLetter}:\vioserial\$Env:VIRTIO_DRIVER_DIRECTORY\amd64\*.inf"

Write-Host "*** Install Virtio Input driver (vioinput)"
pnputil -i -a "${driveLetter}:\vioinput\$Env:VIRTIO_DRIVER_DIRECTORY\amd64\*.inf"

Write-Host "*** Install pvpanic device driver (pvpanic)"
pnputil -i -a "${driveLetter}:\pvpanic\$Env:VIRTIO_DRIVER_DIRECTORY\amd64\*.inf"

Write-Host "*** Install Qemu Guest Agent (qemu-ga-x64.msi)"
Start-Process "${driveLetter}:\guest-agent\qemu-ga-x64.msi" /qn -Wait

Write-Host "*** Unmount virtio-win.iso"
Dismount-DiskImage -ImagePath 'c:\virtio-win.iso'

Write-Host "*** Download vdagent"
$client = new-object System.Net.WebClient
$client.DownloadFile('https://www.spice-space.org/download/windows/vdagent/vdagent-win-0.8.0/vdagent-win-0.8.0.zip', 'c:\vdagent-win.zip')

Write-Host "*** Create $env:ProgramFiles(x64)\SPICE Guest Tools\64 directory"
New-Item "${env:ProgramFiles(x86)}\SPICE Guest Tools\64" -type directory | Out-Null

Write-Host "*** Extract vdagent archive"
Add-Type -A System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::ExtractToDirectory('c:\vdagent-win.zip', "c:\")
Move-Item -Path "c:\vdagent-win-0.8.0\x86_64\*" -Destination "${env:ProgramFiles(x86)}\SPICE Guest Tools\64\"

Write-Host "*** Install vdagent"
& "${env:ProgramFiles(x86)}\SPICE Guest Tools\64\vdservice.exe" install

Write-Host "*** Remove temporary files c:\redhat.cer, c:\virtio-win.iso and c:\vdagent-win*"
rm -Force -Recurse 'c:\virtio-win.iso'
rm -Force -Recurse 'c:\redhat.cer'
rm -Force -Recurse 'c:\vdagent-win*'
