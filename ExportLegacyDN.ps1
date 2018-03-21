$exportPath = read-host "Enter filepath to export data to"
$ou = read-host "Enter the OU where users are homed e.g. OU=User,DC=domain,DC=local "

Get-ADUser -SearchBase $ou -Filter * -Properties EmailAddress,legacyExchangeDN | Select-Object EmailAddress,legacyExchangeDN | Export-CSV $exportPath -NoTypeInformation