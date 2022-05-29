targetScope = 'subscription'

param location string
param AddressSpace string
param deployFirewallInHub bool
param AzureFirewallTier string
param hubRgName string
param deployFirewallrules bool
param deployGatewayInHub bool
param tagsByResource object = {}

var vnetAddressSpace = replace(AddressSpace, '/16', '/24')

var vWanName = 'vWAN'
var firewallName = 'Firewall-Hub'
var gatewayName = 'Gateway-Hub'

resource hubrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hubRgName
  location: location
}

// Deploy vWan and vWan Hub
module vwan 'modules/vwan.bicep' = {
  scope: hubrg
  name: vWanName
  params: {
    AddressPrefix: vnetAddressSpace
    location: location
    vWanName: vWanName
    tagsByResource: tagsByResource
  }
}

// If Azure Firewall deployed in vWan Hub
module AzFirewall 'modules/firewall.bicep' = if (deployFirewallInHub) {
  scope: hubrg
  name: firewallName
  params: {
    deployInVWan: true
    azfwTier: AzureFirewallTier 
    firewallName: firewallName
    vWanID: vwan.outputs.vWanHubID
    location: location
    tagsByResource: tagsByResource
  }
}

// If Azure Firewall deployed in vWan Hub AND Firewall policy rules is selected
module firewallrules 'modules/firewallpolicyrules.bicep' = if (deployFirewallrules && deployFirewallInHub) {
  scope: hubrg
  name: 'firewallRules'
  params: {
    azFwPolicyName: deployFirewallInHub && deployFirewallrules ? AzFirewall.outputs.azFwPolicyName : 'none'
    AddressSpace: AddressSpace
  }
}

// If Azure Firewall deployed in vWan Hub: Add routes to default route table in vWan Hub for all RFC1918 address spaces + default route to Azure Firewall
module vwanSecureRoutes 'modules/vwanhubsecureroutes.bicep' = if (deployFirewallInHub) {
  scope: hubrg
  name: 'secureRoutes'
  params: {
    vwanHubName: vwan.outputs.vWanHubName
    AzFirewallID: deployFirewallInHub ? AzFirewall.outputs.azFwID : 'none'
  }
}

module vpngateway 'modules/vwanvpngateway.bicep' = if (deployGatewayInHub) {
  scope: hubrg
  name: gatewayName
  params: {
    location: location
    vpnGwName: gatewayName
    vWanHubID: vwan.outputs.vWanHubID
  }
}

output vwanHubName string = vwan.outputs.vWanHubName
output vWanHubID string = vwan.outputs.vWanHubID
output vWanID string = vwan.outputs.vWanID
output vWanHubAddressSpace string = vwan.outputs.vWanHubAddressSpace
output HubResourceGroupName string = hubrg.name
output vWanVpnGwID string = vpngateway.outputs.vpnGwID
output vWanVpnGwPip array = vpngateway.outputs.vpnGwPip
output vWanFwPublicIP array = AzFirewall.outputs.azFwIPvWan
output vpnGwBgpIp array = vpngateway.outputs.vpnGwBgpIp
output vpnGwBgpAsn int = vpngateway.outputs.vpnGwBgpAsn
