##############################
#     By Patrick Malley      #
#          3/7/25            #
##############################


function Add-AddressGroup { #function to add address group to a firewall
    param(
            [string]$fwfqdn, #fqdn of firewall
            [string]$groupName, #name of address group
            [string[]]$addresses, #array of addressobjects to be included in group
            [string]$vdom
        )

    Write-Debug "in add-addrgrp adding $groupName with "
    Write-Debug $addresses
    

    if (($addresses -match "v6") -or ($addresses -match ":")){ #determine if it's ipv4 or 6, set URL and API payload (this assumes hosts and groups are named correctly... maybe should validate with api but that's a lot)
            $apiURL = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/addrgrp6/?vdom=" + $vdom #set url for ipv6
    } 
    else {
            $apiURL = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/addrgrp/?vdom=" + $vdom #set url for ipv4
    }

    $members=@() #create an array for the address objects and fill it with separate hashtables for each 
    foreach ($address in $addresses){
        $members += @{name=$address}
    }

    $data = [ordered]@{#create the data to be sent via API (comment and color so we know the script did it)
        name=$groupName
        member=$members
        comment="added by API"
        color="20"
    }

    $dataJson = $data | ConvertTo-Json #REST API only takes json so format it
    
    try { #make the API call
        $answer = (Invoke-RestMethod -method Post -uri $apiURL -Body $dataJson -Headers $headers)
    } catch [System.Net.WebException] {
        Write-Debug "error in add-addressgroup at $apiurl"
    }
        
    return
}




