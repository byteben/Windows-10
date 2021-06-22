<#
.Synopsis
Created: 21/06/21
DEV ONLY: Author Ben Whitmore
Purpose: Remove Workplace join registrations - RunAsUser

.Example
Remove-WorkplaceUserJoinRegistration.ps1 -TenantID "0cebf1f4-e0c4-46d4-8c5a-0fc80bed6b2c" -Remove
#>

Param(
    [Parameter(Mandatory = $False)]
    [Switch]$Remove,
    [Parameter(Mandatory = $True)]
    [String] $TenantId
)

#Get JoinInfo Reg keys that match the TenantId
$UserWPJPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\JoinInfo"
$UserWPJRegKeys = Get-ChildItem -Path $UserWPJPath 
$UserWPJRegKeysMatch = @()

Foreach ($UserWPJRegKey in $UserWPJRegKeys) {
    $WorkPlaceRegKey = Join-Path -Path $UserWPJPath -Childpath $UserWPJRegKey.PSChildName
    Try {
        $KeyMatchJoininfo = Get-ItemProperty -Path $WorkPlaceRegKey -Name "TenantId" -ErrorAction SilentlyContinue
        $UserWPJPathMatch = $KeyMatchJoininfo | Where-Object { $_.TenantId -eq $TenantId }
        If (!($Null -eq $UserWPJPathMatch)) {
            $UserWPJRegKeysMatch += $UserWPJPathMatch.PSChildName
        }
    }
    Catch {
    }
}

#Write registry match for HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\JoinInfo\<GUID> Where TenantId matched
Foreach ($WPJRegKeyFound in $UserWPJRegKeysMatch) {
    Write-Host "AAD Registration match found at: ""HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\Joininfo\$WPJRegKeyFound"""
}

#Get TenantInfo Reg keys that match the TenantId
$TenantInfoPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\TenantInfo"
$TenantInfoPathRegKeys = Get-ChildItem -Path $TenantInfoPath
$TenantInfoPathRegKeysMatch = @()

Foreach ($TenantInfoPathRegKey in $TenantInfoPathRegKeys) {
    If ($TenantInfoPathRegKey.PSChildName -eq $TenantId) {
        $TenantInfoPathRegKeysMatch += $TenantInfoPathRegKey.PSChildName
    }
}

#Write registry match for HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\TenantInfo\<GUID> Where TenantId matched
Foreach ($AADRegTenantFound in $TenantInfoPathRegKeysMatch) {
    Write-Host "Tenant match found at: ""HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\TenantInfo\$AADRegTenantFound"""
}

#Get Personal Certificate for AAD Registrations found in registry
$Certs = @()
Foreach ($Cert in $UserWPJRegKeysMatch) {
    Try {
        $AAD_Cert = Get-ChildItem -path Cert:\CurrentUser\My | Where-Object { $_.ThumbPrint -eq $Cert } -ErrorAction SilentlyContinue
        If ($AAD_Cert) {
            
            $Certs += $Cert
        }  
    }
    Catch {
    }
}

#Write certificate match where thumbprints match AAD registry key registration information
Foreach ($CertFound in $Certs) {
    Write-Host "Certificate found with Thumbprint ""$($CertFound)"""
}

#Remove Registry Keys and Certificates if the $Remove parameter is passed
If ($Remove) {
    Write-Host "INFO: ""Remove"" parameter passed to script. Removing AAD Registration and certificates for Tenant ""$($TenantId)"" for the current user" -ForegroundColor Yellow

    #Remove registry for HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\JoinInfo\<GUID> Where TenantId matched

    Foreach ($WPJRegKeyFound in $UserWPJRegKeysMatch) {
        Write-Host "Removing AAD Registration WPJ match found at: ""HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\JoinInfo\$WPJRegKeyFound"""
        Remove-Item (Join-Path -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\JoinInfo" -ChildPath $WPJRegKeyFound) -Force -Recurse
    }

    #Remove registry for HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\TenantInfo\<GUID> Where TenantId matched
    Foreach ($AADTenantFound in $TenantInfoPathRegKeysMatch) {
        Write-Host "Removing AAD Registration Tenant match found at: ""HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\TenantInfo\$AADTenantFound"""
        Remove-Item (Join-Path -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\TenantInfo" -ChildPath $AADTenantFound) -Force -Recurse
    }

    #Remove Certificate(s) identified for AAD Join Where TenantId matched
    Foreach ($WPJRegKeyFound in $UserWPJRegKeysMatch) {
        Write-Host "Removing Certificate with Thumbprint: ""$($WPJRegKeyFound)"""
        Get-ChildItem -path Cert:\CurrentUser\My | Where-Object { $_.ThumbPrint -eq $WPJRegKeyFound } -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }

    #DSREGCMD Leave to clear up registration
    Start-Process $ENV:Windir\System32\dsregcmd.exe /leave
}