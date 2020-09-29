#Credit to https://powershell.one/wmi/root/cimv2/win32_systemenclosure
#Modified original script to output IsLaptop, IsDesktop, IsServer, IsOther to be used as a detection method
$Chassis = @{ 
Name = 'ChassisTypes'
Expression = {
$ChassisResult = foreach($ChassisValue in $_.ChassisTypes)
    {
        switch([int]$ChassisValue)
      {
        1          {'IsOther'}
        2          {'IsOther'}
        3          {'IsDesktop'}
        4          {'IsDesktop'}
        5          {'IsDesktop'}
        6          {'IsDesktop'}
        7          {'IsDesktop'}
        8          {'IsLaptop'}
        9          {'IsLaptop'}
        10         {'IsLaptop'}
        11         {'IsLaptop'}
        12         {'IsLaptop'}
        13         {'IsOther'}
        14         {'IsLaptop'}
        15         {'IsDesktop'}
        16         {'IsDesktop'}
        17         {'IsOther'}
        18         {'IsLaptop'}
        19         {'IsOther'}
        20         {'IsOther'}
        21         {'IsLaptop'}
        22         {'IsOther'}
        23         {'IsServer'}
        24         {'IsOther'}
        default    {"$ChassisValue"}
      }
      
    }
    $ChassisResult
  }  
}

Get-CimInstance -ClassName Win32_SystemEnclosure | Select-Object $Chassis | foreach-object {$_.ChassisTypes}