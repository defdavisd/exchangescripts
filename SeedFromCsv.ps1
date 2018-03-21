$path = Read-Host "Enter CSV Path"
$org = Read-Host "Enter organization"

if(Test-Path -Path $path)
{ 
    try
    {
        $boxes = import-csv -Path $path -ErrorAction Stop

        foreach($box in $boxes)
        {
            $firstname = $box.Firstname
            $lastname = $box.lastname
            $password = $box.'Password'
            $mailboxName = $box.'DisplayName'
            $UPN = $box.PrimarySmtpAddress
            $primarySmtpAddress = $box.PrimarySmtpAddress

            $alias = $primarySmtpAddress.Substring(0,$primarySmtpAddress.IndexOf("@")).Trim()

            $pwd = ConvertTo-SecureString $password -AsPlainText -Force -ErrorAction stop

            New-Mailbox -Name $mailboxName -Alias $alias -OrganizationalUnit $org -UserPrincipalName $UPN -PrimarySmtpAddress $primarysmtpaddress -FirstName $firstname -LastName $lastname -Password $pwd -ResetPasswordOnNextLogon $false -AddressBookPolicy $org -ErrorAction stop
            Sleep 10

            Set-Mailbox $primarySmtpAddress -CustomAttribute1 $org -EmailAddressPolicyEnabled $false -issuewarningquota "unlimited" -prohibitsendquota "unlimited" -prohibitsendreceivequota "unlimited"  -usedatabasequotadefaults $false -ErrorAction stop
        }
    }
    catch
    {
        write-host "An error occured. " + $_.Exception.Message
    }
}
else
{
    Write-Host "Failed to find $path"
}