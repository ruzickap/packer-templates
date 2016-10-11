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

Write-Host "*** Install the Baloon Driver (Balloon)"
pnputil -i -a "${driveLetter}:\Balloon\$Env:VIRTIO_DRIVER_DIRECTORY\amd64\*.inf"

Write-Host "*** Install Virtio RNG driver (viorng)"
pnputil -i -a "${driveLetter}:\viorng\$Env:VIRTIO_DRIVER_DIRECTORY\amd64\*.inf"

Write-Host "*** Install Virtio serial driver (vioserial)"
pnputil -i -a "${driveLetter}:\vioserial\$Env:VIRTIO_DRIVER_DIRECTORY\amd64\*.inf"

Write-Host "*** Install pvpanic device driver (pvpanic)"
pnputil -i -a "${driveLetter}:\pvpanic\$Env:VIRTIO_DRIVER_DIRECTORY\amd64\*.inf"

Write-Host "*** Install Qemu Guest Agent (qemu-ga-x64.msi)"
Start-Process "${driveLetter}:\guest-agent\qemu-ga-x64.msi" /qn -Wait

Write-Host "*** Unmount virtio-win.iso"
Dismount-DiskImage -ImagePath 'c:\virtio-win.iso'

Write-Host "*** Remove temporary files c:\redhat.cer and c:\virtio-win.iso"
del 'c:\virtio-win.iso'
del 'c:\redhat.cer'
