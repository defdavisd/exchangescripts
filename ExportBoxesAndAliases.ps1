$filePath = read-host "Specify path to CSV file to create i.e. c:\temp\boxes.csv"

$boxes = Get-Mailbox -resultsize unlimited | ? {$_.Name -notlike 'DiscoverySearchMailbox*' -and $_.WhenCreated -gt "08/01/2017"}
$boxes | ForEach-Object {
   $recipient = get-recipient $_.PrimarySmtpAddress
   $addresses = ""
   foreach($address in $_.EmailAddresses)
   {
       $addresses += ";" + $address
   }

    New-Object -TypeName PSObject -Property @{
      Displayname = $_.DisplayName
      Firstname = $recipient.Firstname
      Lastname = $recipient.LastName
      EmailAddresses = $addresses
      Password = "Set Me"
      PrimarySmtpAddress = $_.PrimarySmtpAddress.ToString()
      }

     } | Export-CSV $filePath -NoTypeInformation -Encoding UTF8