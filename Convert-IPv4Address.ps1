########################################
#       by Patrick Malley for EPA      #
#               6/1/23                 #
########################################

#takes an ipv4 address and converts to ipv6
#if not given In/Out/Infra or Device it defaults to Out/Server
#needs subnets.json to be preloaded into $calcArray via Load-Calculator
#see readme for IP scheme explanation

function Convert-IPv4Address {
    param (
        [Parameter(Mandatory,ValueFromPipeline)][string]$address,
        [ValidateSet("In","Out","Infra")]$routable="Out",
        [ValidateSet("Router","Security Device","L3 Switch","DHCPv6","Network Device","Server Device","Other-Static")]$type = "Server Device"
    )

    process {
        #set all of the parts (except the base) to null
        $prefix = "" #routing prefix, we use a /40
        $site = $null #done
        $inOut = $null #done
        $vlan = $null #done
        $id = $null #done
        $typeID = $null #done
   
        #set the site and vlan based on our calculator array
        foreach ($network in $calcArray){ #find the subnet it belongs to and copy the values
            $checker = $network.IPs.Contains($address)
            if ($checker -eq $true) {
                $site = $network.SiteHex
                $vlan = '{0:x}' -f $network.VLAN #convert to hex
                $vlan = $vlan.ToString() #convert to string
                if ($vlan.Length -lt '3') {$vlan = "0" + $vlan} #if the VLAN hex value is two digits put a 0 in front
                break
            }
        }
    
        #set the inside outside identifier based on passed parameter, removed actual bits for security
        switch ($routable){ 
            {$_ -eq "In" } {$inOut = "5"}
            {$_ -eq "Out"} {$inOut = "5"}
            {$_ -eq "Infra" } {$inOut = "5"}
        }

        #set type identifier based on passed parameter, removed actual bits for security
        switch ($type){
            {$_ -eq "Router"} {$typeID = "5"}
            {$_ -eq "Security Device"} {$typeID = "5"}
            {$_ -eq "L3 Switch"} {$typeID = "5"}
            {$_ -eq "DHCPv6"} {$typeID = "5"}
            {$_ -eq "Network Device"} {$typeID = "5"}
            {$_ -eq "Server Device"} {$typeID = "5"}
            {$_ -eq "Other-Static"} {$typeID = "5"}
        }

        #set the host ID based on last octet
        $temp = $address -match "([0-9]+)$"
        $lastOct = [int]$matches[0]
        $id = '{0:x}' -f $lastOct
        $id = $id.ToString() #convert to string
        if ($id.Length -eq '1') {$id = "0" + $id} #if one digit add a leading 0

        #mash them together
        $IPv6Address = "" #redacted for security

        if ($useDNS) { #if -useDNS is enabled, do a DNS lookup as well
            $DNSfinal = DNS-Translate $address
            if (($DNSFinal) -and ($IPv6Address -ne $DNSfinal)) { #if DNS lookup isn't null and matches our calculated string
                Write-Debug "DNS and translation mismatched for $address, returning DNS result anyway"
                return $DNSfinal
            } elseif ($DNSfinal) { #if it returned an address and didn't hit the previous block we're good
                Write-Debug "DNS and translation match for $address"
                return $DNSfinal
            } else { #if the lookup failed we come here and return the calculated address
                Write-Debug "DNS lookup failed for $address"
                return $IPv6Address
            }
        } else { #if we don't want to look at DNS come here
            return $IPv6Address
        }
    }
}

function DNS-Translate { #goes through two DNS lookups to take a v4 and find the corresponding v6.. honestly should integrate with DDI solution's API instead
    param ([string]$address)
    
    try {
        $results = Resolve-DnsName -name $address #resolve v4 address
    } catch {
        return #return null if DNS fails
    }

    if ($results.NameHost) { #if it resolves
        try{
            $nameResults = Resolve-DnsName -name $results.NameHost #lookup hostname
        } catch {
            return #if the next one (hostname resolution) fails
        }
        foreach ($record in $nameResults) { #step through records
            if (($record.Type -eq 'AAAA') -and ((!$record.IPAddress.contains('fe80')) -and (!$record.IPAddress.contains('6464')))) { #check for AAAA record and make sure it's not link local or nat64
                return $record.IPAddress
            }
        }
    }
}

function Get-IPv4Location {
    param(
    [Parameter(Mandatory,ValueFromPipeline,Position=0)][string]$address)

    begin {
        if ($calcArray -eq $null) {
            Load-Calculator
        }
    }

    process{
        foreach ($network in $calcArray){
            $checker = $network.IPs.Contains($address)
            if ($checker -eq $true) {
                return $network.SiteID
                break
            }
        }
    }
}

function Get-IPv4CIDR {
    param(
    [Parameter(Mandatory,ValueFromPipeline,Position=0)][string]$address)

    begin {
        if ($calcArray -eq $null) {
            Load-Calculator
        }
    }

    process{
        foreach ($network in $calcArray){
            $checker = $network.IPs.Contains($address)
            if ($checker -eq $true) {
                return $network.CIDR
                break
            }
        }
    }
}

function Get-IPv4VLAN {
    param(
    [Parameter(Mandatory,ValueFromPipeline,Position=0)][string]$address)

    begin {
        if ($calcArray -eq $null) {
            Load-Calculator
        }
    }

    process{
        foreach ($network in $calcArray){
            $checker = $network.IPs.Contains($address)
            if ($checker -eq $true) {
                return $network.VLAN
                break
            }
        }
    }
}

function Get-IPv4SiteHex {
    param(
    [Parameter(Mandatory,ValueFromPipeline,Position=0)][string]$address)

    begin {
        if ($calcArray -eq $null) {
            Load-Calculator
        }
    }

    process{
        foreach ($network in $calcArray){
            $checker = $network.IPs.Contains($address)
            if ($checker -eq $true) {
                return $network.SiteHex
                break
            }
        }
    }
}

function Load-Calculator {
    $script:calcArray = Get-Content 'C:\Users\mmalley\subnets.json' | ConvertFrom-JSON
}
