<#
===========================================================================
	 Created on:   	10/08/2020 10:02
	 Created by:   	Ben Whitmore
	 Filename:     	Path_Length.ps1
===========================================================================
    
Version:
1.0

.SYNOPSIS
This script is designed to highlight files on a fileshare that will not be able to be moved to SharePoint online using the SharePoint Migration Tool

.Parameter Path
File Path to test

.Parameter Length
Length of path to test. SharePoint online has a 400 character limit for a file path
https://support.microsoft.com/en-gb/office/invalid-file-names-and-file-types-in-onedrive-and-sharepoint-64883a5d-228e-48f5-b3d2-eb39e07630fa?ui=en-us&rs=en-gb&ad=gb#invalidfilefoldernames

.Example
Path_Length.ps1 -Path "D:\Test\Files" -Length "400"

#>
Param
(
    [Parameter(Mandatory = $True)]
    [String]$Path,
    [Parameter(Mandatory = $False)]
    [String]$Length = 400
)

#Reset Warning
$Warning = $False

#Get file info from fileshare
$Files = Get-ChildItem -Path $Path -recurse | Select-Object Fullname

#Write-Warning "File path is greater than $($Length) characters for the following files"
ForEach ($File in $Files) {
    If ($File.FullName.Length -gt $Length) {
        #Write-Warning "$($File.FullName) ($($File.FullName.Length))"
        $Warning = $True
    }  
}

#Write-Output "File path is less than $($Length) characters for the following files"
ForEach ($File in $Files) {
    If ($File.FullName.Length -lt $Length) {
        #Write-Output "$($File.FullName) ($($File.FullName.Length))"
    }  
}

#Show error if files with large paths found
If ($Warning -eq $True) {
    Write-Warning "Some files in path ""$($Path)"" exceeded the path length of $($Length). See the Out-GridView for more information"
    $Warning = $False
}

#Output results to Grid View
$Files | Select-Object Fullname, @{Name = "PathLength"; Expression = { $_.FullName.Length } }  | Sort-Object PathLength -Decending  | Out-GridView