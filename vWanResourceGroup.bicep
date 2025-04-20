targetScope = 'subscription'

param location string
param shortLocationCode string
param vWanID string
param AddressSpace string
param deployFirewallInHub bool
param AzureFirewallTier string
param hubRgName string
param deployFirewallrules bool
param deployGatewayInHub bool
param tagsByResource object = {}
param firewallDNSproxy bool
param diagnosticWorkspaceId string
param internetTrafficRoutingPolicy bool
param privateTrafficRoutingPolicy bool

// var vWanName = 'vWAN'
var firewallName = 'Firewall-Hub-${shortLocationCode}'
var gatewayName = 'Gateway-Hub-${shortLocationCode}'
var vwanHubName = 'HUB-${shortLocationCode}'

// Reference existing the resource group for the hub
resource hubrg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: hubRgName
}

// Deploy vWan and vWan Hub
module vwanHub 'modules/vwanhub.bicep' = {
  scope: hubrg
  name: vwanHubName
  params: {
    HubName: vwanHubName
    AddressPrefix: AddressSpace
    location: location
    tagsByResource: tagsByResource
    vWanID: vWanID
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
    vWanID: vwanHub.outputs.ID
    location: location
    tagsByResource: tagsByResource
    firewallDNSproxy: firewallDNSproxy
  }
}

// If Azure Firewall deployed in vWan Hub AND Firewall policy rules is selected
module firewallrules 'modules/firewallpolicyrules.bicep' = if (deployFirewallrules && deployFirewallInHub) {
  scope: hubrg
  name: 'firewallRules-${shortLocationCode}'
  params: {
    azFwPolicyName: deployFirewallInHub && deployFirewallrules ? AzFirewall.outputs.azFwPolicyName : 'none'
    AddressSpace: AddressSpace
  }
}

// If Azure Firewall deployed in vWan Hub: Add routes to default route table in vWan Hub for all RFC1918 address spaces + default route to Azure Firewall
module vwanRouteTable 'modules/vwanhubroutes.bicep' = {
  scope: hubrg
  name: 'routeTable-${shortLocationCode}'
  params: {
    vwanHubName: vwanHub.outputs.Name
    AzFirewallID: deployFirewallInHub ? AzFirewall.outputs.azFwID : 'none'
    deployFirewallInHub: deployFirewallInHub
    internetTrafficRoutingPolicy: internetTrafficRoutingPolicy
    privateTrafficRoutingPolicy: privateTrafficRoutingPolicy
  }
}

module vpngateway 'modules/vwanvpngateway.bicep' = if (deployGatewayInHub) {
  scope: hubrg
  name: gatewayName
  params: {
    location: location
    vpnGwName: gatewayName
    vWanHubID: vwanHub.outputs.ID
  }
}

module dcrvminsights 'modules/dcrvminsights.bicep' = if (!empty(diagnosticWorkspaceId)) {
  scope: hubrg
  name: 'dcr-vminsights-${shortLocationCode}'
  params: {
    diagnosticWorkspaceId: diagnosticWorkspaceId
    location: location
    tagsByResource: tagsByResource
  }
}

output vWanHubName string = vwanHub.outputs.Name
output HubResourceGroupName string = hubrg.name
output vWanFwIP string = deployFirewallInHub ? AzFirewall.outputs.azFwIP : 'none'
output vpnGwBgpIp array = deployGatewayInHub ? vpngateway.outputs.vpnGwBgpIp : []
output vpnGwName string = deployGatewayInHub ? vpngateway.outputs.vpnGwName : 'none'
output dcrvminsightsID string = !empty(diagnosticWorkspaceId) ? dcrvminsights.outputs.dcrID : 'none'
