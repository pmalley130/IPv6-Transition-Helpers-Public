###########################################
#       By Patrick Malley for EPA         #
#           Original 4/18/23              #
###########################################

function Get-AddressesFromGroup { #recursive function that accepts the name of an address group and returns all of the address objects inside of that group
    param (
        [String]$fwfqdn, #fqdn of firewall
        [String]$addressGroup,
        [String]$vdom
    )

    $apiURL = "https://" + $fwfqdn + "api/v2/cmdb/firewall/addrgrp/" + $addressGroup + "/?vdom=" + $vdom #create URL for API call
    $addressObjects = @() #create an empty array of address objects
    $response = (Invoke-RestMethod -method Get -Uri $apiURL -Headers $headers).results #query API for the members of the address object
    
    foreach ($member in $response.member) { #step through each member, if it's an address add it to the array, if it's another address group then call this same function and step through those members
        try { 
            $objectCallURL = "https://" + $fwfqdn + "api/v2/cmdb/firewall/address/" + $member.name + "/?vdom=" + $vdom #create query for the address object
            $objectCallResult = (Invoke-RestMethod -method get -uri $objectCallURL -headers $headers).results #make the query
            $objectCallResult | Add-Member -NotePropertyName ParentGroup -NotePropertyValue $addressGroup #add a value to the address object with the name of the group it belongs to
            $addressObjects += $objectCallResult #if the query made it this far then add the address object to the array to be returned
        } catch [System.Net.WebException] {
            $hostMSG = "$objectcallURL is not a valid URL, attempting to find address group with the name " + $member.name
            Write-Host $hostMSG
            $addressObjects += Get-AddressesFromGroup -addressGroup $member.name -vdom $vdom #if the script makes it here it's because the previous API call failed. it's mostly likely a 404 because the name refers to another address group and not an address object
        }
    }
    return $addressObjects #send em back
}
            