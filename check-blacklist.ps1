Import-module C:\pssqlite\PSSQLite.psm1

$database = ".\blacklist.sqlite.db"

$apikey = "681abff524e713225e07b9f9e080f60e"
$baseUrl = "http://api.whoapi.com/"

$notifyapirequestsexhausted = $false

function Check-Database
{
    return Test-Path -Path $database
}

function Create-Database
{
    write-host "Create $database"

    $Query = "CREATE TABLE defaults (
        lastrun datetime,
        apirequestsremaining int,
        notifyapirequestsdepleted bit)"

    Invoke-SqliteQuery -Query $Query -DataSource $database

    $Query = "CREATE TABLE blacklistdata (
        id int PRIMARYKEY,
        domain text,
        datedetected datetime,
        ticketid text)"

    Invoke-SqliteQuery -Query $Query -DataSource $database
}


function Update-RemainingRequests
{
    Param([system.int32]$requests)

    $query = ""
    $notifydepleted = 0

    $resultset = Invoke-SqliteQuery -DataSource $database -Query "SELECT * FROM defaults"

    if($resultset -eq $null) #never inserted
    {
        $query = "INSERT INTO defaults (lastrun, apirequestsremaining,notifyapirequestsdepleted)
                     VALUES (@lastrun, '@apirequestsremaining', '@notifyapirequestsdepleted')"
    }
    else
    {
        if($resultset.apirequestsremaining -gt 0 -and $requests -eq 0)
        {
            $notifydepleted = 1
        }

        $query = "Update defaults set lastrun=@lastrun, apirequestsremaining=@apirequestsremaining, notifyapirequestsdepleted=@notifyapirequestsdepleted"
    }

    Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
            lastrun = Get-Date
            apirequestsremaining = $requests
            notifyapirequestsdepleted = $notifydepleted
    }

    if($notifydepleted)
    {
        
    }
}

function Add-NewBlacklisting
{
    Param([system.string]$domain,
          [system.string]$trackers)

    Write-Host "$domain is blacklisted! Found in databases maintained by these trackers:`n`r$trackers"

    $resultset = Invoke-SqliteQuery -DataSource $database -Query "SELECT * FROM blacklistdata where domain like '$domain'"

    if($resultset -eq $null)
    {
        #insert and raise ticket
        $ticketid = Create-Ticket -domain $domain -trackers $trackers

        if($ticketid -ne 0)
        {
            $query = "INSERT INTO blacklistdata (domain, datedetected, trackers, ticketid)
                     VALUES (@domain, @datedetected, @trackers, @ticketid)"

            Invoke-SqliteQuery -DataSource $database -Query $query -SqlParameters @{
                domain = $domain 
                datedetected = Get-Date
                trackers = $trackers
                ticketid = $ticketid
            }

            Write-Host "New Ticket Raised. Domain $domain is blacklisted."
        }
        else
        {
            Write-Host "Failed to raise ticket".
        }
    }
}    

function Create-Ticket
{
    Param([system.string]$domain,
          [system.string]$trackers)

    return 0
}

function CheckBlacklist
{
Param([System.String]$domain)
    
    #Query: http://api.whoapi.com/?apikey=681abff524e713225e07b9f9e080f60e&r=blacklist&domain=spf.co.uk
    $client = New-Object System.Net.WebClient

    Write-Host "Checking $domain ..."
   
    try
    {
        $query = $baseUrl + "?apikey=$apikey&r=blacklist&domain=$domain" 
        $response = $client.DownloadString($query)
        $data = ConvertFrom-Json $response
    }
    catch
    {
        #log error here
    }
    
    $client.Dispose()

    $data #return json object
}


##############################################################################
## APP Entry Point
##############################################################################
if(-not(Check-Database))
{
    Create-Database
}

$domains = get-accepteddomain
$requestsremaining = 0

foreach($domain in $domains)
{    
    $data = CheckBlacklist -domain $domain

    if($data -ne $null)
    {
        if($data.blacklisted -eq 1) #Oh dear. Find out where blacklisted and notify
        {
            $trackers = ""

            foreach($trackedby in $data.blacklists)
            {
                if($trackedby.blacklisted -eq 1)
                {
                    $trackers += $trackedby.tracker + [System.Environment]::NewLine
                }    
            }

            #notify blacklisting here.
            Add-NewBlacklisting -domain $domain -trackedby $trackers
        }
        else
        {
            Write-Host "$domain is not listed in any blacklist databases."
        }

        $requestsremaining = $data.requests_available
    }

    if($data.requests_available -eq 0) 
    {
        break
    } 
}

Update-RemainingRequests -requests $requestsremaining