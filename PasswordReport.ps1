#NAME: PasswordReport.ps1
#DESCRIPTION: Emails users who have expiring passwords to warn them.
#AUTHOR: Richard Ravenhill
#MODIFIED: 29/11/2017
#VERSION: 1.0
#LAST CHANGE: 
########################################

#Define variables
$logfilepath = "c:\skyetools\logs"
$logfile = Join-Path -path $logfilepath -childpath AD-PasswordReport.log
$MAXSIZE = 2097152

$reportPath = "c:\skyetools\report.csv"

#Define logging function
Function LogWrite {
    Param ([string]$msg)
    $now = (Get-Date).ToString()
    Add-Content $logfile "[$now]:$msg" 
}

#Check if folder and file for log exists, if not create
if (-not (Test-Path $logfilepath)) {
    New-Item $logfilepath -type directory
}

if (-not (Test-Path $logfile)) {
    New-Item $logfile -type file
}

#Prevent log file getting too big. Max 2MB.
if ((Get-Item $logfile).Length -gt $MAXSIZE) {
    Clear-Content $logfile
}

LogWrite "Starting $($MyInvocation.MyCommand.Path)"

###################################################

#Get Current Date
$date = Get-Date

#Import AD Module
Import-Module ActiveDirectory

#Define AD Account OU
$searchbase = $env:searchBase

#Get AD Max Password Age
$maxage = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.TotalDays

#Get Applicable User List
LogWrite "Getting user list..."
$users = (Get-ADUser -SearchBase $searchbase -filter {(Enabled -eq "True") -and (PasswordNeverExpires -eq "False") -and (PasswordExpired -eq "False")} -properties *) | Sort-Object pwdLastSet 

LogWrite "Processing $($users.count) users"

$data = @()
#Check password expiry, if matching send warning email
foreach ($user in $users) {
    $name = $user.GivenName
    $email = $user.EmailAddress

    $ExpiryDate = $user.PasswordLastSet + $maxage
    $DaysLeft = ($ExpiryDate - $date).days

    $pwddata = New-Object -TypeName PSObject
    $pwddata | Add-Member -Type NoteProperty -Name Name -Value $name
    $pwddata | Add-Member -Type NoteProperty -Name EmailAddress -Value $email
    $pwddata | Add-Member -Type NoteProperty -Name ExpireDate -Value $ExpiryDate
    $pwddata | Add-Member -Type NoteProperty -Name DaysLeft -Value $DaysLeft
    $pwddata | Add-Member -Type NoteProperty -Name LastLogon -Value $user.LastLogonDate 

    $data += $pwddata
}

LogWrite "Writing data to file."
$data | export-csv -Path $reportPath -NoTypeInformation

sleep -Seconds 20

try
{
    Send-MailMessage -from $env:from -To $env:To -Subject "Password Status Report" -Attachments $reportPath -SmtpServer $env:smtpserver
    LogWrite "Email sent to $env:To"
}
catch
{
    $errorMsg = $_.Exception.Message
    LogWrite "Failed to send email: $errorMsg"

}

Write-Host "PasswordReport Complete."






