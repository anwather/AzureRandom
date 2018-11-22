Function Generate-MasterKeyAuthorizationSignature {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)][String]$verb,
        [Parameter(Mandatory = $true)][String]$resourceLink,
        [Parameter(Mandatory = $true)][String]$resourceType,
        [Parameter(Mandatory = $true)][String]$dateTime,
        [Parameter(Mandatory = $true)][String]$key,
        [Parameter(Mandatory = $true)][String]$keyType,
        [Parameter(Mandatory = $true)][String]$tokenVersion
    )

    $hmacSha256 = New-Object System.Security.Cryptography.HMACSHA256
    $hmacSha256.Key = [System.Convert]::FromBase64String($key)

    $payLoad = "$($verb.ToLowerInvariant())`n$($resourceType.ToLowerInvariant())`n$resourceLink`n$($dateTime.ToLowerInvariant())`n`n"
    $hashPayLoad = $hmacSha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($payLoad))
    $signature = [System.Convert]::ToBase64String($hashPayLoad);

    [System.Web.HttpUtility]::UrlEncode("type=$keyType&ver=$tokenVersion&sig=$signature")
}