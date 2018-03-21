#NAME: AD-AccountExpiryEmail.ps1
#DESCRIPTION: Emails users who have expiring passwords to warn them.
#AUTHOR: Jack Stevens
#MODIFIED: 13/10/2016
#VERSION: 1.1
#LAST CHANGE: Amend wording on log.
########################################

#Define variables
$logfilepath = "c:\skyetools\logs"
$logfile = Join-Path -path $logfilepath -childpath AD-AccountExpiryEmail.log
$MAXSIZE = 2097152

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


#Check password expiry, if matching send warning email
foreach ($user in $users) {
    $name = $user.GivenName
    $email = $user.EmailAddress

    $ExpiryDate = $user.PasswordLastSet + $maxage
    $DaysLeft = ($ExpiryDate - $date).days

    #Create warning email
    $WarnMessage = "
<p style='font-family:calibri'>Hi $name,</p>

<p style='font-family:calibri'>Your Windows login password will expire in <b>$DaysLeft</b> days, please change your password by clicking on Start > Windows Security > Change Password. Failure to do so in the next $DaysLeft days may result in being unable to access the system.</p>

<p style='font-family:calibri'>Requirements for the password are as follows:</p>
<ul style='font-family:calibri'>
<li>Must be at least 8 characters in length</li>
<li>Must not contain the user's account name or parts of the user's full name that exceed two consecutive characters</li>
<li>Must not be one of your last 12 passwords</li>
<li>Contain characters from three of the following four categories:</li>
<li>English uppercase characters (A through Z)</li>
<li>English lowercase characters (a through z)</li>
<li>Base 10 digits (0 through 9)</li>
<li>Non-alphabetic characters (for example, !, $, #, %)</li>
</ul>
<p style='font-family:calibri'>For any assistance, Please contact the IT Helpdesk via support@skye-cloud.com or 08450754913.<b> Please do not reply to this message.</b></a></p>

"

    #Send Email Function

    Function SendEmail {
        send-mailmessage -to $email -from $env:from -Subject "URGENT: Password Reminder - Your password will expire in $DaysLeft days" -body $WarnMessage  -smtpserver $env:smtpserver -BodyAsHtml -Priority High
    }


    if ($DaysLeft -eq "7") {
        LogWrite "User $email has $DaysLeft days until password expiry. Sending warning email."
        SendEmail
    }

    elseif ($DaysLeft -eq "3") {
        LogWrite "User $email has $DaysLeft days until password expiry. Sending warning email."
        SendEmail
    }

    elseif ($DaysLeft -eq "1") {
        LogWrite "User $email has $DaysLeft days until password expiry. Sending warning email."
        SendEmail
    }
}



