<#
.SYNOPSIS
    Pop a toast notification if unsupported applications are detected
.DESCRIPTION
    This script is designed to be run as a Proactive Remediation. 
    The BadApps array contains application names that are considered unsupported by the company. The user is prompted to remove the application(s).
    If no BadApps are found, the output of the script is "No Bad Apps Found". If BadAPps are found, along with the Toast the BadAPps are written to the script output as a JSON.
    Note: The script is suitable for environments where users have the correct permissions to remove the application(s) listed.
.EXAMPLE
    Invoke-UnsupportedAppToast.ps1 (Run in the User Context)      
.NOTES
    FileName:    Invoke-UnsupportedAppToast.ps1
    Author:      Ben Whitmore
    Contributor: Jan Ketil Skanke
    Contact:     @byteben
    Created:     2022-12-Feb

    Version history:
    1.0.0 - (2022-02-12) Script released
#>

#region SCRIPTVARIABLES

$BadApps = @(
    "Adobe Shockwave Player"
    "JavaFX"
    "Java 6"
    "Java SE Development Kit 6"
    "Java(TM) SE Development Kit 6"
    "Java(TM) 6"
    "Java 7"
    "Java SE Development Kit 7"
    "Java(TM) SE Development Kit 7"
    "Java(TM) 7"
    "Adobe Flash Player"
    "Adobe Air"
)
$CustomHandlerDisplayName = "Contoso IT Company"
$CustomHandlerAppID = "CustomToastNotify"
$GoodMorning = "Good Morning"
$GoodAfternoon = "Good Afternoon"
$GoodEvening = "Good Evening"
$ToastImageSource = "https://github.com/byteben/Toast/raw/master/heroimage.jpg" #ToastImage should be  364px x 180px
$ToastImage = Join-Path -Path $ENV:temp -ChildPath "ToastImage.jpg" #ToastImageSource is downloaded to this location
$ToastDuration = "long" #ToastDuration: Short = 7s, Long = 25s
$ToastTitle = "We need to bring to your attention some important information"
$EventTitle = "Unsupported App(s) Found"
$EventText = "Please uninstall the following applications at your earliest convenience as they pose a security risk to your computer:-"
$SnoozeTitle = "Set Reminder"
$SnoozeMessage = "Remind me again in"
#endregion

#region FETCHIMAGE

$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("$ToastImageSource", "$ToastImage")
#endregion

# Function to get all Installed Applications
function Get-InstalledApplications() {
    param(
        [string]$UserSid
    )
    
    New-PSDrive -PSProvider Registry -Name "HKU" -Root HKEY_USERS | Out-Null
    $regpath = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")
    $regpath += "HKU:\$UserSid\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    if (-not ([IntPtr]::Size -eq 4)) {
        $regpath += "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $regpath += "HKU:\$UserSid\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    }
    $PropertyNames = 'DisplayName', 'DisplayVersion', 'Publisher', 'UninstallString'
    $Apps = Get-ItemProperty $regpath -Name $PropertyNames -ErrorAction SilentlyContinue | . { process { if ($_.DisplayName) { $_ } } } | Select-Object DisplayName, DisplayVersion, Publisher | Sort-Object DisplayName   
    Remove-PSDrive -Name "HKU" | Out-Null
    Return $Apps
}
#end function

#region GETSID
#Get SID of current interactive users

$CurrentLoggedOnUser = (Get-CimInstance win32_computersystem).UserName
if (-not ([string]::IsNullOrEmpty($CurrentLoggedOnUser))) {
    $AdObj = New-Object System.Security.Principal.NTAccount($CurrentLoggedOnUser)
    $strSID = $AdObj.Translate([System.Security.Principal.SecurityIdentifier])
    $UserSid = $strSID.Value
}
else {
    $UserSid = $null
}
#endregion
	
#region APPINVENTORY
#Get Apps for system and current user
$MyApps = Get-InstalledApplications -UserSid $UserSid
$UniqueApps = ($MyApps | Group-Object Displayname | Where-Object { $_.Count -eq 1 }).Group
$DuplicatedApps = ($MyApps | Group-Object Displayname | Where-Object { $_.Count -gt 1 }).Group
$NewestDuplicateApp = ($DuplicatedApps | Group-Object DisplayName) | ForEach-Object { $_.Group | Sort-Object [version]DisplayVersion -Descending | Select-Object -First 1 }
$CleanAppList = $UniqueApps + $NewestDuplicateApp | Sort-Object DisplayName

#Build App Array
$AppArray = @()
foreach ($App in $CleanAppList) {
    $tempapp = New-Object -TypeName PSObject
    $tempapp | Add-Member -MemberType NoteProperty -Name "AppName" -Value $App.DisplayName -Force
    $tempapp | Add-Member -MemberType NoteProperty -Name "AppVersion" -Value $App.DisplayVersion -Force
    $tempapp | Add-Member -MemberType NoteProperty -Name "AppPublisher" -Value $App.Publisher -Force
    $AppArray += $tempapp
}
	
$AppPayLoad = $AppArray
#endregion APPINVENTORY

#region Find Bad Apps
$BadAppFound = $Null
$BadAppArray = @()

Foreach ($App in $AppPayLoad) {
    Foreach ($BadApp in $BadApps) {
        If ($App.AppName -like "*$BadApp*") {
            $tempbadapp = New-Object -TypeName PSObject
            $tempbadapp | Add-Member -MemberType NoteProperty -Name "AppName" -Value $App.AppName -Force
            $tempbadapp | Add-Member -MemberType NoteProperty -Name "AppVersion" -Value $App.AppVersion -Force
            $tempbadapp | Add-Member -MemberType NoteProperty -Name "AppPublisher" -Value $App.AppPublisher -Force
            $BadAppArray += $tempbadapp
            $BadAppFound = $True
        }
    }
}
$BadAppPayLoad = $BadAppArray

#Update Event Text Message to include bad apps
$EventText = $EventText + "`n"
Foreach ($BadApp2 in $BadAppPayload) { 
    If ($BadApp2.AppVersion -and $BadApp2.AppPublisher) {
        $EventText = $EventText + "`n- $($BadApp2.AppName), v$($BadApp2.AppVersion) by $($BadApp2.AppPublisher)"
    }
    If (-not($BadApp2.AppVersion) -and $BadApp2.AppPublisher) {
        $EventText = $EventText + "`n- $($BadApp2.AppName) by $($BadApp2.AppPublisher)"
    }
    If (-not($BadApp2.AppVersion) -and -not($BadApp2.AppPublisher)) {
        $EventText = $EventText + "`n- $($BadApp2.AppName)"
    }
    
}
#endregion

If ($BadAppFound) {

    #region CUSTOMHANDLER
    #https://docs.microsoft.com/en-us/windows/apps/design/shell/tiles-and-notifications/send-local-toast-other-apps
    $CustomToastNotifyRegKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\$CustomHandlerAppID"
    $CustomHandlerClassRegKey = "HKCU:\Software\Classes\AppUserModelId"

    Try {
        If (!(Test-Path -Path $CustomToastNotifyRegKey)) {
            New-Item -Path $CustomToastNotifyRegKey -Force | Out-Null
            New-ItemProperty -Path $CustomToastNotifyRegKey -Name "ShowInActionCenter" -Value 1 -PropertyType DWORD -Force | Out-Null
        }
    }
    Catch { 
        $_.Exception.Message 
    }

    Try {
        If (!(Test-Path -Path $CustomHandlerClassRegKey)) {
            New-Item -Path $CustomHandlerClassRegKey -Name $CustomHandlerAppID -Force | Out-Null
            New-ItemProperty -Path $CustomHandlerClassRegKey\$CustomHandlerAppID -Name "DisplayName" -Value $CustomHandlerDisplayName -PropertyType String -Force | Out-Null
            New-ItemProperty -Path $CustomHandlerClassRegKey\$CustomHandlerAppID -Name "ShowInSettings" -Value 0 -PropertyType DWORD -Force | Out-Null
        }
    }
    Catch { 
        $_.Exception.Message 
    }

    Try {
        If ((Get-ItemProperty -Path $CustomHandlerClassRegKey\$CustomHandlerAppID -Name "DisplayName" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DisplayName -ErrorAction SilentlyContinue) -ne $CustomHandlerDisplayName) {
            New-ItemProperty -Path $CustomHandlerClassRegKey\$CustomHandlerAppID -Name "DisplayName" -Value $CustomHandlerDisplayName -PropertyType String -Force | Out-Null
        }
    }
    Catch {
        $_.Exception.Message
    }
    #endregion

    #region TOAST
    #Get Hour of Day and set Custom Hello
    $Hour = (Get-Date).Hour
    If ($Hour -lt 12) { $CustomHello = $GoodMorning }
    ElseIf ($Hour -gt 16) { $CustomHello = $GoodEvening }
    Else { $CustomHello = $GoodAfternoon }

    #Load Assemblies
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

    #Build XML ToastTemplate 
    [xml]$ToastTemplate = @"
<toast duration="$ToastDuration" scenario="reminder">
    <visual>
        <binding template="ToastGeneric">
            <text>$CustomHello</text>
            <text>$ToastTitle</text>
            <image placement="hero" src="$ToastImage"/>
            <group>
                <subgroup>
                    <text hint-style="title" hint-wrap="true" >$EventTitle</text>
                </subgroup>
            </group>
            <group>
                <subgroup>
                    <text hint-style="body" hint-wrap="true" >$EventText</text>
                </subgroup>
            </group>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:notification.default"/>
    <actions>
        <input id="SnoozeTimer" type="selection" title="$SnoozeMessage" defaultInput="1">
            <selection id="1" content="1 Minute"/>
            <selection id="30" content="30 Minutes"/>
            <selection id="60" content="1 Hour"/>
            <selection id="120" content="2 Hours"/>
            <selection id="240" content="4 Hours"/>
        </input>
        <action activationType="system" arguments="snooze" hint-inputId="SnoozeTimer" content="$SnoozeTitle" id="test-snooze"/>
        <action arguments="dismiss" content="Dismiss" activationType="system"/>
    </actions>
</toast>
"@

    #Prepare XML
    $ToastXml = [Windows.Data.Xml.Dom.XmlDocument]::New()
    $ToastXml.LoadXml($ToastTemplate.OuterXml)
    
    #Prepare and Create Toast
    $ToastMessage = [Windows.UI.Notifications.ToastNotification]::New($ToastXML)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($CustomHandlerAppID).Show($ToastMessage)
    #endregion

    #Write-Output for Proactive Remediation
    $BadAppPayLoadOutput = $BadAppPayLoad | ConvertTo-Json
    Write-Output $BadAppPayLoadOutput
    Exit 0
}
else {
    Write-Output "No Bad Apps Found"
    Exit 0
}