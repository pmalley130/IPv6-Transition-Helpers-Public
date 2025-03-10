##############################
#     By Patrick Malley      #
#          3/8/25            #
##############################

#TODO - add pipeline, add debug and verbose

function Add-AddressObjects { #function to add address objects to a firewall, using array of hashtables
    param(
            [string]$fwfqdn, #fqdn of firewall
            [hashtable[]]$addressObjects, #address object to be added, needs name and subnet for v4, name and ip6 for v4
            [string]$vdom
        )

    $v4Objects=@() #make blank arrays for v4 and v6
    $v6Objects=@()

    foreach ($addressObject in $addressObjects){ #cycle through all objects and add them to respective arrays based on IP version
        if ($addressObject.containsKey('ip6')) { $v6Objects += $addressObject }
        elseif ($addressObject.containsKey('subnet')) {$v4Objects +=$addressObjects}
        else { Write-Host $addressObject.name + "is invalid" }
    }

    if ($v4Objects) { #if v4 array isn't empty then push to fw
        $apiUrl = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/address/?vdom=" + $vdom
        $body = $v4Objects | ConvertTo-Json
        try { #make the api call
            $answer = (Invoke-RestMethod -method Post -uri $apiURL -Body $body -Headers $headers)
        } catch [System.Net.WebException] {
            $hostMSG = $apiURL + " is returning error" + $answer.status
        }
    }

    if ($v6Objects) {
        $apiURL = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/address6/?vdom=" + $vdom
        $body = $v6Objects | ConvertTo-Json
        try { #make the api call
            $answer = (Invoke-RestMethod -method Post -uri $apiURL -Body $body -Headers $headers)
        } catch [System.Net.WebException] {
            $hostMSG = $apiURL + " is returning error" + $answer.status
        }
    }

    #TODO - add logic for -debug flag here to use get-address to validate each object
}



