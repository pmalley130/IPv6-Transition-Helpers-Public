###########################################
#       By Patrick Malley for EPA         #
#           Original 4/24/23              #
#           Tested on 7.0.x               #
###########################################

#returns a PSCustomObject of a Firewall policy
#adds custom properties for vdom, and the firewall's name and fqdn for use in other functions
#adds functions to enumerate all source and destination objects

function Get-Policy { 
    param(
        [string]$fwfqdn, #fqdn of firewall
        [string]$policyNumber,
        [string]$vdom
    )

    $apiURL = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/policy/" + $policyNumber + "/?vdom=" + $vdom #create the API request URL

    try {#save the results of the API call or let console know there was an error
        $response = (Invoke-RestMethod -method Get -Uri $apiURL -Headers $headers).results

        #save vdom to new property
        $response | Add-Member -NotePropertyName vdom -NotePropertyValue $vdom

        #save fwfqdn to policy for future lookups
        $response | Add-member -NotePropertyName fwfqdn $fwfqdn

        #new API call to find name of firewall
        $apiURL = "https://" + $fwfqdn + "/api/v2/monitor/system/status"
        $fwname = (Invoke-RestMethod -method Get -Uri $apiURL -Headers $headers).results.hostname
        $response | Add-Member -NotePropertyName fwname -NotePropertyValue $fwname

        $enumerateSrc = { #function to grab all source objects
            $srcTable = @()
            foreach ($group in $this.srcaddr){
                if ($group.name -ne 'all') {
                    $srcTable += (Get-Addresses -fwfqdn $this.fwfqdn -address $group.name -vdom $this.vdom)
                } else {
                    $srcTable += "all"
                }
            }
            return $srcTable
        }

        $enumerateDst = { #function to grab all destination objects
            $dstTable = @()
            foreach ($group in $this.dstaddr){
                if ($group.name -ne 'all') {
                    $dstTable += (Get-Addresses -fwfqdn $this.fwfqdn -address $group.name -vdom $this.vdom)
                } else {
                    $dstTable += "all"
                }
            }
            return $dstTable
        }

        $response | Add-Member -MemberType ScriptMethod -Name GetSourceAddresses -Value $enumerateSrc
        $response | Add-Member -MemberType ScriptMethod -Name GetDestinationAddresses -Value $enumerateDst
        
    } catch [System.Net.WebException] {
        Write-Debug "$apiURL is returning an error"
        return
    }

    return $response    
}