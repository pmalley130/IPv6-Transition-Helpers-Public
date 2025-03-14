##############################
#     By Patrick Malley      #
#          3/10/25           #
##############################

function Get-AddressGroup { #function get address group from a firewall
    param(
            [string]$fwfqdn, #fqdn of firewall
            [string]$groupName, #name of address group to grab
            [string]$vdom
        )

    $groupName = $groupName.Replace(' ','%20') #handle spaces

    if ($groupName.Contains("v6")){ #set URL based on v6 or not
        $apiURL = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/addrgrp6/" + $groupName + "/?vdom=" + $vdom
    } else {
        $apiURL = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/addrgrp/" + $groupName + "/?vdom=" + $vdom
    }

    try {
        $response = (Invoke-RestMethod -method Get -Uri $apiURL -Headers $headers).results
    } catch [System.Net.WebException] {
        Write-Debug "error in get-addressgroup at $apiURL"
        return
    }
        
    return $response
}




