#spits out address objects from a given policy PSCustomObject into csv - useful for diff and debug
#filename format is firewallname_vdom_policyid_source/dest
function Output-PolicyAddresses {
    param (
        [PSCustomObject]$policy
    )

    $dstfilename = $policy.fwname + "_" + $policy.vdom + "_policy_" + $policy.policyid + "_destinations.csv"
    $policy.GetDestinationAddresses() | ForEach-Object {$_} | Export-CSV -path $dstfilename

    $srcfilename = $policy.fwname + "_" + $policy.vdom + "_policy_" + $policy.policyid + "_sources.csv"
    $policy.GetSourceAddresses() | ForEach-Object {$_} | Export-CSV -path $srcfilename
}        