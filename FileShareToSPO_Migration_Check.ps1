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
$WarningPath = $Null

#Invalid Characters
#$Exclude = @('"', ',', '*', ':', '<', '>', '?', '/', '\', '|')


#Get file info from fileshare
$Files = Get-ChildItem -Path $Path -recurse | Select-Object Name, Fullname

#Write-Warning "File path is greater than $($Length) characters for the following files"
ForEach ($File in $Files) {
    If ($File.FullName.Length -gt $Length) {
        $WarningPath = $True
    }  
}

#Show error if files with large paths found
If ($WarningPath -eq $True) {
    Write-Warning "Some files in path ""$($Path)"" exceeded the path length of $($Length). See the Out-GridView for more information"
    $WarningPath = $Null
}

#Show error if files with invalid characters
If ($WarningChar -eq $True) {
    Write-Warning "Some files in path ""$($Path)"" contained an invalid charcter. See the Out-GridView for more information"
    $WarningChar = $Null
}

#Output results to Grid View
$Files | Select-Object Fullname, @{Name = "Path_Length"; Expression = { $_.FullName.Length } } | Sort-Object Path_Length -Descending  | Out-GridView