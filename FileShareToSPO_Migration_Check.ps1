<#
===========================================================================
	 Created on:   	10/08/2020 10:02
	 Created by:   	Ben Whitmore
	 Filename:     	Path_Length.ps1
===========================================================================
    
Version:
1.0

.SYNOPSIS
This script is designed to highlight files on a fileshare that will not be able to be 
moved to SharePoint online using the SharePoint Migration Tool

.Parameter Path
File Path to test

.Parameter Length
Length of path to test. SharePoint online has a 400 character limit for a file path
https://support.microsoft.com/en-gb/office/invalid-file-names-and-file-types-in-onedrive-
and-sharepoint-64883a5d-228e-48f5-b3d2-eb39e07630fa?ui=en-us&rs=en-
gb&ad=gb#invalidfilefoldernames

.Parameter OutDir
Specify target Out Directory

.Example
Path_Length.ps1 -Path "D:\Test\Files" -Length "400" -OutDir "C:\Outs"

#>
Param
(
    [Parameter(Mandatory = $True)]
    [String]$Path,
    [Parameter(Mandatory = $False)]
    [String]$Length = 400,
    [String]$OutDir
)

$ScriptPath = $MyInvocation.MyCommand.Path
$CurrentDir = Split-Path $ScriptPath

#Reset Warning
$WarningPath = $Null

#Specify Out File
$OutFile = "SPO_Migrate_Out.csv"

If ($OutDir) {
    $OutDir = $OutDir
}
Else {
    $OutDir = $CurrentDir
}
#Get file info from fileshare

Try {
    $Files = Get-ChildItem -Path $Path -recurse -ErrorAction Continue -ErrorVariable Error_GCI | Select-Object Name, Fullname 
}
Catch {
    Write-Warning "Path error: $($Path), Error: $($Error_GCI)"
    $WarningPath = $True
}

#Write-Warning "File path is greater than $($Length) characters for the following files"
ForEach ($File in $Files) {
    If ($File.FullName.Length -gt $Length) {
        $WarningPath = $True
    }  
}

#Show error if files with large paths found
If ($WarningPath -eq $True) {
    Write-Warning "Some files in path ""$($Path)"" exceeded the path length of $($Length) or the path was unreadable. See the Out-GridView for more information"
    $WarningPath = $Null
}


#Save Out to Path being checked
$Files | Select-Object Fullname, @{Name = "Path_Length"; Expression = { $_.FullName.Length } } | Sort-Object Path_Length -Descending  | Export-Csv (Join-Path $OutDir "SPO_Migration_Check.csv") -Append

#Output results to Grid View
$Files | Select-Object Fullname, @{Name = "Path_Length"; Expression = { $_.FullName.Length 
    } 
} | Sort-Object Path_Length -Descending  | Out-GridView