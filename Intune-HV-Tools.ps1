<#
Intune.HV.Tools
  ______    ______    ______   __               ______   ________  __    __  ________  ________ 
 /      \  /      \  /      \ /  |             /      \ /        |/  |  /  |/        |/        |
/$$$$$$  |/$$$$$$  |/$$$$$$  |$$ |            /$$$$$$  |$$$$$$$$/ $$ |  $$ |$$$$$$$$/ $$$$$$$$/ 
$$ |  $$/ $$ |  $$ |$$ |  $$ |$$ |            $$ \__$$/    $$ |   $$ |  $$ |$$ |__    $$ |__    
$$ |      $$ |  $$ |$$ |  $$ |$$ |            $$      \    $$ |   $$ |  $$ |$$    |   $$    |   
$$ |   __ $$ |  $$ |$$ |  $$ |$$ |             $$$$$$  |   $$ |   $$ |  $$ |$$$$$/    $$$$$/    
$$ \__/  |$$ \__$$ |$$ \__$$ |$$ |_____       /  \__$$ |   $$ |   $$ \__$$ |$$ |      $$ |      
$$    $$/ $$    $$/ $$    $$/ $$       |      $$    $$/    $$ |   $$    $$/ $$ |      $$ |      
 $$$$$$/   $$$$$$/   $$$$$$/  $$$$$$$$/        $$$$$$/     $$/     $$$$$$/  $$/       $$/       
                                                                                                
                                                                                                
                                                                                               
https://github.com/tabs-not-spaces/Intune.HV.Tools

#>

#Initialize Environment
Install-Module -Name Intune.HV.Tools -Scope CurrentUser
Initialize-HVTools -Path "C:\MMSLABS\IntuneHVTools"

#Create templates (convert ISO to VHDX)
Add-ImageToConfig -ImageName "W1121H2" -IsoPath "C:\MMSLABS\IntuneHVTools\W1121H2.iso"
Add-ImageToConfig -ImageName "W1021H1" -IsoPath "C:\MMSLABS\IntuneHVTools\W1021H1.iso"

#Alternatively add a custom VHDX to the environment
Add-ImageToConfig -ImageName "2004" -ReferenceVHDX "c:\Path\To\ref10.vhdx"

#Add Tenant to the config (Image Name can be overidden, it just sets a default image for the tenant)
Add-TenantToConfig -TenantName 'byteben' -ImageName W1121H2 -AdminUpn 'gadm-ben@byteben.com'

#Add VSwitch
Add-NetworkToConfig -VSwitchName 'WAN'

#Review Config
Get-HVToolsConfig
