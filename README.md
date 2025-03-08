# IPv6-Transition-Helpers
Helper Powershell methods to translate IPv4 addresses and firewall policies. Home folder contains tools to be used on any computer, API folder requires access to a Fortinet firewall.

These won't be helpful to the general public, they're to be used with the addressing scheme at my own organization. We use the original IPv4 address of a device along with which physical site it resides at, which vlan it's on, and a few other identifiers to determine the address. It assumes that there's a "subnets.json" file in the directory it's being run from - this file was born from a spreadsheet that contains all of the CIDRs from our DDI solution along with their vlan and site number. It works as a lookup key for the script.

### Convert-IPv4Address.ps1
Convert-IPv4Address takes an IPv4 address (string) and outputs its IPv6 equivalent. It has arguments -address (mandatory), -routable (in, out, infra), and -type (router, security device, L3 switch, DHCPv6, Network Device, Server Device, Other-Static). If routable and type are note supplied it assumes "out" and "server device". It accepts pipeline input.

This file also has helper commands Get-IPv4Location (returns which site a device is in), Get-IPv4CIDR (returns which subnet it's in), Get-IPv4VLAN, and Get-IPv4SiteHex (returns the hex identifier we use for physical location).

It also contains Load-Calculator, which is needed to load the subnets.json file into memory

### Get-IPsInRange.ps1
Get-IPsInRange takes a CIDR and outputs every IP in the CIDR, but also allows you to use $array.contains($IP) to see if a specific IP is in a CIDR

### Output-PolicyAddresses.ps1
Output-PolicyAddresses takes a [PSCustomObject] firewall policy (it's literally just a json file of the REST API output when you GET a firewall policy from a Fortigate with a couple of helper functions added - see API folder) and spits out a CSV of all source and destination addresses involved in the policy, mostly used for diff and debug

## API Folder
These ones require access to the management interface of a Fortigate and a working method of API use. I use a header with the authorization token in these, saved to $headers

### Get-Addresses.ps1
Get-Addresses takes the name of an address object (or address group) and returns an array of the IP addresses. If it's actually an address group it calls Get-AddressesFromGroup. Requires -fwfqdn (the FQDN of the firewall), -address (name of the address object), and -vdom (the vdom the object is in)

### Get-AddressesfromGroup.ps1
Get-AddressesfromGroup is a recursive function that takes the name of an address group and will return all of the addresses used in the group in an array. It also adds the name of each group an address is a part of for later reconstruction (most likely for use in an IPv6 object to keep naming consistent). Requires -fwfqdn (the FQDN of the firewall), -addressGroup (name of the address group object), and -vdom (the vdom the object is in)

### Add-AddressObject.ps1
Add-AddressObject adds an address object to the firewall. Requires --fwfqdn (the FQDN of the firewall), -objectName (name of the new address object), -address (ip address of the new object, ipv4 or ipv6), and -vdom (the vdom the object is in)

### Add-AddressGroup.ps1
Add-AddressGroup creates an address group out of the names of address objects sent to it. Requires --fwfqdn (the FQDN of the firewall), -groupName (name of the new address object), -addresses (names of existing address objects, sent as an array: "object1","object2"), and -vdom (the vdom the object is in)

### Get-Policy.ps1
Get-Policy returns a PSCustomObject of a Fortigate firewall policy with some fields and helper functions added. Requires -fwfqdn (the FQDN of the firewall), -policyNumber (the policy ID of the policy), and -vdom (the vdom the policy is in). The additions to the object are:

- fwname for the name of the firewall it came from
- vdom for the vdom it came from
- enumerateSrc outputs all of the address objects in the source field of the policy
- enumerateDst outputs all of the address objects in the destination field of the policy
