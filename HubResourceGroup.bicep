targetScope = 'subscription'

param location string
param shortLocationCode string
param AddressSpace string
param isMultiRegion bool
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
param SecondRegionAddressSpace string
param firewallDNSproxy bool

param vpnGwEnebaleBgp bool
param vpnGwBgpAsn int

var firewallSubnetPrefix = cidrSubnet(hubAddressSpace, 26, 0)
var bastionSubnetPrefix = cidrSubnet(hubAddressSpace, 26, 1)
var gatewaySubnetPrefix = cidrSubnet(hubAddressSpace, 26, 2)

var firewallIP = cidrHost(firewallSubnetPrefix, 3)

var bastionName = 'Bastion-Hub-${shortLocationCode}'
var rtNameVPNgwSubnet = 'RT-Hub-GatewaySubnet-${shortLocationCode}'
var hubVnetName = 'VNET-Hub-${shortLocationCode}'
var firewallName = 'Firewall-Hub-${shortLocationCode}'
var gatewayName = 'Gateway-Hub-${shortLocationCode}'
var bastionNsgName = 'NSG-Bastion-Hub-${shortLocationCode}'

// reference existing the resource group for the hub
resource hubrg 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: hubRgName
  // location: location
  // tags: tagsByResource[?'Microsoft.Resources/subscriptions/resourceGroups'] ?? {}
}

module bastioNsg 'modules/nsg.bicep' = if (deployBastionInHub) {
  scope: hubrg
  name: bastionNsgName
  params: {
    location: location
    nsgName: bastionNsgName
    isBastionNSG: true
    tagsByResource: tagsByResource
  }
}

module vnet 'modules/vnet.bicep' = {
  scope: hubrg
  name: 'hubvnet'
  params: {
    location: location
    vnetAddressSpcae: hubAddressSpace
    rtGwID: deployFirewallInHub && deployGatewayInHub ? rtvpngw.outputs.rtID : 'none'
    bastionNSGID: deployBastionInHub ? bastioNsg.outputs.nsgID : 'none'
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
    rtFwID: isMultiRegion && deployFirewallInHub && deployUDRs ? rtFirewall.outputs.rtID : 'none'
    firewallDNSproxy: firewallDNSproxy
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
    SecondRegionAddressSpace: SecondRegionAddressSpace
    isMultiRegion: isMultiRegion
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
    tagsByResource: tagsByResource
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

module rtFirewall 'modules/routetable.bicep' = if (deployFirewallInHub && deployUDRs && isMultiRegion) {
  scope: hubrg
  name: 'routeTable-FW'
  params: {
    location: location
    rtName: 'RT-Hub-FW-${shortLocationCode}'
    disableRouteProp: false
    isFirewallSubnet: true
    tagsByResource: tagsByResource
  }
}

output hubVnetID string = vnet.outputs.vnetID
output azFwIp string = deployFirewallInHub ? firewall.outputs.azFwIP : '1.2.3.4'
output hubRgName string = hubrg.name
output HubResourceGroupName string = hubrg.name
output hubVnetName string = vnet.outputs.vnetName
output hubVnetAddressSpace array = vnet.outputs.vnetAddressSpace
output hubGatewayPublicIP string = deployGatewayInHub ? vpngw.outputs.vpnGwPublicIP : 'none'
output hubGatewayID string = deployGatewayInHub ? vpngw.outputs.vpnGwID : 'none'
output HubGwBgpPeeringAddress string = deployGatewayInHub ? vpngw.outputs.vpnGwBgpPeeringAddress : 'none'
output rtFirewallName string = deployFirewallInHub && deployUDRs && isMultiRegion ? rtFirewall.outputs.rtName : 'none'
