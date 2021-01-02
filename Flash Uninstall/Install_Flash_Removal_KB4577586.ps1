<#	
===========================================================================
	 Created on:   	0/01/2021 13:06
	 Created by:   	Ben Whitmore
	 Organization: 	-
	 Filename:     	Install_Flash_Removal_KB4577586.ps1
===========================================================================
    
Version:
1.0
#>

#Set Current Directory
$ScriptPath = $MyInvocation.MyCommand.Path
$CurrentDir = Split-Path $ScriptPath

$PatchVersions = Get-ChildItem $CurrentDir | Where-Object {$_.PSIsContainer} | Foreach-Object {$_.Name}