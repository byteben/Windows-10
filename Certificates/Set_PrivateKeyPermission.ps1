
<#	
===========================================================================
	 Created on:   	14/01/2021 23:06
	 Created by:   	Ben Whitmore
	 Organization: 	-
	 Filename:     	Set_PrivateKeyPermission.ps1
	 Target System: Windows 10 Only
===========================================================================

1.0 
Release

.SYNOPSIS
The purpose of the script is to change the Private Key Permission on a computer certificate issued from a specific template.

.DESCRIPTION
This script can be used to add/change an account permissions on a certificates private key when the certificate has been issued using a specific template.

.Parameter Template
Specify the name of the template used to issue the certificate

.Parameter Account
Specify the account you wish to add/change on the private key ACL. The default account will be set to "LOCAL SERVICE" if no parameter is specified

.Parameter Permission
Specify the permission you would like to set. Choose "Read" or "FullControl"

.Example
Set_PrivateKeyPermission.ps1 -Account "LOCAL SERVICE" -Permission "Read" -Template "Workstation Authentication EAP-TLS"
#>

Param
(
    [Parameter(Mandatory = $False)]
    [String]$Template = "Workstation Authentication EAP-TLS",
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
    }

    If ($ACLAccess -like "*$($Account) Allow $($Permission)*") {
        Write-Output """$($Account)"" has the correct ""$($Permission)"" permission on the Certificate Private Key"
    }
    else {
        Write-Warning """$($Account)"" does not have the correct ""$($Permission)"" permission on the Certificate Private Key"
        Write-Output "Setting Private Key Permission to ""$($Permission)"" for Account ""$($Account)""..."
        Try {

            #Create a new permission
            $NewPerm = New-Object security.accesscontrol.filesystemaccessrule $Account, $Permission, Allow

            #Add the new permission to the ACL
            $KeyPermACL.AddAccessRule($NewPerm)
            Set-Acl -Path $KeyLocation.FullName -AclObject $KeyPermACL
        }
        Catch {

            #Catch the error
            Write-Warning "Error modifying the private key ACL: $($error[0].Exception)"
        }
    }
}