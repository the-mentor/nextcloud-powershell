function Connect-NextcloudServer {
    param(
        $Username,
        $Password,
        $Server
    )
    
    
    $creds = "$($Username):$($Password)"
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($creds))
    $basicAuthValue = "Basic $encodedCreds" 
    $Headers = @{
        Authorization = $basicAuthValue
        'OCS-APIRequest' = 'true'
    }
    
    $r = Invoke-RestMethod -Method Get -Headers $Headers -Uri "https://$Server/ocs/v1.php/cloud/users?search=&format=json&limit=1"
    if($r.ocs.meta.status -eq 'ok'){
        Write-host "Connected to Nextcloud Server: $Server"
        $Global:NextCloudAuthHeaders
    }
    else{
        Write-Host "Failed to Authenticate to Nextcloud Server: $Server"
    }
}

