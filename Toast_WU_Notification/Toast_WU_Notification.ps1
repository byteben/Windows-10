<#
	.NOTES
	===========================================================================
	 Created on:   	17/05/2021 11:12 AM
	 Created by:   	Maurice Daly / Ben Whitmore
	 Organization: 	CloudWay
	 Filename:     	Toast_WU_Notification.ps1
	===========================================================================
	.DESCRIPTION
		Notify the logged on user of a pending Windows Updates Installation
#>

Param
(
    [Parameter(Mandatory = $False)]
    [String]$ToastGUID
)

#region ToastCustomisation

#Create Toast Variables
$ToastTime = "16:30"
$ToastTitle = "An Important Update is Scheduled"
$ToastText = "Windows 10 20H2 is being rolled out this afternoon after 16:00. You MUST leave your computer on. Failure to leave your computer on will result in a delay accessing your computer in the morning."

#ToastDuration: Short = 7s, Long = 25s
$ToastDuration = "long"

#Format Time
$ToastTimeToUse = [datetime]::ParseExact($ToastTime, "HH:mm", $null)

#Images
[uri]$ImageRepositoryUri = "https://dornanbranding.blob.core.windows.net/logos/"
$BadgeImgName = "SquareLogo.png"
$HeroImgName = "DornanLogo.jpg"

#endregion ToastCustomisation

#region ToastRunningValues

#Set Unique GUID for the Toast
If (!($ToastGUID)) {
    $ToastGUID = ([guid]::NewGuid()).ToString().ToUpper()
}

#Current Directory
$ScriptPath = $MyInvocation.MyCommand.Path
$CurrentDir = Split-Path $ScriptPath

#Set Toast Path to Temp Directory
$ToastPath = (Join-Path $ENV:Windir "Temp\$($ToastGuid)")

#Set Toast PS File Name
$ToastPSFile = $MyInvocation.MyCommand.Name

$BadgeImage = Join-Path -Path $ENV:Windir -ChildPath "temp\$BadgeImgName"
$HeroImage = Join-Path -Path $ENV:Windir -ChildPath "temp\$HeroImgName"
#endregion ToastRunningValues

#region ScriptFunctions
# Toast function
function Display-ToastNotification {
	
    #Fetching images from URI
    #$WebClient = New-Object System.Net.WebClient
    #$WebClient.DownloadFile("$BadgeImageUri", "$BadgeImage")
    #$WebClient.DownloadFile("$HeroImageUri", "$HeroImage")

    $BadgeImageUri = [Uri]::new([Uri]::new($ImageRepositoryUri), $BadgeImgName).ToString()
    $HeroImageUri = [Uri]::new([Uri]::new($ImageRepositoryUri), $HeroImgName).ToString()
    New-Object uri $BadgeImageUri
    New-Object uri $HeroImageUri

    Invoke-WebRequest -UseBasicParsing -Uri $BadgeImageUri -OutFile $BadgeImage -ErrorAction SilentlyContinue
    Invoke-WebRequest -UseBasicParsing -Uri $HeroImageUri -OutFile $HeroImage -ErrorAction SilentlyContinue
	
    #Set COM App ID > To bring a URL on button press to focus use a browser for the appid e.g. MSEdge
    #$LauncherID = "Microsoft.SoftwareCenter.DesktopToasts"
    $LauncherID = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
    #$Launcherid = "MSEdge"
	
    #Dont Create a Scheduled Task if the script is running in the context of the logged on user, only if SYSTEM fired the script i.e. Deployment from Intune/ConfigMgr
    If (([System.Security.Principal.WindowsIdentity]::GetCurrent()).Name -eq "NT AUTHORITY\SYSTEM") {
		
        #Prepare to stage Toast Notification Content in %TEMP% Folder
        Try {
			
            #Create TEMP folder to stage Toast Notification Content in %TEMP% Folder
            New-Item $ToastPath -ItemType Directory -Force -ErrorAction Continue | Out-Null
            $ToastFiles = Get-ChildItem $CurrentDir -Recurse
			
            #Copy Toast Files to Toat TEMP folder
            ForEach ($ToastFile in $ToastFiles) {
                Copy-Item (Join-Path $CurrentDir $ToastFile) -Destination $ToastPath -ErrorAction Continue
            }
        }
        Catch {
            Write-Warning $_.Exception.Message
        }
		
        #Set new Toast script to run from TEMP path
        $New_ToastPath = Join-Path -Path $ToastPath -ChildPath $ToastPSFile
		
        #Created Scheduled Task to run as Logged on User
        $Task_TimeToRun = $ToastTimeToUse
        $Task_Expiry = $ToastTimeToUse.AddSeconds(21600).ToString('s') #Task Expires after 6 hours
        $Task_Action = New-ScheduledTaskAction -Execute "C:\WINDOWS\system32\WindowsPowerShell\v1.0\PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -File ""$New_ToastPath"" -ToastGUID ""$ToastGUID"""
        $Task_Trigger = New-ScheduledTaskTrigger -Once -At $Task_TimeToRun
        $Task_Trigger.EndBoundary = $Task_Expiry
        $Task_Principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" -RunLevel Limited
        $Task_Settings = New-ScheduledTaskSettingsSet -Compatibility V1 -DeleteExpiredTaskAfter (New-TimeSpan -Seconds 600) -AllowStartIfOnBatteries
        $New_Task = New-ScheduledTask -Description "Toast_Notification_$($ToastGuid) Task for user notification. Title: $($ToastTitle) :: Event:$($ToastText) :: Source Path: $($ToastPath) " -Action $Task_Action -Principal $Task_Principal -Trigger $Task_Trigger -Settings $Task_Settings
        Register-ScheduledTask -TaskName "Toast_Notification_$($ToastGuid)" -InputObject $New_Task
    }
	
    #Run the toast if the script is running in the context of the Logged On User
    If (!(([System.Security.Principal.WindowsIdentity]::GetCurrent()).Name -eq "NT AUTHORITY\SYSTEM")) {
		
        $Log = (Join-Path $ENV:Windir "Temp\$($ToastGuid).log")
        Start-Transcript $Log

        #Enable Notifications
        #Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value 0 -ErrorAction SilentlyContinue
        #Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 1 -ErrorAction SilentlyContinue
		
        #Get logged on user DisplayName
        #Try to get the DisplayName for Domain User
        $ErrorActionPreference = "Continue"
		
        Try {
            Write-Output "Trying Identity LogonUI Registry Key for Domain User info..."
            Get-Itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "LastLoggedOnDisplayName" -ErrorAction Stop | out-null
            $User = Get-Itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "LastLoggedOnDisplayName" | Select-Object -ExpandProperty LastLoggedOnDisplayName -ErrorAction Stop | out-null
			
            If ($Null -eq $User) {
                $Firstname = $Null
            }
            else {
                $DisplayName = $User.Split(" ")
                $Firstname = $DisplayName[0]
            }
        }
        Catch [System.Management.Automation.PSArgumentException] {
            "Registry Key Property missing"
            Write-Warning "Registry Key for LastLoggedOnDisplayName could not be found."
            $Firstname = $Null
        }
        Catch [System.Management.Automation.ItemNotFoundException] {
            "Registry Key itself is missing"
            Write-Warning "Registry value for LastLoggedOnDisplayName could not be found."
            $Firstname = $Null
        }
		
        #Try to get the DisplayName for Azure AD User
        If ($Null -eq $Firstname) {
            Write-Output "Trying Identity Store Cache for Azure AD User info..."
            Try {
                $UserSID = (whoami /user /fo csv | ConvertFrom-Csv).Sid
                $LogonCacheSID = (Get-ChildItem HKLM:\SOFTWARE\Microsoft\IdentityStore\LogonCache -Recurse -Depth 2 | Where-Object { $_.Name -match $UserSID }).Name
                If ($LogonCacheSID) {
                    $LogonCacheSID = $LogonCacheSID.Replace("HKEY_LOCAL_MACHINE", "HKLM:")
                    $User = Get-ItemProperty -Path $LogonCacheSID | Select-Object -ExpandProperty DisplayName -ErrorAction Stop
                    $DisplayName = $User.Split(" ")
                    $Firstname = $DisplayName[0]
                }
                else {
                    Write-Warning "Could not get DisplayName property from Identity Store Cache for Azure AD User"
                    $Firstname = $Null
                }
            }
            Catch [System.Management.Automation.PSArgumentException] {
                Write-Warning "Could not get DisplayName property from Identity Store Cache for Azure AD User"
                Write-Output "Resorting to whoami info for Toast DisplayName..."
                $Firstname = $Null
            }
            Catch [System.Management.Automation.ItemNotFoundException] {
                Write-Warning "Could not get SID from Identity Store Cache for Azure AD User"
                Write-Output "Resorting to whoami info for Toast DisplayName..."
                $Firstname = $Null
            }
            Catch {
                Write-Warning "Could not get SID from Identity Store Cache for Azure AD User"
                Write-Output "Resorting to whoami info for Toast DisplayName..."
                $Firstname = $Null
            }
        }
		
        #Try to get the DisplayName from whoami
        If ($Null -eq $Firstname) {
            Try {
                Write-Output "Trying Identity whoami.exe for DisplayName info..."
                $User = whoami.exe
                $Firstname = (Get-Culture).textinfo.totitlecase($User.Split("\")[1])
                Write-Output "DisplayName retrieved from whoami.exe"
            }
            Catch {
                Write-Warning "Could not get DisplayName from whoami.exe"
            }
        }
		
        #If DisplayName could not be obtained, leave it blank
        If ($Null -eq $Firstname) {
            Write-Output "DisplayName could not be obtained, it will be blank in the Toast"
        }

        #Get Hour of Day and set Custom Hello
        $Hour = (Get-Date).Hour
        If ($Hour -lt 12) { $CustomHello = "Good Morning $($Firstname), $ToastTitle" }
        ElseIf ($Hour -gt 16) { $CustomHello = "Good Evening $($Firstname), $ToastTitle" }
        Else { $CustomHello = "Good Afternoon $($Firstname), $ToastTitle" }
		
        #Load Assemblies
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
		
        #Build XML ToastTemplate 
        [xml]$ToastTemplate = @"
<toast duration="$ToastDuration" scenario="alarm">
    <visual>
        <binding template="ToastGeneric">
            <text>$CustomHello</text>
            <text>$ToastText</text>
            <text placement="attribution">$Signature</text>
            <image placement="hero" src="$HeroImage"/>
            <image placement="appLogoOverride" hint-crop="circle" src="$BadgeImage"/>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:notification.default"/>
</toast>
"@
		
        #Build XML ActionTemplate 
        [xml]$ActionTemplate = @"
<toast>
    <actions>
        <action arguments="dismiss" content="Dismiss" activationType="system"/>
    </actions>
</toast>
"@
		
        #Define default actions to be added $ToastTemplate
        $Action_Node = $ActionTemplate.toast.actions
		
        #Append actions to $ToastTemplate
        [void]$ToastTemplate.toast.AppendChild($ToastTemplate.ImportNode($Action_Node, $true))
		
        #Prepare XML
        $ToastXml = [Windows.Data.Xml.Dom.XmlDocument]::New()
        $ToastXml.LoadXml($ToastTemplate.OuterXml)
		
        #Prepare and Create Toast
        $ToastMessage = [Windows.UI.Notifications.ToastNotification]::New($ToastXML)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($LauncherID).Show($ToastMessage)
		
        Stop-Transcript
    }
}
#endregion RegionName

#region ScriptRunningCode
	
Display-ToastNotification

#Endregion ScriptRunningCode