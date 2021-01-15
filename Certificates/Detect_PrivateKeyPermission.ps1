Param
(
    [Parameter(Mandatory = $False)]
    [String]$Template = "Workstation Authentication",
    [String]$Account = "LOCAL SERVICE",
    [ValidateSet("Read", "FullControl")]
    [String]$Permission = "Read"
)

#Get Client Certificate issued from the specified Template
$Certificates = Get-ChildItem Cert:\LocalMachine\my |  Where-Object { $_.HasPrivateKey } | Where-Object { $_.Extensions | Where-Object { ($_.oid.friendlyname -match "Certificate Template Information" -and ($_.Format(0) -like "*$($Template)*")) } }

#Change private key perms on Client Certificates
ForEach ($Cert in $Certificates) {

    #Format expected Subject Name on Certificate
    $ComputerName = ([System.Net.Dns]::GetHostByName(($env:computerName))).Hostname
        
    #Get the key
    $Key = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Cert)

    Try {
        #Get the permissions from the key
        $KeyPerm = $Key.key.UniqueName
        $KeyLocation = Get-ChildItem "$env:ALLUSERSPROFILE\Microsoft\Crypto" -Recurse | Where-Object { $_.Name -like "$KeyPerm*" }
        $KeyPermACL = Get-Acl -Path $KeyLocation.FullName
            
        #Check if the Account has the correct Permission on the Private Key
        $ACLAccess = $keypermacl | Select-Object -ExpandProperty AccessToString
    }
    Catch {

        #Catch error if permissions were unobtainable
        Write-Warning "Could not get the ACL: $($error[0].Exception)"
        Exit 1
    }

    If ($ACLAccess -like "*$($Account) Allow $($Permission)*") {
        Write-Output """$($Account)"" has the correct ""$($Permission)"" permission on the Certificate Private Key"
        Exit 0
    }
    else {
        Write-Warning """$($Account)"" does not have the correct ""$($Permission)"" permission on the Certificate Private Key"
        Write-Output "Setting Private Key Permission to ""$($Permission)"" for Account ""$($Account)""..."
        Exit 1
    }
}