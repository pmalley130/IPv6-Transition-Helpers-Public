##############################
#     By Patrick Malley      #
#          3/10/25           #
##############################

#function to PUT update a firewall policy with new v6 sources and destinations
#todo: handle v4 or v6 by GETing existing information - you cannot PUT only the new addresses, you need the existing ones as well

function Update-PolicyAddresses{
    param(
        [parameter(mandatory)][string]$fwfqdn,
        [parameter(mandatory)][string]$policyid,
        [hashtable[]]$srcaddr,
        [hashtable[]]$dstaddr,
        [hashtable[]]$srcaddr6,
        [hashtable[]]$dstaddr6,
        [parameter(mandatory)][string]$vdom
    )

    $apiURL = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/policy/" + $policyid + "?vdom=" +$vdom #build API url

    if ($srcaddr6){ #only do this if ipv6 addresses were added - can only add sources if destinations are added as well and vice versa, so no need to use OR
        $data = @{
            srcaddr6=$srcaddr6
            dstaddr6=$dstaddr6
        }
    }
    
    $dataJSON = $data | ConvertTo-Json -Depth "6" #api only accepts json

    try {#make api call
        $answer = (Invoke-RestMethod -method Put -uri $apiURL -Body $dataJson -Headers $headers)
    } catch [System.Net.WebException] {
        Write-Debug "error in Update-PolicyAddresses at $apiURL"
        return
    }
}