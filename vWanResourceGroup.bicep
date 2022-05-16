targetScope = 'subscription'

param location string
param AddressSpace string
param deployFirewallInHub bool
param AzureFirewallTier string
param hubRgName string
param deployFirewallrules bool
param deployGatewayInHub bool
param tagsByResource object
// param AllSpokeAddressSpaces array
param vWanName string = 'vWAN01'


var vnetAddressSpace = replace(AddressSpace, '/16', '/24')

resource hubrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hubRgName
  location: location
}

module vwan 'modules/vwan.bicep' = {
  scope: hubrg
  name: vWanName
  params: {
    AddressPrefix: vnetAddressSpace
    location: location
    vWanName: vWanName
    AzureFirewallTier: AzureFirewallTier
    deployFirewallInHub: deployFirewallInHub
    tagsByResource: tagsByResource
    deployGatewayInHub: deployGatewayInHub
  }
}

module vwanFwPolicyRules 'modules/firewallpolicyrules.bicep' = if (deployFirewallrules) {
  scope: hubrg
  name: 'firewallrules'
  params: {
    AddressSpace: AddressSpace
    azFwPolicyName: deployFirewallInHub ? vwan.outputs.azFwPolicyName : ''
  }
}
