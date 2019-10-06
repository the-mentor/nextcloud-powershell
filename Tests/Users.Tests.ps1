#Requires -Modules Pester
[CmdletBinding()]
param (
    [PSCredential]$Credential = $NextcloudCredential,
    [string]$Server = $NextcloudServer
)
if ($env:AGENT_NAME) {
    $Credential = [Management.Automation.PSCredential]::new($env:VarNextcloudUser, (ConvertTo-SecureString $env:VarNextcloudPassword -AsPlainText -Force))
    $Server = $env:VarNextcloudServer
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
    BeforeEach {
        $FailedCount = InModuleScope -ModuleName Pester { $Pester.FailedCount }
        if ($FailedCount -gt 0) {
            Set-ItResult -Skipped -Because 'Previous test failed'
        }
    }
    $UserIdAdmin = $Credential.UserName
    $UserIdTest1 = "{0}-{1}-Test1" -f $UserIdAdmin, $(if ($env:SYSTEM_JOBDISPLAYNAME) { $env:SYSTEM_JOBDISPLAYNAME } else { 'Local' })
    It 'Connect-NextcloudServer' {
        Connect-NextcloudServer -Server $Server -Credential $Credential | Should -BeNullOrEmpty
    }
    It 'Get-NextcloudUser' {
        $User = Get-NextcloudUser -UserID $UserIdAdmin
        $User.id | Should -Be $UserIdAdmin
    }
    It 'Add-NextcloudUser' {
        try {
            Remove-NextcloudUser -UserID $UserIdTest1
        }
        catch {
            Write-Verbose $_
        }
        Add-NextcloudUser -UserID $UserIdTest1 -Password New-Guid | Should -BeNullOrEmpty
        (Get-NextcloudUser -UserID $UserIdTest1).id | Should -Be $UserIdTest1

        { Add-NextcloudUser -UserID $UserIdTest1 -Password New-Guid } | Should -Throw -ExpectedMessage 'User already exists'
    }
    It 'Get-NextcloudUsers' {
        $Users = Get-NextcloudUser
        $Users.id | Should -Contain $UserIdAdmin
        $Users.id | Should -Contain $UserIdTest1
    }
    It 'Set-NextcloudUser' {
        Set-NextcloudUser -UserID $UserIdTest1 -Email 'me@example.com' | Should -BeNullOrEmpty
        (Get-NextcloudUser -UserID $UserIdTest1).email | Should -Be 'me@example.com'
    }
    It 'Remove-NextcloudUser' {
        Remove-NextcloudUser -UserID $UserIdTest1 | Should -BeNullOrEmpty
        { Remove-NextcloudUser -UserID $UserIdTest1 } | Should -Throw -ExpectedMessage '101'
        Get-NextcloudUser -UserID $UserIdTest1 | Should -BeNullOrEmpty
    }
}