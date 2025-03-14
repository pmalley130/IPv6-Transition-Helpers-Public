##############################
#     By Patrick Malley      #
#          3/10/25           #
##############################

#function to dualstack an ipv4 policy - handles nested groups and objects via built-in recursive functions
#currently only works if all objects are ipv4 single hosts, no subnet or fqdn support *yet*

function Dualstack-Policy {
    param (
        [parameter(mandatory,ValueFromPipeline)] [object[]]$policy
    )

    begin {
	$IPv4Regex = "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b" #ipv4 address object contains the address and the subnet mask in the same string so need regex to grab the actual addy
    }

    process {
        $convertedObjects = @{} #lookup table for objects and groups, key is ipv4 name, value is (new) ipv6 name
        $processedGroups = @{} #groups lookup table - only needs to look up whether it's been processed or not so we'll go with key: ipv4 name 
        
    
        function Convert-AddressObject { #function to convert object
            param ([string]$objectName)

            $obj = Get-AddressObject -fwfqdn $policy.fwfqdn -objectName $objectName -vdom $policy.vdom #get object we're converting
        
            if ($obj -and -not $convertedObjects.ContainsKey($obj.name)) { #check to see if API worked and if object has been created yet, return if API failed or it's already been converted
                $s=$obj.subnet -match $IPv4Regex #regex to grab the ipv4 address out of the object
                $ipv4Addr = $matches[0]
                Write-Debug "Converting $ipv4Addr"
            
                $ipv6Addr = $ipv4addr | Convert-IPv4Address #build and create object
                $ipv6Name = "host_$ipv6Addr"
                Write-Debug "adding object $ipv6Name $ipv6Addr/128"
                Add-AddressObject -fwfqdn $policy.fwfqdn -objectName $ipv6Name -address "$ipv6Addr/128" -vdom $policy.vdom
                $convertedObjects[$obj.name] = $ipv6Name #add to lookup table - key:ipv4 objectname, value: ipv6 objectname
            } else { return }
        }

        function Convert-AddressGroup { #function to convert a group - calls itself recursively to figure out dependents if necessary
            param ([string]$groupName)

            if ($processedGroups.ContainsKey($groupName)) {return} #if it's already been created, yeet outta here

            $group = Get-AddressGroup -fwfqdn $policy.fwfqdn -groupName $groupName -vdom $policy.vdom

            if ($group) { #if the group exists on the fw
                $ipv6Members = @() #build array of ipv6 addressobjects

                foreach ($member in $group.member) { #step through each member of the group
                    if (-not $convertedObjects.ContainsKey($member.name)) { #if member hasn't been converted yet, convert it
                        Convert-AddressObject -objectName $member.name
                        Convert-AddressGroup -groupName $member.name
                    }

                    if ($convertedObjects.ContainsKey($member.name)) { #if member HAS been converted, add ipv6 version to via lookup table
                        $ipv6Members += $convertedObjects[$member.name] 
                    } else {
                        return
                    }
                }

                $ipv6GroupName = "$($group.name)_IPv6"
                Write-Debug "adding group $ipv6GroupName"
                Add-AddressGroup -fwfqdn $policy.fwfqdn -groupName $ipv6GroupName -addresses $ipv6Members -vdom $policy.vdom #add IPv6 version of group to fw
                $convertedObjects[$group.name] = $ipv6GroupName #add group to lookup tables
                $processedGroups[$group.name] = $true
            }
        }

        #convert the source address in the policy
        foreach ($addr in $policy.srcaddr) {
            Convert-AddressObject -objectName $addr.name
            Convert-AddressGroup -groupName $addr.name
        }
    
        #now the destination addresses
        foreach ($addr in $policy.dstaddr) { 
            Convert-AddressObject -objectName $addr.name
            Convert-AddressGroup -groupName $addr.name
        }

        #add converted objects to src
        $v6Src = @{}
        foreach ($addr in $policy.srcaddr) {
            if ($convertedObjects.ContainsKey($addr.name)) {
                $v6Src += @{ name = $convertedObjects[$addr.name]}
            }
        }
        Write-Debug "v6 sources:"
        Write-Debug ($v6Src | ConvertTo-Json -Depth "4")

        #same for destinations
        $v6Dst = @{}
        foreach ($addr in $policy.dstaddr) {
            if ($convertedObjects.ContainsKey($addr.name)) {
                $v6Dst += @{ name = $convertedObjects[$addr.name]}
            }
        }
        
        Write-Debug "v6 destinations:"
        Write-Debug ($v6Dst | ConvertTo-Json -Depth "4")

        Update-PolicyAddresses -fwfqdn $policy.fwfqdn -policyid $policy.policyid -srcaddr6 $v6Src -dstaddr6 $v6Dst -vdom $policy.vdom #send updated addresses to firewall
    }
}
