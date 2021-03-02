Param(
    [Parameter(Mandatory = $False)]
    [Switch]$Remove,
    [Parameter(Mandatory = $True)]
    [String]$Tenant
)

$OldTenant = $Tenant + ".onmicrosoft.com"
$RegPath = "HKLM:\SOFTWARE\Microsoft\Enrollments"

If ($Remove) {
    Write-Warning "Running script with the Remove parameter. Any existing MDM enrollment registrations will be removed"
}
else {
    Write-Output "Running script without the Remove Parameter. MDM enrollment information will be gathered but not removed"
}

Try {
    $SchTaskObj = New-Object -ComObject Schedule.Service
    $SchTaskObj.connect($ENV:COMPUTERNAME)
    $SchTaskObj_Folder = $SchTaskObj.GetFolder("Microsoft\Windows\EnterpriseMgmt")
    $EntMgmt_SchTask = $SchTaskObj_Folder.GetFolders(1) | Where-Object { [guid]::TryParse($_.Name, $([ref][guid]::Empty)) -eq $True } | Select-Object Name

}
Catch {
    Write-Warning "No MDM Enrollment Scheduled Task was found in ""\Microsoft\Windows\EnterpriseMgmt"""
    Exit 0
}

If ($EntMgmt_SchTask) {
    Foreach ($TaskFolder in $EntMgmt_SchTask) {
        Write-Host "MDM Enrollment Scheduled Task Found: ""$($TaskFolder.Name)"""
        $RegValue = (Join-Path -Path $RegPath -ChildPath $TaskFolder.Name)

        Try {
            $Reg = Get-ItemProperty -Path $RegValue | Where-Object { $_.UPN -like "*$OldTenant" } -ErrorAction SilentlyContinue
        }
        Catch {
            Write-Warning "Unable to get corresponding Registry Key for Scheduled Task ""$($TaskFolder.Name)"""
            Exit 0
        }

        If ($Reg) {
            Write-Output "MDM Enrollement Scheduled Task ""$($TaskFolder.Name)"" is for Tenant ""$OldTenant"""

            Try {
                $MDM_Cert = Get-ChildItem -path Cert:\LocalMachine\My | Where-Object { $_.ThumbPrint -eq $Reg.DMPCertThumbPrint } -ErrorAction SilentlyContinue
                If ($MDM_Cert) {
                    Write-Output "Found Microsoft Intune MDM Device Certificate with matching ThumbPrint ""$($Reg.DMPCertThumbPrint)"""
                }
                else {
                    Write-Warning "No Microsoft Intune MDM Device Certificate found with matching ThumbPrint ""$($Reg.DMPCertThumbPrint)"""
                }
            }
            Catch {
                Write-Warning "Unable to find Certificate with Thumbprint ""$($Reg.DMPCertThumbPrint)"""
            }
            If ($Remove) {
                Write-Output "Removing MDM enrollment registration ""$($TaskFolder.Name)""..."
                If ($MDM_Cert) {
                    Write-Output "Removing MDM Certificate..."
                    Try {
                        $MDM_Cert | Remove-Item -ErrorAction SilentlyContinue
                        Write-Output "Certificate with Thumbprint ""$($Reg.DMPCertThumbPrint)"" Deleted"
                    }
                    Catch {
                        Write-Warning "Failed to remove certificate with Thumbprint ""$($Reg.DMPCertThumbPrint)"""
                        Exit 0
                    }
                }
                Write-Output "Removing Scheduled Tasks..."
                Try {
                    $Tasks = ($SchTaskObj.GetFolder("Microsoft\Windows\EnterpriseMgmt\$($TaskFolder.Name)")).GetTasks(1)
                    ForEach ($Task in $Tasks) {
                        Write-Output "Deleting Task ""$($Task.Name)"""
                        ($SchTaskObj.GetFolder("Microsoft\Windows\EnterpriseMgmt\$($TaskFolder.Name)")).DeleteTask($Task.Name, 0)
                    }
                    ($SchTaskObj.GetFolder("Microsoft\Windows\EnterpriseMgmt")).DeleteFolder($TaskFolder.Name, 0)
                }
                Catch {
                    Write-Warning "Error Removing Scheduled Tasks"
                    Write-Warning $Error[0]
                    Exit 0
                }
                Write-Output "Removing MDM Registry Keys..."
                Try {
                    Remove-Item -Path $RegValue -Recurse -Force -ErrorAction SilentlyContinue
                }
                Catch {
                    Write-Warning "Error Removing MDM Enrollment Registry Key ""$RegValue"""
                    Exit 0
                }
                Write-Output "Completed Removing MDM Enrollment."
            }
        }
    }
}
else {
    Write-Output "No MDM Enrollment found matching the tenant ""$OldTenant"""
} 