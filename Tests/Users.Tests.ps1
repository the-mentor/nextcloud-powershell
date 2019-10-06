#Requires -Modules Pester
[CmdletBinding()]
param (
    [PSCredential]$Credential = $NextcloudCredential,
    [string]$Server = $NextcloudServer
)
if ($env:AGENT_NAME) {
    $Credential = [Management.Automation.PSCredential]::new($(NextcloudUser), (ConvertTo-SecureString $(NextcloudPassword) -AsPlainText -Force))
    $Server = $(NextcloudServer)
}
else {
    if (!$Credential) {
        $Credential = $Global:NextcloudCredential = Get-Credential
    }
    if (!$Server) {
        $Server = $Global:NextcloudServer = Read-Host -Prompt 'Nextcloud Server'
    }
}

Describe 'Users' {
    $UserId = $Credential.UserName
    It 'Connect-NextcloudServer' {
        Connect-NextcloudServer -Server $Server -Credential $Credential | Should -BeNullOrEmpty
    }
    It 'Get-NextcloudUser' {
        $User = Get-NextcloudUser -UserID $UserId | Should -BeNullOrEmpty
        $User.id | Should -Be $UserId
    }
    It 'Add-NextcloudUser' {
        Remove-NextcloudUser -UserID "$UserId-Test1" -ErrorAction SilentlyContinue
        Add-NextcloudUser -UserID "$UserId-Test1" -Password New-Guid | Should -BeNullOrEmpty
        (Get-NextcloudUser -UserID $UserId).id | Should -Be "$UserId-Test1"

        { Add-NextcloudUser -UserID "$UserId-Test1" -Password New-Guid } | Should -Throw -ExpectedMessage 'User already exists'
    }
    It 'Get-NextcloudUsers' {
        $Users = Get-NextcloudUser
        $Users.id | Should -Contain $UserId
        $Users.id | Should -Contain "$UserId-Test1"
    }
    It 'Set-NextcloudUser' {
        Set-NextcloudUser -UserID "$UserId-Test1" -Email 'me@example.com' | Should -BeNullOrEmpty
        (Get-NextcloudUser -UserID "$UserId-Test1").email | Should -Be 'me@example.com'
    }
    It 'Remove-NextcloudUser' {
        Remove-NextcloudUser -UserID "$UserId-Test1" | Should -BeNullOrEmpty
        { Remove-NextcloudUser -UserID "$UserId-Test1" } | Should -Throw -ExpectedMessage '101'
        Get-NextcloudUser -UserID "$UserId-Test1" | Should -BeNullOrEmpty
    }
}