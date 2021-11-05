

$PublicIP_URI = 'http://ifconfig.me/ip'
$GEO_URI = 'http://ipinfo.io/'

Write-Host "--------------Testing GEO URL's--------------" -ForegroundColor Cyan
Write-Host "` "

function TestURL($URL) {
    Try {
        $Request = [System.Net.WebRequest]::Create($URL)
        $Response = $Request.getResponse()

        If ($Response.StatusCode -eq 'OK') {
            Write-Host "$URL is accessible." -ForegroundColor green
            $Return_Response = "OK"
        }
        Else {
            Write-Warning "$URL is not accessible. Site may be down."
            $Return_Response = "Failed"
        }
    }
    Catch {
        Write-Warning "$URL is not accessible. Site may be down."
        $Return_Response = "Failed"
    }
    Return $Return_Response
}
If (((TestURL $PublicIP_URI) -eq "OK") -and ((TestURL $GEO_URI) -eq "OK")) {

    $MY_GEO = Invoke-RestMethod -Uri ($GEO_URI + (Invoke-WebRequest -uri $PublicIP_URI).Content)

    $MY_IP = $MY_GEO.ip
    $MY_City = $MY_GEO.city
    $MY_Region = $MY_GEO.region
    $MY_Country = $MY_GEO.country
    $MY_LOC = $MY_GEO.loc
    $MY_ISP = $MY_GEO.org
    Write-Host "` "
    Write-Host "--------------Geolocation information--------------" -ForegroundColor Cyan
    Write-Host "` "
    Write-Output "IP Address: $MY_IP"
    Write-Output "City: $MY_City"
    Write-Output "Region: $MY_Region"
    Write-Output "Country: $MY_Country"
    Write-Output "Coordinates: $MY_LOC"
    Write-Output "ISP: $MY_ISP"
    Write-Host "` "
}
else {
    Write-Warning "Could not obtain GEO information. URL(s) inaccessible."
}


