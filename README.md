# IPv6-Transition-Helpers
Helper Powershell methods to translate IPv4 addresses and firewall policies. Home folder contains tools to be used on any computer, API folder requires access to a Fortinet firewall.

These won't be helpful to the general public, they're to be used with the addressing scheme at my own organization. We use the original IPv4 address of a device along with which physical site it resides at, which vlan it's on, and a few other identifiers to determine the address. The script assumes that there's a "subnets.json" file in the directory it's being run from - this file was born from a spreadsheet that contains all of the CIDRs from our DDI solution along with their vlan and site number. It works as a lookup key for the script.

### Convert-IPv4Address.ps1
Convert-IPv4Address takes an IPv4 address (string) and outputs its IPv6 equivalent. It has arguments -address (mandatory), -routable (in, out, infra), and -type (router, security device, L3 switch, DHCPv6, Network Device, Server Device, Other-Static). If routable and type are note supplied it assumes "out" and "server device". It accepts pipeline input. The -useDNS flag will attempt to look up the hostname and then the IPv6 record of the address. If the lookup is successful it will return the DNS version, with debug or verbose on it will warn if there is a mismatch between the translation and lookup (but still return the result of the lookup).

This file also has helper commands Get-IPv4Location (returns which site a device is in), Get-IPv4CIDR (returns which subnet it's in), Get-IPv4VLAN, and Get-IPv4SiteHex (returns the hex identifier we use for physical location).

It also contains Load-Calculator, which is needed to load the subnets.json file into memory

### Get-IPsInRange.ps1
Get-IPsInRange takes a CIDR and outputs every IP in the CIDR, but also allows you to use $array.contains($IP) to see if a specific IP is in a CIDR

### Output-PolicyAddresses.ps1
Output-PolicyAddresses takes a [PSCustomObject] firewall policy (it's literally just a json file of the REST API output when you GET a firewall policy from a Fortigate with a couple of helper functions added - see API folder) and spits out a CSV of all source and destination addresses involved in the policy, mostly used for diff and debug

## API Folder
These ones require access to the management interface of a Fortigate and a working method of API use. I use a header with the authorization token in these, saved to a global variable, $headers

### Get-Policy.ps1
Get-Policy returns a PSCustomObject of a Fortigate firewall policy with some fields and helper functions added. Requires -fwfqdn (the FQDN of the firewall), -policyNumber (the policy ID of the policy), and -vdom (the vdom the policy is in). The additions to the object are: 
- fwname for the name of the firewall it came from
- vdom for the vdom it came from
- enumerateSrc outputs all of the address objects in the source field of the policy
- enumerateDst outputs all of the address objects in the destination field of the policy

### Dualstack-Policy.ps1
Dualstack-policy accepts a firewall policy, looks at the IPv4 sources and destinations, converts all groups and objects to IPv6, and adds them to the policy. Accepts pipeline input. Requires -policy (a firewall policy object returned by Get-Policy)

### Update-PolicyAddresses.ps1
Update-PolicyAddresses updates the IPv4 and IPv6 addresses in a policy object. Note, the firewall will return an error if you add a type of address to src and not destination, i.e., an IPv6 address in src and only IPv4 addresses in dst. Requires -fwfqdn (the FQDN of the firewall), -policyid (the policy # of the firewall policy you're updating), -vdom (the vdom the policy is in), [-srcaddr, -dstaddr] (hashtable arrays of values representing the IPv4 source and destination addresses to add to the firewall, only needs "name" key) AND/OR [-srcaddr6, -dstaddr6] (hashtable arrays of values representing the IPv6 source and destination addresses to add to the firewall, only needs "name" key)

### Get-AddressObject.ps1
Get-AddressObject take the name of an IPv4 or IPv6 address object (assumes that the name contains the address itself) and returns the address object from the firewall. Requires -fwfqdn (the FQDN of the firewall), -objectName (name of the address object), and -vdom (the vdom the object is in). Returns null if object cannot be found.

### Get-AddressGroup.ps1
Get-AddressObject take the name of an IPv4 or IPv6 address group (assumes that the name contains "v6" if it's an IPv6 group) and returns the address group from the firewall. Requires -fwfqdn (the FQDN of the firewall), -objectName (name of the address object), and -vdom (the vdom the object is in). Returns null if object cannot be found.

### Get-Addresses.ps1
Get-Addresses takes the name of an IPv4 address object (or address group) and returns an array of the IP addresses. If it's actually an address group it calls Get-AddressesFromGroup. Requires -fwfqdn (the FQDN of the firewall), -address (name of the address object), and -vdom (the vdom the object is in). This is recursive and will call ALL bottom level objects.

### Get-AddressesfromGroup.ps1
Get-AddressesfromGroup is a recursive function that takes the name of an address group and will return all of the addresses used in the group in an array. It also adds the name of each group an address is a part of for later reconstruction (most likely for use in an IPv6 object to keep naming consistent). Requires -fwfqdn (the FQDN of the firewall), -addressGroup (name of the address group object), and -vdom (the vdom the object is in)

### Add-AddressObject.ps1
Add-AddressObject adds an address object to the firewall. Requires --fwfqdn (the FQDN of the firewall), -objectName (name of the new address object), -address (ip address of the new object, ipv4 or ipv6), and -vdom (the vdom the object is in)

### Add-AddressGroup.ps1
Add-AddressGroup creates an address group out of the names of address objects sent to it. Requires --fwfqdn (the FQDN of the firewall), -groupName (name of the new address object), -addresses (names of existing address objects, sent as an array: "object1","object2"), and -vdom (the vdom the object is in)

### Add-AddressObjects.ps1 
Add-AddressObjects creates address objects on the firewall out of an array of addressObjects{}. Each hashtable requires the name key for the name of the object, and either "ip6" key for an IPv6 address or "subnet" key for an IPv4 address. Requires -fwfqdn (the FQDN of the firewall), -addressObjects (the name/value pairs that make the firewall objects), and -vdom (the vdom the object is in)




