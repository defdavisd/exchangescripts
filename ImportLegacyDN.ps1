 $filePath = read-host "Enter CSV filepath"
   
   if(Test-Path -path $filePath)
   {
      $Input = Import-CSV $filePath
      
      Write-Host "Processing $($Input.count) x500 Addresses" -foregroundcolor Green
     
      ForEach ($row in $Input)
      {
          if($row.legacyExchangeDN)
          {
	     $mb = get-mailbox $row.EmailAddress
             $user = get-aduser $mb.samAccountName

	     $x500Address = $($row.legacyExchangeDN)
	     
             Write-Host "Adding $x500Address to $($user.samAccountName)" -Foregroundcolor Green
	     
             Set-ADUser -Identity $user -add @{proxyAddresses="X500:$x500Address"}
   	  }
      }
    }