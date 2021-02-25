$Path = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
$Channel = @(
    "Update{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}"
    "Update{2CD8A007-E189-409D-A2C8-9AF4EF3C72AA}"
    "Update{65C35B14-6C1D-4122-AC46-7148CC9D6497}"
    "Update{0D50BFEC-CD6A-4F9A-964C-C7416E3ACB10}"
)
$Type = "DWORD"
$Value = 1

ForEach ($Name in $Channel) {
    Try {
        Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop -ErrorVariable NotExist | Out-Null
        Write-Output """$Path\$Name"" Exists"
        Write-Output "Attempting to set the Registry Value to $Value"
    }
    Catch {
        Write-Warning "Registry value for $Name not found"
    }  

    Try {
        If (!($NotExist)) {
            Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value -ErrorAction Stop | Out-Null
            Write-Output "Updated Registry Value Succesfully"
        }
    }
    Catch {
        Write-Warning "Could not update the registry value for $Name"
    }
}  