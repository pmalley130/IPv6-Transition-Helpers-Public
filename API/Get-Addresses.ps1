###########################################
#       By Patrick Malley for EPA         #
#            Original 5/11/23             #
###########################################

function Get-Addresses { #Function to return addresses from a fw policy
    param(
        [String]$fwfqdn, #fqdn of firewall
        [string]$address,
        [string]$vdom
    )

    #we're bad and some address groups (particularly subnets) have "/" in the name - the API doesn't like this so it has to be replaced with "%2F"
    if ($address.Contains("/")){
        $addressforURL = $address.Replace('/','%2F')
    } else {
        $addressforURL = $address
    }

    $apiURL = "https://" + $fwfqdn + "api/v2/cmdb/firewall/address/" + $addressforURL + "/?vdom=" + $vdom #create URL for API call
    $response = @() #create empty array of objects

    #try to grab the address object from the api, if it does not work assume that the object is an address *group* instead of an address and grab that
    try {
        $response = (Invoke-RestMethod -method get -uri $apiURL -headers $headers).results
    } catch [System.Net.WebException] {
        $response = Get-AddressesFromGroup -addressGroup $address -vdom $vdom
    }
    return $response
}

