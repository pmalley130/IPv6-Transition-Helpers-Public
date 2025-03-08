##############################
#     By Patrick Malley      #
#          3/7/25            #
##############################


function Add-AddressObject { #function to add address object to a firewall
    param(
            [string]$fwfqdn, #fqdn of firewall
            [string]$objectName, #name of address object
            [string]$address, #ip address 
            [string]$vdom
        )

    if ($address.Contains(':')){ #determine if it's ipv4 or 6, set URL and API payload
            $apiURL = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/address6/?vdom=" + $vdom #set url for ipv6
            
            $body = [ordered]@{ #build data needed for object
                name=$objectName
                ip6=$address
            }
    } 
    else {
            $apiURL = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/address/?vdom=" + $vdom #set url for ipv4

            $body = [ordered]@{ #build data for IPv4, TODO: logic to parse CIDR and generate mask instead of assuming /32
                name=$objectName
                subnet=$address + " 255.255.255.255"
            }
    }

    $body.Add("comment","added by API")

    $bodyJson = $body | ConvertTo-Json #convert to format that the API can handle

    try { #make the api call
        $answer = (Invoke-RestMethod -method Post -uri $apiURL -Body $bodyJson -Headers $headers)
    } catch [System.Net.WebException] {
        $hostMSG = $apiURL + " is returning error" + $answer.status
    }
        
    return $answer.mkey + " " + $answer.status #let console know whether it succeeded
}



