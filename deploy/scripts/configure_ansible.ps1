[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)

powershell.exe -ExecutionPolicy ByPass -File $file -ForceNewSSLCert -EnableCredSSP -Verbose

Enable-WSManCredSSP -Role Server -Force

Set-Item -Path "WSMan:\localhost\Service\Auth\CredSSP" -Value $true
