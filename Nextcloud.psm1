function Invoke-NextcloudApi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$Api,

        [ValidateSet('Get', 'Post', 'Put', 'Delete')]
        [String]$Method,

        [hashtable]$Body,
        [Switch]$Json
    )

    if ($Json) {
        if ($Body) {
            $Body['format'] = 'json'
        }
        else {
            $Body = @{ format = 'json' }
        }
    }

    $Params = @{ }
    if ($Body) {
        $Params['Body'] = $Body
    }
    if ($Method) {
        $Params['Method'] = $Method
    }
    if ($Method -in 'Post', 'Put') {
        $Params['ContentType'] = 'application/x-www-form-urlencoded'
    }

    $r = Invoke-RestMethod -Headers $Script:NextcloudAuthHeaders  -Uri "$Script:NextcloudBaseURL/$Api" @Params
    if ($r.ocs.meta.status -ne 'ok') {
        $PSCmdlet.ThrowTerminatingError(
            [Management.Automation.ErrorRecord]::new(
                [ArgumentException]::new(('Command failed, status: "{0}", code: "{1}", message: "{2}".' -f $r.ocs.meta.status, $r.ocs.meta.statuscode, $r.ocs.meta.message)),
                'Status not "ok"',
                [Management.Automation.ErrorCategory]::InvalidResult,
                $r
            )
        )
    }
    $r.ocs.data
}

function Connect-NextcloudServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCredential]$Credential,
        [string]$Server,
        [switch]$NoSSL
    )

    $creds = "{0}:{1}" -f $Credential.UserName, $Credential.GetNetworkCredential().Password
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($creds))
    $basicAuthValue = "Basic $encodedCreds"
    $Headers = @{
        Authorization    = $basicAuthValue
        'OCS-APIRequest' = 'true'
    }

    if ($NoSSL) {
        $UrlPrefix = 'http://'
    }
    else {
        $UrlPrefix = 'https://'
    }

    $NextcloudBaseURL = $UrlPrefix + $Server
    Write-Verbose "NextcloudBaseURL: $NextcloudBaseURL"


    try {
        $r = Invoke-RestMethod -Method Get -Headers $Headers -Uri "$NextcloudBaseURL/ocs/v1.php/cloud/users?search=&format=json&limit=1" -ErrorVariable:fail
    }
    catch {
        Write-Error "Nextcloud Server could not be contacted please check the server URL: $NextcloudBaseURL"
    }


    if ($r.ocs.meta.status -eq 'ok') {
        Write-Verbose "Connected to Nextcloud Server: $Server"
        $Script:NextcloudAuthHeaders = $Headers
        $Script:NextcloudBaseURL = $NextcloudBaseURL
    }
    else {
        Write-Error "Failed to Authenticate to Nextcloud Server: $Server. Server returned: $($fail.message.split(',') | select-string statuscode) "
    }
}

function Get-NextcloudUser {
    [CmdletBinding()]
    param(
        [string]$UserID
    )

    $r = Invoke-NextcloudApi -Api "ocs/v1.php/cloud/users" -Json
    $rf = $r.users | Select-Object @{l = 'Users'; e = { $_ } }

    if ($UserID) {
        if ($rf.Users | Where-Object { $_ -eq $UserID }) {
            $r2 = Invoke-NextcloudApi -Api "ocs/v1.php/cloud/users/$UserID" -Json
            return $r2
        }
    }
    else {
        $r2 = $rf.Users | ForEach-Object {
            Invoke-NextcloudApi -Api "ocs/v1.php/cloud/users/$_" -Json
        }

        return $r2
    }
}

function Set-NextcloudUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$UserID,
        [string]$Password,
        [string]$DisplayName,
        [string]$Email,
        [array]$Groups,
        [array]$Subadmin,
        [string]$Quota,
        [string]$Language,
        [switch]$Disable,
        [switch]$Enable
    )

    if ($Enable -and $Disable) {
        Throw "Enable and Disable cant be specified together"
    }

    if ($Enable) {
        $e = Invoke-NextcloudApi -Method Put -Api "ocs/v1.php/cloud/users/$UserID/enable"
        Write-Verbose "User: $UserID Enabled Successfuly!"
    }
    elseif ($Disable) {
        $e = Invoke-NextcloudApi -Method Put -Api "ocs/v1.php/cloud/users/$UserID/disable"
        Write-Verbose "User: $UserID Disabled Successfuly!"
    }

    if ($Email) {
        $requestBody = @{
            key   = 'email'
            value = $Email
        }
        $e = Invoke-NextcloudApi -Method Put -Api "ocs/v1.php/cloud/users/$UserID" -Body $requestBody
    }

    if ($Password) {
        $requestBody = @{
            key   = 'password'
            value = $Password
        }
        $e = Invoke-NextcloudApi -Method Put -Api "ocs/v1.php/cloud/users/$UserID" -Body $requestBody
    }

    if ($DisplayName) {
        $requestBody = @{
            key   = 'displayname'
            value = $DisplayName
        }
        $e = Invoke-NextcloudApi -Method Put -Api "ocs/v1.php/cloud/users/$UserID" -Body $requestBody
    }

    if ($Quota) {
        $requestBody = @{
            key   = 'quota'
            value = $Quota
        }
        $e = Invoke-NextcloudApi -Method Put -Api "ocs/v1.php/cloud/users/$UserID" -Body $requestBody
    }
}

function Add-NextcloudUser {
    [CmdletBinding()]
    param(
        [string]$UserID,
        [string]$Password,
        [string]$DisplayName,
        [string]$Email,
        #[array]$Groups,
        #[array]$Subadmin,
        [string]$Quota,
        [string]$Language
    )

    $requestBody = @{
        userid      = $UserID
        password    = $Password
        displayname = $DisplayName
        email       = $Email
        #groups = $Groups
        #subadmin = $Subadmin
        quota       = $Quota
        language    = $Language
    }

    $r = Invoke-NextcloudApi -Method Post -Api "ocs/v1.php/cloud/users" -Body $requestBody
    Write-Verbose "User: $UserID Created Successfuly!"
}

function Remove-NextcloudUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$UserID
    )

    if ($null -eq $UserID -or $UserID -eq '') { throw 'Please specify user ID. ID cant be empty!' }

    $r = Invoke-NextcloudApi -Method Delete -Api "ocs/v1.php/cloud/users/$UserID"
    Write-Verbose "User: $UserID Deleted Successfuly!"
}
