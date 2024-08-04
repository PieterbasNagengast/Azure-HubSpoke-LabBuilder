targetScope = 'subscription'

// Subscriptions
@description('SubscriptionID for HUB deployemnt')
param hubSubscriptionID string = subscription().subscriptionId

@description('SubscriptionID for Spoke deployemnt')
param spokeSubscriptionID string = subscription().subscriptionId

@description('SubscriptionID for OnPrem deployemnt')
param onPremSubscriptionID string = subscription().subscriptionId

// Virtual Machine parameters
@description('Admin username for Virtual Machines')
param adminUsername string

@description('Admin Password for Virtual Machines')
@secure()
param adminPassword string

@description('Spoke Virtual Machine SKU. Default = Standard_B2s')
param vmSizeSpoke string = 'Standard_B2s'

@description('OnPrem Virtual Machine SKU. Default = Standard_B2s')
param vmSizeOnPrem string = 'Standard_B2s'

@description('Spoke Virtual Machine(s) OS type. Windows or Linux. Default = Windows')
@allowed([
  'Linux'
  'Windows'
])
param osTypeSpoke string = 'Windows'
@description('OnPrem Virtual Machine OS type. Windows or Linux. Default = Windows')
@allowed([
  'Linux'
  'Windows'
])
param osTypeOnPrem string = 'Windows'

// Shared parameters
@description('IP Address space used for VNETs in deployment. Only enter a /16 subnet. Default = 172.16.0.0/16')
param AddressSpace string = '172.16.0.0/16'

@description('Azure Region. Defualt = Deployment location')
param location string = deployment().location

@description('Tags by resource types')
param tagsByResource object = {}

@description('LogAnalytics Workspace resourceID')
param diagnosticWorkspaceId string = ''

// Spoke VNET Parameters
@description('Deploy Spoke VNETs')
param deploySpokes bool = true

@description('Spoke resource group prefix name')
param spokeRgNamePrefix string = 'rg-spoke'

@description('Amount of Spoke VNETs you want to deploy. Default = 2')
param amountOfSpokes int = 2

@description('Deploy VM in every Spoke VNET')
param deployVMsInSpokes bool = false

@description('Directly connect VNET Spokes (Fully Meshed Topology)')
param deployVnetPeeringMesh bool = false

// Hub VNET Parameters
@description('Deploy Hub')
param deployHUB bool = true

@description('Deploy Hub VNET or Azuere vWAN')
@allowed([
  'VNET'
  'VWAN'
])
param hubType string = 'VNET'

@description('Hub resource group pre-fix name')
param hubRgName string = 'rg-hub'

@description('Deploy Bastion Host in Hub VNET')
param deployBastionInHub bool = true

@description('Hub Bastion SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param bastionInHubSKU string = 'Basic'

@description('Deploy Virtual Network Gateway in Hub VNET')
param deployGatewayInHub bool = true

@description('Deploy Azure Firewall in Hub VNET. includes deployment of custom route tables in Spokes and Hub VNETs')
param deployFirewallInHub bool = true

@description('Azure Firewall Tier: Standard or Premium')
@allowed([
  'Standard'
  'Premium'
])
param AzureFirewallTier string = 'Standard'

@description('Deploy Firewall policy Rule Collection group which allows spoke-to-spoke and internet traffic')
param deployFirewallrules bool = true

@description('Enable Azure Firewall DNS Proxy')
param firewallDNSproxy bool = false

@description('Dploy route tables (UDR\'s) to VM subnet(s) in Hub and Spokes')
param deployUDRs bool = true

@description('Enable BGP on Hub Gateway')
param hubBgp bool = false

@description('Hub BGP ASN')
param hubBgpAsn int = 65515

@description('Let Azure Virtual Network Manager manage Peerings in Hub&Spoke')
param deployVnetPeeringAVNM bool = false

@description('Enable Azure vWAN routing Intent Policy for Internet Traffic')
param internetTrafficRoutingPolicy bool = false

@description('Enable Azure vWAN routing Intent Policy for Private Traffic')
param privateTrafficRoutingPolicy bool = false

// OnPrem parameters\
@description('Deploy Virtual Network Gateway in OnPrem')
param deployOnPrem bool = false

@description('OnPrem Resource Group Name')
param onpremRgName string = 'rg-onprem'

@description('Deploy Bastion Host in OnPrem VNET')
param deployBastionInOnPrem bool = false

@description('OnPrem Bastion SKU')
@allowed([
  'Basic'
  'Standard'
])
param bastionInOnPremSKU string = 'Basic'

@description('Deploy VM in OnPrem VNET')
param deployVMinOnPrem bool = false

@description('Deploy Virtual Network Gateway in OnPrem VNET')
param deployGatewayinOnPrem bool = false

@description('Deploy Site-to-Site VPN connection between OnPrem and Hub Gateways')
param deploySiteToSite bool = false

@description('Site-to-Site ShareKey')
@secure()
param sharedKey string = ''

@description('Enable BGP on OnPrem Gateway')
param onpremBgp bool = false

@description('OnPrem BGP ASN')
param onpremBgpAsn int = 65020

// Create array of all Address Spaces used for site-to-site connection from Hub to OnPrem
var AllAddressSpaces = [for i in range(0, amountOfSpokes + 1): cidrSubnet(AddressSpace, 24, i)]

// set HubType variables 
var isVnetHub = hubType == 'VNET'
var isVwanHub = hubType == 'VWAN'

// Deploy Hub VNET including Bastion Host, Route Table, Network Security group and Azure Firewall
module hubVnet 'HubResourceGroup.bicep' = if (deployHUB && isVnetHub) {
  scope: subscription(hubSubscriptionID)
  name: '${hubRgName}-${location}-VNET'
  params: {
    deployBastionInHub: deployBastionInHub && isVnetHub
    location: location
    AddressSpace: AddressSpace
    hubAddressSpace: AllAddressSpaces[0]
    deployFirewallInHub: deployFirewallInHub && isVnetHub
    AzureFirewallTier: AzureFirewallTier
    hubRgName: hubRgName
    deployFirewallrules: deployFirewallrules && isVnetHub
    deployGatewayInHub: deployGatewayInHub && isVnetHub
    tagsByResource: tagsByResource
    AllSpokeAddressSpaces: skip(AllAddressSpaces, 1)
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
  name: '${hubRgName}-${location}-VWAN'
  params: {
    location: location
    deployFirewallInHub: deployFirewallInHub && isVwanHub
    AddressSpace: AllAddressSpaces[0]
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
      spokeRgNamePrefix: spokeRgNamePrefix
      vmSize: vmSizeSpoke
      tagsByResource: tagsByResource
      osType: osTypeSpoke
      deployUDRs: deployUDRs
      diagnosticWorkspaceId: diagnosticWorkspaceId
      firewallDNSproxy: firewallDNSproxy && deployFirewallInHub
      dcrID: deployHUB && isVnetHub
        ? hubVnet.outputs.dcrvminsightsID
        : deployHUB && isVwanHub ? vwan.outputs.dcrvminsightsID : ''
    }
  }
]

// VNET Peerings
module vnetPeerings 'VnetPeerings.bicep' = [
  for i in range(0, amountOfSpokes): if (deployHUB && deploySpokes && isVnetHub && !deployVnetPeeringAVNM) {
    name: '${hubRgName}-VnetPeering${i + 1}-${location}'
    params: {
      HubResourceGroupName: deployHUB && deploySpokes && isVnetHub
        ? hubVnet.outputs.HubResourceGroupName
        : 'No VNET peering'
      SpokeResourceGroupName: deployHUB && deploySpokes && isVnetHub
        ? spokeVnets[i].outputs.spokeResourceGroupName
        : 'No peering'
      HubVnetName: deployHUB && deploySpokes && isVnetHub ? hubVnet.outputs.hubVnetName : 'No VNET peering'
      SpokeVnetID: deployHUB && deploySpokes && isVnetHub ? spokeVnets[i].outputs.spokeVnetID : 'No VNET peering'
      HubVnetID: deployHUB && deploySpokes && isVnetHub ? hubVnet.outputs.hubVnetID : 'No VNET peering'
      SpokeVnetName: deployHUB && deploySpokes && isVnetHub ? spokeVnets[i].outputs.spokeVnetName : 'No VNET peering'
      counter: i
      GatewayDeployed: deployGatewayInHub
      hubSubscriptionID: hubSubscriptionID
      spokeSubscriptionID: spokeSubscriptionID
    }
  }
]

// VNET Peerings AVNM
module vnetPeeringsAVNM 'VnetPeeringsAvnm.bicep' = if (deployHUB && deploySpokes && isVnetHub && deployVnetPeeringAVNM) {
  scope: subscription(hubSubscriptionID)
  name: '${hubRgName}-${location}-AVNM'
  params: {
    avnmSubscriptionScopes: deployHUB && deploySpokes && isVnetHub && deployVnetPeeringAVNM
      ? concat(union(array('/subscriptions/${hubSubscriptionID}'), array('/subscriptions/${spokeSubscriptionID}')))
      : []
    HubResourceGroupName: deployHUB && deploySpokes && isVnetHub && deployVnetPeeringAVNM
      ? hubVnet.outputs.HubResourceGroupName
      : 'No Hub'
    spokeVNETids: [
      for i in range(0, amountOfSpokes): deployHUB && deploySpokes && isVnetHub && deployVnetPeeringAVNM
        ? spokeVnets[i].outputs.spokeVnetID
        : []
    ]
    hubVNETid: deployHUB && deploySpokes && isVnetHub && deployVnetPeeringAVNM ? hubVnet.outputs.hubVnetID : 'No Hub'
    useHubGateway: deployGatewayInHub
    deployVnetPeeringMesh: deployVnetPeeringMesh
    location: location
    tagsByResource: tagsByResource
  }
}

// VNET Connections to Azure vWAN
module vnetConnections 'vWanVnetConnections.bicep' = [
  for i in range(0, amountOfSpokes): if (deployHUB && deploySpokes && isVwanHub) {
    name: '${hubRgName}-VnetConnection${i + 1}-${location}'
    params: {
      HubResourceGroupName: deployHUB && deploySpokes && isVwanHub
        ? vwan.outputs.HubResourceGroupName
        : 'No VNET peering'
      SpokeVnetID: deployHUB && deploySpokes && isVwanHub ? spokeVnets[i].outputs.spokeVnetID : 'No VNET peering'
      vwanHubName: deployHUB && deploySpokes && isVwanHub ? vwan.outputs.vwanHubName : 'No VNET peering'
      deployFirewallInHub: deployFirewallInHub && isVwanHub
      counter: i
      hubSubscriptionID: hubSubscriptionID
      enableRoutingIntent: internetTrafficRoutingPolicy || privateTrafficRoutingPolicy
    }
  }
]

// Deploy OnPrem VNET including VM, Bastion, Network Security Group and Virtual Network Gateway
module onprem 'OnPremResourceGroup.bicep' = if (deployOnPrem) {
  scope: subscription(onPremSubscriptionID)
  name: '${onpremRgName}-${location}'
  params: {
    location: location
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
    dcrID: deployOnPrem && isVnetHub ? hubVnet.outputs.dcrvminsightsID : isVwanHub ? vwan.outputs.dcrvminsightsID : ''
  }
}

// Deploy S2s VPN from OnPrem Gateway to Hub Gateway
module s2s 'VpnConnections.bicep' = if (deployGatewayInHub && deployGatewayinOnPrem && deploySiteToSite && isVnetHub) {
  name: '${hubRgName}-s2s-Hub-OnPrem-${location}'
  params: {
    location: location
    HubRgName: deployHUB && isVnetHub ? hubRgName : 'none'
    HubGatewayID: deployGatewayInHub && isVnetHub ? hubVnet.outputs.hubGatewayID : 'none'
    HubGatewayPublicIP: deployGatewayInHub && isVnetHub ? hubVnet.outputs.hubGatewayPublicIP : 'none'
    HubAddressPrefixes: deployHUB && isVnetHub ? AllAddressSpaces : []
    HubLocalGatewayName: deploySiteToSite && isVnetHub ? 'LocalGateway-Hub' : 'none'
    OnPremRgName: deployOnPrem && isVnetHub ? onpremRgName : 'none'
    OnPremGatewayID: deployGatewayinOnPrem && isVnetHub ? onprem.outputs.OnPremGatewayID : 'none'
    OnPremGatewayPublicIP: deployGatewayinOnPrem && isVnetHub ? onprem.outputs.OnPremGatewayPublicIP : 'none'
    OnPremAddressPrefixes: deployOnPrem && isVnetHub ? array(onprem.outputs.OnPremAddressSpace) : []
    OnPremLocalGatewayName: deploySiteToSite && isVnetHub ? 'LocalGateway-OnPrem' : 'none'
    tagsByResource: tagsByResource
    enableBgp: hubBgp && onpremBgp
    HubBgpAsn: hubBgpAsn
    HubBgpPeeringAddress: deployGatewayInHub && hubBgp && isVnetHub ? hubVnet.outputs.HubGwBgpPeeringAddress : 'none'
    OnPremBgpAsn: onpremBgpAsn
    OnPremBgpPeeringAddress: deployGatewayinOnPrem && onpremBgp && isVnetHub
      ? onprem.outputs.OnPremGwBgpPeeringAddress
      : 'none'
    sharedKey: deploySiteToSite ? sharedKey : 'none'
    hubSubscriptionID: hubSubscriptionID
    onPremSubscriptionID: onPremSubscriptionID
  }
}

// Deploy s2s VPN from OnPrem Gateway to vWan Hub Gateway
module vwans2s 'vWanVpnConnections.bicep' = if (deployGatewayInHub && deployGatewayinOnPrem && deploySiteToSite && isVwanHub) {
  name: '${hubRgName}-s2s-Hub-vWan-OnPrem-${location}'
  params: {
    location: location
    vwanGatewayName: deployHUB && deployGatewayInHub && isVwanHub ? vwan.outputs.vpnGwName : 'none'
    vwanLinkBgpAsn: deployOnPrem && deployGatewayinOnPrem && onpremBgp ? onprem.outputs.OnPremGwBgpAsn : 65515
    vwanLinkPublicIP: deployOnPrem && deployGatewayinOnPrem ? onprem.outputs.OnPremGatewayPublicIP : 'none'
    vwanVpnGwInfo: deployHUB && deployGatewayInHub && isVwanHub ? vwan.outputs.vpnGwBgpIp : []
    vwanLinkBgpPeeringAddress: deployOnPrem && deployGatewayinOnPrem && onpremBgp && isVwanHub
      ? onprem.outputs.OnPremGwBgpPeeringAddress
      : 'none'
    vwanVpnSiteName: 'OnPrem'
    vwanID: deployHUB && isVwanHub ? vwan.outputs.vWanID : 'none'
    vwanHubName: deployHUB && isVwanHub ? vwan.outputs.vwanHubName : 'none'
    OnPremVpnGwID: deployOnPrem && deployGatewayinOnPrem ? onprem.outputs.OnPremGatewayID : 'none'
    OnPremRgName: deployOnPrem ? onpremRgName : 'none'
    HubRgName: deployHUB ? hubRgName : 'none'
    tagsByResource: tagsByResource
    deployFirewallInHub: deployFirewallInHub && isVwanHub
    sharedKey: deploySiteToSite ? sharedKey : 'none'
    hubSubscriptionID: hubSubscriptionID
    onPremSubscriptionID: onPremSubscriptionID
  }
}

// Outputs
output VNET_AzFwPrivateIp string = deployFirewallInHub && deployHUB && isVnetHub ? hubVnet.outputs.azFwIp : 'none'
output VWAN_AzFwPublicIp array = deployFirewallInHub && deployHUB && isVwanHub ? vwan.outputs.vWanFwPublicIP : []
output HubVnetID string = deployHUB && isVnetHub ? hubVnet.outputs.hubVnetID : 'none'
output HubVnetAddressSpace array = deployHUB && isVnetHub ? hubVnet.outputs.hubVnetAddressSpace : []
output HubGatewayPublicIP string = deployGatewayInHub && isVnetHub ? hubVnet.outputs.hubGatewayPublicIP : 'none'
output HubGatewayID string = deployGatewayInHub && isVnetHub ? hubVnet.outputs.hubGatewayID : 'none'
output HubBgpPeeringAddress string = deployGatewayInHub && isVnetHub ? hubVnet.outputs.HubGwBgpPeeringAddress : 'none'
output vWanHubID string = deployHUB && isVwanHub ? vwan.outputs.vWanHubID : 'none'
output vWanID string = deployHUB && isVwanHub ? vwan.outputs.vWanID : 'none'
output vWanVpnGwID string = deployHUB && deployGatewayInHub && isVwanHub ? vwan.outputs.vWanVpnGwID : 'none'
output vWanVpnGwPip array = deployHUB && deployGatewayInHub && isVwanHub ? vwan.outputs.vWanVpnGwPip : []
output vWanVpnBgpIp array = deployHUB && deployGatewayInHub && isVwanHub ? vwan.outputs.vpnGwBgpIp : []
output vWanVpnBgpAsn int = deployHUB && deployGatewayInHub && isVwanHub ? vwan.outputs.vpnGwBgpAsn : 0
output vWanHubAddressSpace string = deployHUB && isVwanHub ? vwan.outputs.vWanHubAddressSpace : 'none'
output OnPremVnetAddressSpace string = deployOnPrem ? onprem.outputs.OnPremAddressSpace : 'none'
output OnPremGatewayPublicIP string = deployGatewayinOnPrem ? onprem.outputs.OnPremGatewayPublicIP : 'none'
output OnPremGatewayID string = deployGatewayinOnPrem ? onprem.outputs.OnPremGatewayID : 'none'
output OnPremBgpPeeringAddress string = deployGatewayinOnPrem ? onprem.outputs.OnPremGwBgpPeeringAddress : 'none'
output SpokeVnets array = [
  for i in range(0, amountOfSpokes): deploySpokes
    ? {
        SpokeVnetId: spokeVnets[i].outputs.spokeVnetID
        SpokeVnetAddressSpace: spokeVnets[i].outputs.spokeVnetAddressSpace
      }
    : 'none'
]
