function Connect-NextcloudServer {
    [cmdletbinding()]
    param(
        $Username,
        $Password,
        $Server,
        [switch]$NoSSL
    )
    
    $creds = "$($Username):$($Password)"
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($creds))
    $basicAuthValue = "Basic $encodedCreds" 
    $Headers = @{
        Authorization = $basicAuthValue
        'OCS-APIRequest' = 'true'
    }

    if($NoSSL){
        $UrlPrefix = 'http://'
    }
    else{
        $UrlPrefix = 'https://'
    }
    
    $NextcloudBaseURL = $UrlPrefix + $Server
    Write-Verbose "NextcloudBaseURL: $NextcloudBaseURL"


    try{
        $r = Invoke-RestMethod -Method Get -Headers $Headers -Uri "$NextcloudBaseURL/ocs/v1.php/cloud/users?search=&format=json&limit=1"
    }
    catch{
        Write-Error "Nextcloud Server could not be contacted please check the server URL: $NextcloudBaseURL"
    }

    
    if($r.ocs.meta.status -eq 'ok'){
        Write-host "Connected to Nextcloud Server: $Server"
        $Global:NextcloudAuthHeaders = $Headers
        $Global:NextcloudBaseURL = $NextcloudBaseURL
    }
    else{
        Write-Host "Failed to Authenticate to Nextcloud Server: $Server"
    }
}

function Get-NextcloudUser {
    [cmdletbinding()]
    param(
        [string]$Name 
    )

    $r = Invoke-RestMethod -Method Get -Headers $Global:NextcloudAuthHeaders -Uri "$($Global:NextcloudBaseURL)/ocs/v1.php/cloud/users?search=&format=json"
    $rf = $r.ocs.data.users |Select-Object @{l='Users';e={$_}}
    
    if($Name){
        if($rf.Users|Where-Object {$_ -eq $Name}){
            $r2 = Invoke-RestMethod -Method Get -Headers $Global:NextcloudAuthHeaders  -Uri "$($Global:NextcloudBaseURL)/ocs/v1.php/cloud/users/$Name"
            return $r2.ocs.data 
        }
    }
    else{
        $r2 = $rf.Users |ForEach-Object{
            Invoke-RestMethod -Method Get -Headers $Global:NextcloudAuthHeaders  -Uri "$($Global:NextcloudBaseURL)/ocs/v1.php/cloud/users/$_"
        }
        
        return $r2.ocs.data
    }
}

function Set-NextcloudUser {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][string]$UserID,
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

    if($Enable -and $Disable){
        Throw "Enable and Disable cant be specified together"
    }
    
    if($Enable){
        $e = Invoke-RestMethod -Method Put -Headers $Global:NextcloudAuthHeaders -Uri "$($Global:NextcloudBaseURL)/ocs/v1.php/cloud/users/$UserID/enable" 
        if($e.ocs.meta.status -eq 'ok'){
            Write-Host "User: $UserID Enabled Successfuly!"
        }
    }
    elseif($Disable){
        $e = Invoke-RestMethod -Method Put -Headers $Global:NextcloudAuthHeaders -Uri "$($Global:NextcloudBaseURL)/ocs/v1.php/cloud/users/$UserID/disable" 
        if($e.ocs.meta.status -eq 'ok'){
            Write-Host "User: $UserID Disabled Successfuly!"
        }
    }

    if($Email){
        $requestBody =  @{
            key = 'email'
            value = $Email
        }
        $e = Invoke-RestMethod -Method Put -Headers $Global:NextcloudAuthHeaders -Uri "$($Global:NextcloudBaseURL)/ocs/v1.php/cloud/users/test7" -Body $requestBody -ContentType application/x-www-form-urlencoded -verbose
    }

    if($Password){
        $requestBody =  @{
            key = 'password'
            value = $Password
        }
        $e = Invoke-RestMethod -Method Put -Headers $Global:NextcloudAuthHeaders -Uri "$($Global:NextcloudBaseURL)/ocs/v1.php/cloud/users/test7" -Body $requestBody -ContentType application/x-www-form-urlencoded -verbose
    }

    if($DisplayName){
        $requestBody =  @{
            key = 'displayname'
            value = $DisplayName
        }
        $e = Invoke-RestMethod -Method Put -Headers $Global:NextcloudAuthHeaders -Uri "$($Global:NextcloudBaseURL)/ocs/v1.php/cloud/users/test7" -Body $requestBody -ContentType application/x-www-form-urlencoded -verbose
    }

    if($Quota){
        $requestBody =  @{
            key = 'quota'
            value = $Quota
        }
        $e = Invoke-RestMethod -Method Put -Headers $Global:NextcloudAuthHeaders -Uri "$($Global:NextcloudBaseURL)/ocs/v1.php/cloud/users/test7" -Body $requestBody -ContentType application/x-www-form-urlencoded -verbose
    }
}

function Add-NextcloudUser {
    [cmdletbinding()]
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

    $requestBody =  @{
        userid = $UserID
        password= $Password
        displayname = $DisplayName
        email = $Email
        #groups = $Groups
        #subadmin = $Subadmin
        quota = $Quota
        language = $Language
    }

    $r = Invoke-RestMethod -Method Post -Headers $Global:NextcloudAuthHeaders -Uri "$($Global:NextcloudBaseURL)/ocs/v1.php/cloud/users" -Body $requestBody
    if($r.ocs.meta.status -eq 'ok'){
        Write-Host "User: $UserID Created Successfuly!"
    }
    else{
        Write-Error "$($r.ocs.meta.message)"

    }
}

function Remove-NextcloudUser {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][string]$UserID
    )
    
    if($null -eq $UserID -or $UserID -eq ''){throw 'Please specify user ID. ID cant be empty!'}

    $r = Invoke-RestMethod -Method Delete -Headers $Global:NextcloudAuthHeaders -Uri "$($Global:NextcloudBaseURL)/ocs/v1.php/cloud/users/$UserID" 
    if($r.ocs.meta.status -eq 'ok'){
        Write-Host "User: $UserID Deleted Successfuly!"
    }
    else{
        Write-Error "$($r.ocs.meta.message)"
    }
}
