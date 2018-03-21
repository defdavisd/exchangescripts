$data = import-csv -path c:\root\pwd.csv

$data

foreach($row in $data)
{
    $primarysmtpaddress = $row.Email
    $password = $row.'Password'

     	
    write-host $primarysmtpaddress $password

    $pwd = ConvertTo-SecureString $password -AsPlainText -Force -ErrorAction stop 
    Set-Mailbox -Identity $primarysmtpaddress -Password $pwd

}