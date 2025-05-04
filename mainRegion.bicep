targetScope = 'subscription'

import { _VPNSettings } from './types.bicep'

// Subscriptions
param hubSubscriptionID string
param spokeSubscriptionID string
param onPremSubscriptionID string

// Virtual Machine parameters
param adminUsername string
@secure()
param adminPassword string
param vmSizeSpoke string
param vmSizeOnPrem string
param dcrID string
@allowed([
  'Linux'
  'Windows'
])
param osTypeSpoke string
@allowed([
  'Linux'
  'Windows'
])
param osTypeOnPrem string

// Shared parameters
param AddressSpace string
param SecondRegionAddressSpace string
param location string
param shortLocationCode string
param tagsByResource object
param isMultiRegion bool

// Spoke VNET Parameters
param deploySpokes bool
param spokeRgNamePrefix string
param amountOfSpokes int
param deployVMsInSpokes bool
param deployVnetPeeringMesh bool
param deployAvnmUDRs bool
param defaultOutboundAccess bool

// Hub VNET Parameters
param deployHUB bool
@allowed([
  'VNET'
  'VWAN'
])
param hubType string
param hubRgName string
param deployBastionInHub bool
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param bastionInHubSKU string
param deployGatewayInHub bool
param deployFirewallInHub bool
@allowed([
  'Standard'
  'Premium'
])
param AzureFirewallTier string
param deployFirewallrules bool
param firewallDNSproxy bool
param deployUDRs bool
param hubBgp bool
param hubBgpAsn int

// Hub vWAN Parameters
param vWanID string
param internetTrafficRoutingPolicy bool
param privateTrafficRoutingPolicy bool

// AVNM parameters
param avnmRgName string
param avnmName string
param avnmUserAssignedIdentityId string
param deployVnetPeeringAVNM bool

// OnPrem parameters
param deployOnPrem bool
param onpremRgName string
param deployBastionInOnPrem bool
@allowed([
  'Basic'
  'Standard'
])
param bastionInOnPremSKU string
param deployVMinOnPrem bool
param deployGatewayinOnPrem bool
param deploySiteToSite bool
@secure()
param sharedKey string
param onpremBgp bool
param onpremBgpAsn int

// Create array of all Address Spaces used for site-to-site connection from Hub to OnPrem
var AllAddressSpaces = [for i in range(0, amountOfSpokes + 1): cidrSubnet(AddressSpace, 24, i)]

// set HubType variables 
var isVnetHub = hubType == 'VNET'
var isVwanHub = hubType == 'VWAN'

var varHubRgName = '${hubRgName}-${shortLocationCode}'

// Create the resource group for the hub
resource hubrg 'Microsoft.Resources/resourceGroups@2023-07-01' = if (deployHUB && isVnetHub) {
  name: varHubRgName
  location: location
  tags: tagsByResource[?'Microsoft.Resources/subscriptions/resourceGroups'] ?? {}
}

// Deploy Hub VNET including Bastion Host, Route Table, Network Security group and Azure Firewall
module hubVnet 'HubResourceGroup.bicep' = if (deployHUB && isVnetHub) {
  scope: subscription(hubSubscriptionID)
  name: '${hubRgName}-${shortLocationCode}-VNET'
  params: {
    deployBastionInHub: deployBastionInHub && isVnetHub && deployHUB
    location: location
    isMultiRegion: isMultiRegion
    shortLocationCode: shortLocationCode
    AddressSpace: AddressSpace
    hubAddressSpace: AllAddressSpaces[0]
    deployFirewallInHub: deployFirewallInHub && isVnetHub && deployHUB
    AzureFirewallTier: AzureFirewallTier
    hubRgName: deployHUB && isVnetHub ? hubrg.name : 'none'
    deployFirewallrules: deployFirewallrules && isVnetHub && deployHUB
    deployGatewayInHub: deployGatewayInHub && isVnetHub && deployHUB
    tagsByResource: tagsByResource
    AllSpokeAddressSpaces: skip(AllAddressSpaces, 1)
    SecondRegionAddressSpace: isMultiRegion ? SecondRegionAddressSpace : ''
    vpnGwBgpAsn: hubBgp ? hubBgpAsn : 65515
    vpnGwEnebaleBgp: hubBgp
    deployUDRs: deployUDRs
    bastionSku: bastionInHubSKU
    firewallDNSproxy: firewallDNSproxy && deployFirewallInHub && isVnetHub
  }
}

//  Deploy Azure vWAN with vWAN Hub and Azure Firewall
module vwan 'vWanResourceGroup.bicep' = if (deployHUB && isVwanHub) {
  scope: subscription(hubSubscriptionID)
  name: '${hubRgName}-${shortLocationCode}-VWAN'
  params: {
    location: location
    shortLocationCode: shortLocationCode
    isMultiRegion: isMultiRegion
    vWanID: vWanID
    deployFirewallInHub: deployFirewallInHub && isVwanHub
    AddressSpace: AllAddressSpaces[0]
    SecondRegionAddressSpace: isMultiRegion ? SecondRegionAddressSpace : ''
    AzureFirewallTier: AzureFirewallTier
    firewallDNSproxy: firewallDNSproxy && isVwanHub
    deployFirewallrules: deployFirewallrules && isVwanHub
    hubRgName: hubRgName
    deployGatewayInHub: deployGatewayInHub && isVwanHub
    tagsByResource: tagsByResource
    internetTrafficRoutingPolicy: internetTrafficRoutingPolicy
    privateTrafficRoutingPolicy: privateTrafficRoutingPolicy
  }
}

// Deploy Spoke VNET's including VM, Bastion Host, Route Table, Network Security group
module spokeVnets 'SpokeResourceGroup.bicep' = [
  for i in range(1, amountOfSpokes): if (deploySpokes) {
    scope: subscription(spokeSubscriptionID)
    name: '${spokeRgNamePrefix}${i}-${shortLocationCode}'
    params: {
      location: location
      shortLocationCode: shortLocationCode
      counter: i
      AddressSpace: AllAddressSpaces[i]
      adminPassword: adminPassword
      adminUsername: adminUsername
      deployVMsInSpokes: deployVMsInSpokes
      deployFirewallInHub: deployFirewallInHub && isVnetHub
      AzureFirewallpip: deployHUB && isVnetHub
        ? hubVnet.outputs.azFwIp
        : deployHUB && isVwanHub ? vwan.outputs.vWanFwIP : 'none'
      HubDeployed: deployHUB && isVnetHub
      spokeRgName: '${spokeRgNamePrefix}${i}-${shortLocationCode}'
      vmSize: vmSizeSpoke
      tagsByResource: tagsByResource
      osType: osTypeSpoke
      deployUDRs: deployAvnmUDRs ? false : deployUDRs
      firewallDNSproxy: firewallDNSproxy && deployFirewallInHub
      dcrID: dcrID ?? ''
      defaultOutboundAccess: defaultOutboundAccess
    }
  }
]

// VNET Peerings
module vnetPeerings 'VnetPeerings.bicep' = [
  for i in range(0, amountOfSpokes): if (deployHUB && deploySpokes && isVnetHub && !deployVnetPeeringAVNM) {
    name: '${hubRgName}-VnetPeering${i + 1}-${shortLocationCode}'
    params: {
      vnetIDA: deployHUB && deploySpokes && isVnetHub ? spokeVnets[i].outputs.spokeVnetID : 'No VNET peering'
      vnetIDB: deployHUB && deploySpokes && isVnetHub ? hubVnet.outputs.hubVnetID : 'No VNET peering'
      useRemoteGatewaysVnetA: deployGatewayInHub
      allowGatewayTransitVnetB: deployGatewayInHub
    }
  }
]

// VNET Peerings AVNM
module vnetPeeringsAVNM 'Avnm.bicep' = if (deployHUB && deploySpokes && isVnetHub && deployVnetPeeringAVNM) {
  scope: subscription(hubSubscriptionID)
  name: 'AVNM-${shortLocationCode}'
  params: {
    avnmName: avnmName
    userAssignedIdentityId: avnmUserAssignedIdentityId
    shortLocationCode: shortLocationCode
    avnmRgName: deployHUB && deploySpokes && isVnetHub && deployVnetPeeringAVNM ? avnmRgName : 'No Hub'
    spokeVNETids: [
      for i in range(0, amountOfSpokes): deployHUB && deploySpokes && isVnetHub && deployVnetPeeringAVNM
        ? spokeVnets[i].outputs.spokeVnetID
        : []
    ]
    hubVNETid: deployHUB && deploySpokes && isVnetHub && deployVnetPeeringAVNM ? hubVnet.outputs.hubVnetID : 'No Hub'
    useHubGateway: deployGatewayInHub
    deployVnetPeeringMesh: deployHUB && deploySpokes && isVnetHub && deployVnetPeeringAVNM && deployVnetPeeringMesh
    deployAvnmUDRs: deployHUB && deploySpokes && isVnetHub && deployVnetPeeringAVNM && deployAvnmUDRs && deployFirewallInHub
    AzFwPrivateIP: deployHUB && deploySpokes && isVnetHub && deployVnetPeeringAVNM && deployAvnmUDRs && deployFirewallInHub
      ? hubVnet.outputs.azFwIp
      : 'none'
    location: location
    tagsByResource: tagsByResource
  }
}

// VNET Connections to Azure vWAN
module vnetConnections 'vWanVnetConnections.bicep' = [
  for i in range(0, amountOfSpokes): if (deployHUB && deploySpokes && isVwanHub) {
    name: 'VWAN-VnetConnection${i + 1}-${shortLocationCode}'
    params: {
      HubResourceGroupName: deployHUB && deploySpokes && isVwanHub
        ? vwan.outputs.HubResourceGroupName
        : 'No VNET peering'
      SpokeVnetID: deployHUB && deploySpokes && isVwanHub ? spokeVnets[i].outputs.spokeVnetID : 'No VNET peering'
      vwanHubName: deployHUB && deploySpokes && isVwanHub ? vwan.outputs.vWanHubName : 'No VNET peering'
      deployFirewallInHub: deployFirewallInHub && isVwanHub
      counter: i
      hubSubscriptionID: hubSubscriptionID
      enableRoutingIntent: internetTrafficRoutingPolicy || privateTrafficRoutingPolicy
      shortLocationCode: shortLocationCode
    }
  }
]

// Deploy OnPrem VNET including VM, Bastion, Network Security Group and Virtual Network Gateway
module onprem 'OnPremResourceGroup.bicep' = if (deployOnPrem) {
  scope: subscription(onPremSubscriptionID)
  name: '${onpremRgName}-${shortLocationCode}'
  params: {
    location: location
    shortLocationCode: shortLocationCode
    adminPassword: adminPassword
    adminUsername: adminUsername
    AddressSpace: cidrSubnet(AddressSpace, 24, 255)
    deployBastionInOnPrem: deployBastionInOnPrem
    deployGatewayInOnPrem: deployGatewayinOnPrem
    deployVMsInOnPrem: deployVMinOnPrem
    OnPremRgName: onpremRgName
    vmSize: vmSizeOnPrem
    tagsByResource: tagsByResource
    osType: osTypeOnPrem
    vpnGwBgpAsn: onpremBgp ? onpremBgpAsn : 65515
    vpnGwEnebaleBgp: onpremBgp
    bastionSku: bastionInOnPremSKU
    dcrID: dcrID ?? ''
  }
}

// variable to validate if we need to deploy VPN connections
var deployVPNConnectionsVNET = deployGatewayInHub && deployGatewayinOnPrem && deploySiteToSite && isVnetHub && deployHUB

// Deploy S2s VPN from OnPrem Gateway to Hub Gateway
module s2s 'VpnConnections.bicep' = if (deployVPNConnectionsVNET) {
  name: 'VPN-s2s-Hub-to-OnPrem-${shortLocationCode}'
  params: {
    HubLocation: location
    HubRgName: deployVPNConnectionsVNET ? hubVnet.outputs.hubRgName : 'none'
    HubGatewayID: deployVPNConnectionsVNET ? hubVnet.outputs.hubGatewayID : 'none'
    HubGatewayPublicIP: deployVPNConnectionsVNET ? hubVnet.outputs.hubGatewayPublicIP : 'none'
    HubAddressPrefixes: deployVPNConnectionsVNET ? AllAddressSpaces : []
    HubLocalGatewayName: deployVPNConnectionsVNET ? 'LocalGateway-Hub-${shortLocationCode}' : 'none'
    OnPremLocation: location
    OnPremRgName: deployVPNConnectionsVNET ? onprem.outputs.OnPremRgName : 'none'
    OnPremGatewayID: deployVPNConnectionsVNET ? onprem.outputs.OnPremGatewayID : 'none'
    OnPremGatewayPublicIP: deployVPNConnectionsVNET ? onprem.outputs.OnPremGatewayPublicIP : 'none'
    OnPremAddressPrefixes: deployVPNConnectionsVNET ? array(onprem.outputs.OnPremAddressSpace) : []
    OnPremLocalGatewayName: deployVPNConnectionsVNET ? 'LocalGateway-OnPrem-${shortLocationCode}' : 'none'
    tagsByResource: tagsByResource
    enableBgp: hubBgp && onpremBgp && deployVPNConnectionsVNET
    HubBgpAsn: hubBgpAsn
    HubBgpPeeringAddress: deployVPNConnectionsVNET ? hubVnet.outputs.HubGwBgpPeeringAddress : 'none'
    OnPremBgpAsn: onpremBgpAsn
    OnPremBgpPeeringAddress: deployVPNConnectionsVNET ? onprem.outputs.OnPremGwBgpPeeringAddress : 'none'
    sharedKey: deploySiteToSite && deployVPNConnectionsVNET ? sharedKey : 'none'
    hubSubscriptionID: hubSubscriptionID
    onPremSubscriptionID: onPremSubscriptionID
  }
}

// valideate if we need to deploy VPN connections for vWAN
var deployVPNConnectionsVWAN = deployGatewayInHub && deployGatewayinOnPrem && deploySiteToSite && isVwanHub && deployHUB && deployOnPrem

// Deploy s2s VPN from OnPrem Gateway to vWan Hub Gateway
module vwans2s 'vWanVpnConnections.bicep' = if (deployVPNConnectionsVWAN) {
  name: '${hubRgName}-s2s-Hub-vWan-OnPrem-${shortLocationCode}'
  params: {
    HubLocation: location
    HubShortLocationCode: shortLocationCode
    HubRgName: deployVPNConnectionsVWAN ? hubRgName : 'none'
    vwanVpnGwInfo: deployVPNConnectionsVWAN ? vwan.outputs.vpnGwBgpIp : []
    vwanGatewayName: deployVPNConnectionsVWAN ? vwan.outputs.vpnGwName : 'none'
    vwanID: deployVPNConnectionsVWAN ? vWanID : 'none'
    vwanHubName: deployVPNConnectionsVWAN ? vwan.outputs.vWanHubName : 'none'
    HubAddressPrefixes: deployVPNConnectionsVWAN ? AllAddressSpaces : []
    HubLocalGatewayName: deployVPNConnectionsVWAN ? 'LocalGateway-Hub-${shortLocationCode}' : 'none'
    OnPremLocation: location
    OnPremShortLocationCode: shortLocationCode
    OnPremRgName: deployVPNConnectionsVWAN ? onprem.outputs.OnPremRgName : 'none'
    OnPremGatewayID: deployVPNConnectionsVWAN ? onprem.outputs.OnPremGatewayID : 'none'
    OnPremGatewayPublicIP: deployVPNConnectionsVWAN ? onprem.outputs.OnPremGatewayPublicIP : 'none'
    OnPremAddressPrefixes: deployVPNConnectionsVWAN ? array(onprem.outputs.OnPremAddressSpace) : []
    OnPremBgpPeeringAddress: deployVPNConnectionsVWAN ? onprem.outputs.OnPremGwBgpPeeringAddress : 'none'
    OnPremBgpAsn: deployVPNConnectionsVWAN ? onprem.outputs.OnPremGwBgpAsn : 65515
    tagsByResource: tagsByResource
    enableBgp: hubBgp && onpremBgp && deployVPNConnectionsVWAN
    sharedKey: deployVPNConnectionsVWAN ? sharedKey : 'none'
    hubSubscriptionID: hubSubscriptionID
    onPremSubscriptionID: onPremSubscriptionID
    deployFirewallInHub: deployFirewallInHub && deployVPNConnectionsVWAN
    isCrossRegion: false
  }
}

// Outputs
output HubRtFirewallName string = deployFirewallInHub && deployHUB && isVnetHub
  ? hubVnet.outputs.rtFirewallName
  : 'none'
output VNET_AzFwPrivateIp string = deployFirewallInHub && deployHUB && isVnetHub ? hubVnet.outputs.azFwIp : 'none'
output vWanHubID string = deployHUB && isVwanHub ? vwan.outputs.vWanHubID : 'none'
output HubVnetID string = deployHUB && isVnetHub ? hubVnet.outputs.hubVnetID : 'none'
output VpnSettings _VPNSettings = {
  Hub: deployVPNConnectionsVNET
    ? {
        type: 'VNET'
        GatewayID: deployVPNConnectionsVNET ? hubVnet.outputs.hubGatewayID : 'none'
        GatewayPublicIP: deployVPNConnectionsVNET ? hubVnet.outputs.hubGatewayPublicIP : 'none'
        AddressPrefixes: deployVPNConnectionsVNET ? AllAddressSpaces : []
        BgpAsn: hubBgpAsn
        BgpPeeringAddress: deployVPNConnectionsVNET ? hubVnet.outputs.HubGwBgpPeeringAddress : 'none'
        Location: location
        shortLocationCode: shortLocationCode
        enableBgp: hubBgp
      }
    : {
        type: 'VWAN'
        vWanID: deployVPNConnectionsVWAN ? vWanID : 'none'
        vWanHubName: deployVPNConnectionsVWAN ? vwan.outputs.vWanHubName : 'none'
        vWanGatewayName: deployVPNConnectionsVWAN ? vwan.outputs.vpnGwName : 'none'
        vwanVpnGwInfo: deployVPNConnectionsVWAN ? vwan.outputs.vpnGwBgpIp : []
        AddressPrefixes: deployVPNConnectionsVWAN ? AllAddressSpaces : []
        BgpAsn: 65515
        Location: location
        shortLocationCode: shortLocationCode
        enableBgp: hubBgp && onpremBgp && deployVPNConnectionsVWAN
        propagateToNoneRouteTable: deployFirewallInHub && deployVPNConnectionsVWAN
      }
  OnPrem: {
    type: 'VNET'
    GatewayID: deployVPNConnectionsVNET || deployVPNConnectionsVWAN ? onprem.outputs.OnPremGatewayID : 'none'
    GatewayPublicIP: deployVPNConnectionsVNET || deployVPNConnectionsVWAN
      ? onprem.outputs.OnPremGatewayPublicIP
      : 'none'
    AddressPrefixes: deployVPNConnectionsVNET || deployVPNConnectionsVWAN
      ? array(onprem.outputs.OnPremAddressSpace)
      : []
    BgpAsn: onpremBgpAsn
    BgpPeeringAddress: deployVPNConnectionsVNET || deployVPNConnectionsVWAN
      ? onprem.outputs.OnPremGwBgpPeeringAddress
      : 'none'
    Location: location
    shortLocationCode: shortLocationCode
    enableBgp: onpremBgp
  }
}
