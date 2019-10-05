Import-Module .\Nextcloud.psd1 -Force

$User = 'Me'
$Credential = Get-Credential $User

Connect-NextcloudServer -Server nextcloud-dev.powershellonlinux.com -Credential $Credential

Get-NextcloudUser -UserID $User
Set-NextcloudUser -Email 'zoby101@gmail.com' -UserID $User
Add-NextcloudUser -UserID "$User-Test1" -Password New-Guid
Remove-NextcloudUser -UserID "$User-Test1"