<#	
===========================================================================
	 Created on:   	04/07/2020 13:06
	 Created by:   	Ben Whitmore
	 Organization: 	-
	 Filename:     	Install_Font.ps1
===========================================================================
    
Version:
1.0

#>

#Set Current Directory
$ScriptPath = $MyInvocation.MyCommand.Path
$CurrentDir = Split-Path $ScriptPath

#Set Font Reg Key Path
$FontRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

#Grab the Font from the Current Directory
foreach ($Font in $(Get-ChildItem -Path $CurrentDir -Include *.ttf, *.otf, *.fon, *.fnt -Recurse)) {

    #Copy Font to the Windows Font Directory
    Copy-Item $Font "C:\Windows\Fonts\" -Force
    
    #Set the Registry Key to indicate the Font has been installed
    New-ItemProperty -Path $FontRegPath -Name $Font.Name -Value $Font.Name -PropertyType String | Out-Null
}