$Groups = Get-DistributionGroup -resultsize unlimited
$Groups | ForEach-Object {
$group = $_.Name
$members = ''
Get-DistributionGroupMember $_.PrimarySmtpAddress | ForEach-Object {
        If($members) {
              $members=$members + ";" + $_.PrimarySmtpAddress.ToString() 
           } Else {
              $members=$_.PrimarySmtpAddress.ToString()
           }
  }
New-Object -TypeName PSObject -Property @{
      GroupName = $group
      PrimarySmtpAddress = $_.PrimarySmtpAddress.ToString()
      AllowExternal = $_.RequireSenderAuthentication
      Members = $members

     }
} | Export-CSV "C:\temp\Distribution-Group-Members.csv" -NoTypeInformation -Encoding UTF8