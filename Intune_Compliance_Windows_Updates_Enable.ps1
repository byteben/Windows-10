Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [string]$commercialIDValue
)

$vCommercialIDPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        
if (Test-Path -Path $vCommercialIDPath -eq $false) {
    Try {
        New-Item -Path $vCommercialIDPath -ItemType Key
    }
    Catch {
        Write-Output "Failed to create registry key path: $vCommercialIDPath"
    }
}

if ((Get-ItemProperty -Path $vCommercialIDPath -Name CommercialId -ErrorAction SilentlyContinue) -eq $null) {
    Try {		    
        New-ItemProperty -Path $vCommercialIDPath -Name CommercialId -PropertyType String -Value $commercialIDValue
    }
    Catch {
        Write-Output "Failed to write Commercial Id: $commercialIDValue at registry key path: $vCommercialIDPath"
    }
}