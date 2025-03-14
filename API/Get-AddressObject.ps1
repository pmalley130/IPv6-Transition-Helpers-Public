##############################
#     By Patrick Malley      #
#          3/10/25           #
##############################

function Get-AddressObject { #function get address group from a firewall
    param(
            [string]$fwfqdn, #fqdn of firewall
            [string]$objectName, #name of address object to grab
            [string]$vdom
        )

    $objectName = $objectName.Replace(' ','%20') #it's being sent to a URI so handle things that URIs hate
    
    if ($objectName.Contains(":")){ #v6 address
        $objectName = $objectName.Replace('/','%3A')
        $apiURL = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/address6/" + $objectName + "/?vdom=" + $vdom
    } else {
        $objectName = $objectName.Replace('/','%2F') #v4 address
        $apiURL = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/address/" + $objectName + "/?vdom=" + $vdom
    }

    try {
        $response = (Invoke-RestMethod -method Get -Uri $apiURL -Headers $headers).results
    } catch [System.Net.WebException] {
        Write-Debug "error in get-addressobject at $apiURL"
        return
    }
    
    return $response
}




