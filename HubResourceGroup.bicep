targetScope = 'subscription'

param location string
param AddressSpace string
param hubAddressSpace string
param deployBastionInHub bool
param bastionSku string
param deployFirewallInHub bool
param AzureFirewallTier string
param hubRgName string
param deployFirewallrules bool
param deployUDRs bool
param deployGatewayInHub bool
param tagsByResource object
param AllSpokeAddressSpaces array
param firewallDNSproxy bool

param vpnGwEnebaleBgp bool
param vpnGwBgpAsn int

param diagnosticWorkspaceId string

var firewallSubnetPrefix = cidrSubnet(hubAddressSpace, 26, 0)
var bastionSubnetPrefix = cidrSubnet(hubAddressSpace, 26, 1)
var gatewaySubnetPrefix = cidrSubnet(hubAddressSpace, 26, 2)

var firewallIP = cidrHost(firewallSubnetPrefix, 3)

var bastionName = 'Bastion-Hub'
var rtNameVPNgwSubnet = 'RT-Hub-GatewaySubnet'
var hubVnetName = 'VNET-Hub'
var firewallName = 'Firewall-Hub'
var gatewayName = 'Gateway-Hub'

// Create the resource group for the hub
resource hubrg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: hubRgName
  location: location
  tags: tagsByResource[?'Microsoft.Resources/subscriptions/resourceGroups'] ?? {}
}

module vnet 'modules/vnet.bicep' = {
  scope: hubrg
  name: 'hubvnet'
  params: {
    location: location
    vnetAddressSpcae: hubAddressSpace
    rtGwID: deployFirewallInHub && deployGatewayInHub ? rtvpngw.outputs.rtID : 'none'
    vnetname: hubVnetName
    bastionSubnetPrefix: bastionSubnetPrefix
    firewallSubnetPrefix: firewallSubnetPrefix
    GatewaySubnetPrefix: gatewaySubnetPrefix
    deployDefaultSubnet: false
    deployBastionSubnet: deployBastionInHub
    deployFirewallSubnet: deployFirewallInHub
    deployGatewaySubnet: deployGatewayInHub
    tagsByResource: tagsByResource
    azFwIp: firewallIP
    firewallDNSproxy: firewallDNSproxy
  }
}

module dcrvminsights 'modules/dcrvminsights.bicep' = if (!empty(diagnosticWorkspaceId)) {
  scope: hubrg
  name: 'dcr-vminsights'
  params: {
    diagnosticWorkspaceId: diagnosticWorkspaceId
    location: location
    tagsByResource: tagsByResource
  }
}

module bastion 'modules/bastion.bicep' = if (deployBastionInHub) {
  scope: hubrg
  name: 'bastion'
  params: {
    location: location
    subnetID: deployBastionInHub ? vnet.outputs.bastionSubnetID : ''
    bastionName: bastionName
    tagsByResource: tagsByResource
    bastionSku: bastionSku
  }
}

module firewall 'modules/firewall.bicep' = if (deployFirewallInHub) {
  scope: hubrg
  name: 'hubFirewall'
  params: {
    deployInVWan: false
    location: location
    firewallName: firewallName
    azfwsubnetid: deployFirewallInHub ? vnet.outputs.firewallSubnetID : ''
    azfwTier: AzureFirewallTier
    tagsByResource: tagsByResource
    firewallDNSproxy: firewallDNSproxy
  }
}

module firewallrules 'modules/firewallpolicyrules.bicep' = if (deployFirewallrules && deployFirewallInHub) {
  scope: hubrg
  name: 'firewallRules'
  params: {
    azFwPolicyName: deployFirewallInHub && deployFirewallrules ? firewall.outputs.azFwPolicyName : ''
    AddressSpace: AddressSpace
  }
}

module vpngw 'modules/vpngateway.bicep' = if (deployGatewayInHub) {
  scope: hubrg
  name: gatewayName
  params: {
    location: location
    vpnGatewayName: gatewayName
    vpnGatewaySubnetID: deployGatewayInHub ? vnet.outputs.gatewaySubnetID : ''
    tagsByResource: tagsByResource
    vpnGatewayBgpAsn: vpnGwEnebaleBgp ? vpnGwBgpAsn : 65515
    vpnGatewayEnableBgp: vpnGwEnebaleBgp
  }
}

module rtvpngw 'modules/routetable.bicep' = if (deployFirewallInHub && deployGatewayInHub && deployUDRs) {
  scope: hubrg
  name: 'routeTable-VPNGW'
  params: {
    location: location
    rtName: rtNameVPNgwSubnet
    disableRouteProp: false
  }
}

module routeVPNgw 'modules/route.bicep' = [
  for (addressRange, i) in AllSpokeAddressSpaces: if (deployFirewallInHub && deployGatewayInHub && deployUDRs) {
    scope: hubrg
    name: 'Route-vpngw${i}'
    params: {
      routeAddressPrefix: addressRange
      routeName: deployFirewallInHub && deployGatewayInHub && deployUDRs
        ? '${rtvpngw.outputs.rtName}/LocalRoute${i}'
        : 'dummy3'
      routeNextHopIpAddress: deployFirewallInHub && deployUDRs ? firewall.outputs.azFwIP : '1.2.3.4'
    }
  }
]

output hubVnetID string = vnet.outputs.vnetID
output azFwIp string = deployFirewallInHub ? firewall.outputs.azFwIP : '1.2.3.4'
output HubResourceGroupName string = hubrg.name
output hubVnetName string = vnet.outputs.vnetName
output hubVnetAddressSpace array = vnet.outputs.vnetAddressSpace
output hubGatewayPublicIP string = deployGatewayInHub ? vpngw.outputs.vpnGwPublicIP : 'none'
output hubGatewayID string = deployGatewayInHub ? vpngw.outputs.vpnGwID : 'none'
output HubGwBgpPeeringAddress string = deployGatewayInHub ? vpngw.outputs.vpnGwBgpPeeringAddress : 'none'
output dcrvminsightsID string = !empty(diagnosticWorkspaceId) ? dcrvminsights.outputs.dcrID : ''
