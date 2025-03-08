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

    
    if ($addresses[0].Contains(':')){ #determine if it's ipv4 or 6, set URL and API payload
            $apiURL = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/addrgrp6/?vdom=" + $vdom #set url for ipv6
    } 
    else {
            $apiURL = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/addrgrp/?vdom=" + $vdom #set url for ipv4
    }

    $members=@() #create an array for the address objects and fill it with separate hashtables for each 
    foreach ($address in $addresses){
        $members += @{name=$address}
    }

    $data = [ordered]@{#create the data to be sent via API
        name="API test"
        member=$members
    }

    $dataJson = $data | ConvertTo-Json #REST API only takes json so format it
    
    try { #make the API call
        $answer = (Invoke-RestMethod -method Post -uri $apiURL -Body $dataJson -Headers $headers)
    } catch [System.Net.WebException] {
        $hostMSG = $apiURL + " is returning error" + $answer.status
    }
        
    return $answer.mkey + " " + $answer.status #let console know whether it succeeded
}




