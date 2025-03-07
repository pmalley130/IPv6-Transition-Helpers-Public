###########################################
#       By Patrick Malley for EPA         #
#           Original 4/24/23              #
#           Tested on 7.0.x               #
###########################################

function Get-Policy { #returns a PSCustomObject of a Firewall policy
    param(
        [string]$fwfqdn, #fqdn of firewall
        [string]$policyNumber, #policy ID
        [string]$vdom #vdom name
    )

    $apiURL = "https://" + $fwfqdn + "/api/v2/cmdb/firewall/policy/" + $policyNumber + "/?vdom=" + $vdom #create the API request URL

    try {#save the results of the API call or let console know there was an error
        $response = (Invoke-RestMethod -method Get -Uri $apiURL -Headers $headers).results

        #save vdom to new property
        $response | Add-Member -NotePropertyName vdom -NotePropertyValue $vdom

        #new API call to find name of firewall and save to new property
        $apiURL = "https://" + $fwfqdn + "/api/v2/monitor/system/status"
        $fwname = (Invoke-RestMethod -method Get -Uri $apiURL -Headers $headers).results.hostname
        $response | Add-Member -NotePropertyName fwname -NotePropertyValue $fwname

        $enumerateSrc = {
            $srcTable = @()
            foreach ($group in $this.srcaddr){
                if ($group.name -ne 'all') {
                    $srcTable += Get-Addresses -address $group.name -vdom $this.vdom
                } else {
                    $srcTable += "all"
                }
            }
            return $srcTable
        }

        $enumerateDst = {
            $dstTable = @()
            foreach ($group in $this.dstaddr){
                if ($group.name -ne 'all') {
                    $dstTable += Get-Addresses -address $group.name -vdom $this.vdom
                } else {
                    $dstTable += "all"
                }
            }
            return $dstTable
        }

        $response | Add-Member -MemberType ScriptMethod -Name GetSourceAddresses -Value $enumerateSrc
        $response | Add-Member -MemberType ScriptMethod -Name GetDestinationAddresses -Value $enumerateDst
        
    } catch [System.Net.WebException] {
        $hostMSG = $apiURL + " is returning an error"
        Write-Host $hostMSG
    }

    return $response    
}