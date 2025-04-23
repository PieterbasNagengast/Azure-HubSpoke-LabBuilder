targetScope = 'subscription'

import { _VPNSettings } from './types.bicep'

// Subscriptions
@description('SubscriptionID for HUB deployemnt')
param hubSubscriptionID string

@description('SubscriptionID for Spoke deployemnt')
param spokeSubscriptionID string

@description('SubscriptionID for OnPrem deployemnt')
param onPremSubscriptionID string

// Virtual Machine parameters
@description('Admin username for Virtual Machines')
param adminUsername string

@description('Admin Password for Virtual Machines')
@secure()
param adminPassword string

@description('Spoke Virtual Machine SKU. Default = Standard_B2s')
param vmSizeSpoke string

@description('OnPrem Virtual Machine SKU. Default = Standard_B2s')
param vmSizeOnPrem string

@description('Spoke Virtual Machine(s) OS type. Windows or Linux. Default = Windows')
@allowed([
  'Linux'
  'Windows'
])
param osTypeSpoke string
@description('OnPrem Virtual Machine OS type. Windows or Linux. Default = Windows')
@allowed([
  'Linux'
  'Windows'
])
param osTypeOnPrem string

// Shared parameters
@description('IP Address space used for VNETs in deployment. Only enter a /16 subnet. Default = 172.16.0.0/16')
param AddressSpace string

@description('Second region Address space. used for AzFirewall rules')
param SecondRegionAddressSpace string

@description('Azure Region. Defualt = Deployment location')
param location string

@description('Short location code for deployment. Default = westeurope')
param shortLocationCode string

@description('Tags by resource types. Default = empty')
param tagsByResource object

@description('LogAnalytics Workspace resourceID')
param diagnosticWorkspaceId string

// Spoke VNET Parameters
@description('Deploy Spoke VNETs. Default = true')
param deploySpokes bool

@description('Spoke resource group prefix name. Default = rg-spoke')
param spokeRgNamePrefix string

@description('Amount of Spoke VNETs you want to deploy. Default = 2')
param amountOfSpokes int

@description('Deploy VM in every Spoke VNET')
param deployVMsInSpokes bool

@description('Directly connect VNET Spokes (Fully Meshed Topology)')
param deployVnetPeeringMesh bool

@description('Let Azure Virtual Network Manager manage UDRs in Spoke VNETs')
param deployAvnmUDRs bool

@description('Enable Private Subnet in Default Subnet in Spoke VNETs')
param defaultOutboundAccess bool

// Hub VNET Parameters
@description('Deploy Hub')
param deployHUB bool

@description('Deploy Hub VNET or Azuere vWAN. Default = VNET')
@allowed([
  'VNET'
  'VWAN'
])
param hubType string

@description('Virtual WAN ID')
param vWanID string

@description('Hub resource group pre-fix name. Default = rg-hub')
param hubRgName string

@description('Deploy Bastion Host in Hub VNET. Default = true')
param deployBastionInHub bool

@description('Hub Bastion SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param bastionInHubSKU string

@description('Deploy Virtual Network Gateway in Hub VNET')
param deployGatewayInHub bool

@description('Deploy Azure Firewall in Hub VNET. includes deployment of custom route tables in Spokes and Hub VNETs')
param deployFirewallInHub bool

@description('Azure Firewall Tier: Standard or Premium')
@allowed([
  'Standard'
  'Premium'
])
param AzureFirewallTier string

@description('Deploy Firewall policy Rule Collection group which allows spoke-to-spoke and internet traffic')
param deployFirewallrules bool

@description('Enable Azure Firewall DNS Proxy')
param firewallDNSproxy bool

@description('Dploy route tables (UDR\'s) to VM subnet(s) in Hub and Spokes')
param deployUDRs bool

param isMultiRegion bool

@description('Enable BGP on Hub Gateway')
param hubBgp bool

@description('Hub BGP ASN')
param hubBgpAsn int

// AVNM parameters
@description('AVNM Resource Group Name')
param avnmRgName string

@description('AVNM name')
param avnmName string

@description('User Assigned Identity ID for AVNM')
param avnmUserAssignedIdentityId string

@description('Let Azure Virtual Network Manager manage Peerings in Hub&Spoke')
param deployVnetPeeringAVNM bool

@description('Enable Azure vWAN routing Intent Policy for Internet Traffic')
param internetTrafficRoutingPolicy bool

@description('Enable Azure vWAN routing Intent Policy for Private Traffic')
param privateTrafficRoutingPolicy bool

// OnPrem parameters\
@description('Deploy Virtual Network Gateway in OnPrem')
param deployOnPrem bool

@description('OnPrem Resource Group Name')
param onpremRgName string

@description('Deploy Bastion Host in OnPrem VNET')
param deployBastionInOnPrem bool

@description('OnPrem Bastion SKU')
@allowed([
  'Basic'
  'Standard'
])
param bastionInOnPremSKU string

@description('Deploy VM in OnPrem VNET')
param deployVMinOnPrem bool

@description('Deploy Virtual Network Gateway in OnPrem VNET')
param deployGatewayinOnPrem bool

@description('Deploy Site-to-Site VPN connection between OnPrem and Hub Gateways')
param deploySiteToSite bool

@description('Site-to-Site ShareKey')
@secure()
param sharedKey string

@description('Enable BGP on OnPrem Gateway')
param onpremBgp bool

@description('OnPrem BGP ASN')
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
  name: '${hubRgName}-${location}-VNET'
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
    diagnosticWorkspaceId: diagnosticWorkspaceId
    firewallDNSproxy: firewallDNSproxy && deployFirewallInHub && isVnetHub
  }
}

//  Deploy Azure vWAN with vWAN Hub and Azure Firewall
module vwan 'vWanResourceGroup.bicep' = if (deployHUB && isVwanHub) {
  scope: subscription(hubSubscriptionID)
  name: 'VWAN-${location}-Hub'
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
    diagnosticWorkspaceId: diagnosticWorkspaceId
    internetTrafficRoutingPolicy: internetTrafficRoutingPolicy
    privateTrafficRoutingPolicy: privateTrafficRoutingPolicy
  }
}

// Deploy Spoke VNET's including VM, Bastion Host, Route Table, Network Security group
module spokeVnets 'SpokeResourceGroup.bicep' = [
  for i in range(1, amountOfSpokes): if (deploySpokes) {
    scope: subscription(spokeSubscriptionID)
    name: '${spokeRgNamePrefix}${i}-${location}'
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
      diagnosticWorkspaceId: diagnosticWorkspaceId
      firewallDNSproxy: firewallDNSproxy && deployFirewallInHub
      dcrID: deployHUB && isVnetHub
        ? hubVnet.outputs.dcrvminsightsID
        : deployHUB && isVwanHub ? vwan.outputs.dcrvminsightsID : ''
      defaultOutboundAccess: defaultOutboundAccess
    }
  }
]

// VNET Peerings
module vnetPeerings 'VnetPeerings.bicep' = [
  for i in range(0, amountOfSpokes): if (deployHUB && deploySpokes && isVnetHub && !deployVnetPeeringAVNM) {
    name: '${hubRgName}-VnetPeering${i + 1}-${location}'
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
  name: '${onpremRgName}-${location}'
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
    diagnosticWorkspaceId: diagnosticWorkspaceId
    dcrID: ''
  }
}

// dcrID: deployOnPrem && isVnetHub && deployHUB
//   ? hubVnet.outputs.dcrvminsightsID
//   : isVwanHub ? vwan.outputs.dcrvminsightsID : ''

// variable to validate if we need to deploy VPN connections
var deployVPNConnectionsVNET = deployGatewayInHub && deployGatewayinOnPrem && deploySiteToSite && isVnetHub && deployHUB

// Deploy S2s VPN from OnPrem Gateway to Hub Gateway
module s2s 'VpnConnections.bicep' = if (deployVPNConnectionsVNET) {
  name: 'VPN-s2s-Hub-to-OnPrem-${location}'
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
  name: '${hubRgName}-s2s-Hub-vWan-OnPrem-${location}'
  params: {
    HubLocation: location
    HubRgName: deployVPNConnectionsVWAN ? hubRgName : 'none'
    vwanVpnGwInfo: deployVPNConnectionsVWAN ? vwan.outputs.vpnGwBgpIp : []
    vwanGatewayName: deployVPNConnectionsVWAN ? vwan.outputs.vpnGwName : 'none'
    vwanID: deployVPNConnectionsVWAN ? vWanID : 'none'
    vwanHubName: deployVPNConnectionsVWAN ? vwan.outputs.vWanHubName : 'none'
    HubAddressPrefixes: deployVPNConnectionsVWAN ? AllAddressSpaces : []
    HubLocalGatewayName: deployVPNConnectionsVWAN ? 'LocalGateway-Hub-${shortLocationCode}' : 'none'
    OnPremLocation: location
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
  }
}

// Outputs
output HubRtFirewallName string = deployFirewallInHub && deployHUB && isVnetHub
  ? hubVnet.outputs.rtFirewallName
  : 'none'
output VNET_AzFwPrivateIp string = deployFirewallInHub && deployHUB && isVnetHub ? hubVnet.outputs.azFwIp : 'none'
output HubVnetID string = deployHUB && isVnetHub ? hubVnet.outputs.hubVnetID : 'none'
output VpnSettings _VPNSettings = deployVPNConnectionsVNET || deployVPNConnectionsVWAN
  ? {
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
            vWanID: vWanID
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
        GatewayID: deployVPNConnectionsVNET ? onprem.outputs.OnPremGatewayID : 'none'
        GatewayPublicIP: deployVPNConnectionsVNET ? onprem.outputs.OnPremGatewayPublicIP : 'none'
        AddressPrefixes: deployVPNConnectionsVNET ? array(onprem.outputs.OnPremAddressSpace) : []
        BgpAsn: onpremBgpAsn
        BgpPeeringAddress: deployVPNConnectionsVNET ? onprem.outputs.OnPremGwBgpPeeringAddress : 'none'
        Location: location
        shortLocationCode: shortLocationCode
        enableBgp: onpremBgp
      }
    }
  : {}
