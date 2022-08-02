targetScope = 'subscription'

// Subscriptions
@description('SubscriptionID for HUB deployemnt')
param hubSubscriptionID string = subscription().subscriptionId

@description('SubscriptionID for Spoke deployemnt')
param spokeSubscriptionID string = subscription().subscriptionId

@description('SubscriptionID for OnPrem deployemnt')
param onPremSubscriptionID string = subscription().subscriptionId

// Virtual Machine parameters
@description('Admin username for VM')
param adminUsername string = ''

@description('Admin Password for VM')
@secure()
param adminPassword string = ''

@description('Hub Virtual Machine SKU. Default = Standard_B2s')
param vmSizeHub string = 'Standard_B2s'

@description('Spoke Virtual Machine SKU. Default = Standard_B2s')
param vmSizeSpoke string = 'Standard_B2s'

@description('OnPrem Virtual Machine SKU. Default = Standard_B2s')
param vmSizeOnPrem string = 'Standard_B2s'

@description('Hub Virtual Machine OS type. Windows or Linux. Default = Windows')
@allowed([
  'Linux'
  'Windows'
])
param osTypeHub string = 'Windows'

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

@description('Deploy Bastion Host in every Spoke VNET')
param deployBastionInSpoke bool = false

@description('Spoke Bastion SKU')
@allowed([
  'Basic'
  'Standard'
])
param bastionInSpokeSKU string = 'Basic'

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
])
param bastionInHubSKU string = 'Basic'

@description('Deploy VM in Hub VNET')
param deployVMinHub bool = true

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
param deployFirewallrules bool = false

@description('Dploy route tables (UDR\'s) to VM subnet(s) in Hub and Spokes')
param deployUDRs bool = true

@description('Enable BGP on Hub Gateway')
param hubBgp bool = false

@description('Hub BGP ASN')
param hubBgpAsn int = 65515

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
var AllAddressSpaces = [for i in range(0, amountOfSpokes + 1): replace(AddressSpace, '0.0/16', '${i}.0/24')]

// Create array of all Spoke Address Spaces used to set routes on VPN Gateway rout table in Hub
var AllSpokeAddressSpaces = [for i in range(1, amountOfSpokes): replace(AddressSpace, '0.0/16', '${i}.0/24')]

// Deploy Hub VNET including VM, Bastion Host, Route Table, Network Security group and Azure Firewall
module hubVnet 'HubResourceGroup.bicep' = if (deployHUB && hubType == 'VNET') {
  scope: subscription(hubSubscriptionID)
  name: '${hubRgName}-${location}-VNET'
  params: {
    deployBastionInHub: deployBastionInHub && hubType == 'VNET'
    location: location
    AddressSpace: AddressSpace
    adminPassword: adminPassword
    adminUsername: adminUsername
    deployVMinHub: deployVMinHub && hubType == 'VNET'
    deployFirewallInHub: deployFirewallInHub && hubType == 'VNET'
    AzureFirewallTier: AzureFirewallTier
    hubRgName: hubRgName
    deployFirewallrules: deployFirewallrules && hubType == 'VNET'
    deployGatewayInHub: deployGatewayInHub && hubType == 'VNET'
    vmSize: vmSizeHub
    tagsByResource: tagsByResource
    osType: osTypeHub
    AllSpokeAddressSpaces: AllSpokeAddressSpaces
    vpnGwBgpAsn: hubBgp ? hubBgpAsn : 65515
    vpnGwEnebaleBgp: hubBgp
    deployUDRs: deployUDRs
    bastionSku: bastionInHubSKU
    diagnosticWorkspaceId: diagnosticWorkspaceId
  }
}

//  Deploy Azure vWAN with vWAN Hub and Azure Firewall
module vwan 'vWanResourceGroup.bicep' = if (deployHUB && hubType == 'VWAN') {
  scope: subscription(hubSubscriptionID)
  name: '${hubRgName}-${location}-VWAN'
  params: {
    location: location
    deployFirewallInHub: deployFirewallInHub && hubType == 'VWAN'
    AddressSpace: AddressSpace
    AzureFirewallTier: AzureFirewallTier
    deployFirewallrules: deployFirewallrules && hubType == 'VWAN'
    hubRgName: hubRgName
    deployGatewayInHub: deployGatewayInHub && hubType == 'VWAN'
    tagsByResource: tagsByResource
    diagnosticWorkspaceId: diagnosticWorkspaceId
  }
}

// Deploy Spoke VNET's including VM, Bastion Host, Route Table, Network Security group
module spokeVnets 'SpokeResourceGroup.bicep' = [for i in range(1, amountOfSpokes): if (deploySpokes) {
  scope: subscription(spokeSubscriptionID)
  name: '${spokeRgNamePrefix}${i}-${location}'
  params: {
    location: location
    counter: i
    AddressSpace: AddressSpace
    deployBastionInSpoke: deployBastionInSpoke
    adminPassword: adminPassword
    adminUsername: adminUsername
    deployVMsInSpokes: deployVMsInSpokes
    deployFirewallInHub: deployFirewallInHub && hubType == 'VNET'
    AzureFirewallpip: deployHUB && hubType == 'VNET' ? hubVnet.outputs.azFwIp : 'Not deployed'
    HubDeployed: deployHUB && hubType == 'VNET'
    spokeRgNamePrefix: spokeRgNamePrefix
    vmSize: vmSizeSpoke
    tagsByResource: tagsByResource
    osType: osTypeSpoke
    hubDefaultSubnetPrefix: deployHUB && hubType == 'VNET' ? hubVnet.outputs.hubDefaultSubnetPrefix : 'Not deployed'
    deployUDRs: deployUDRs
    bastionSku: bastionInSpokeSKU
    diagnosticWorkspaceId: diagnosticWorkspaceId
  }
}]

// VNET Peerings
module vnetPeerings 'VnetPeerings.bicep' = [for i in range(0, amountOfSpokes): if (deployHUB && deploySpokes && hubType == 'VNET') {
  name: '${hubRgName}-VnetPeering${i + 1}-${location}'
  params: {
    HubResourceGroupName: deployHUB && deploySpokes && hubType == 'VNET' ? hubVnet.outputs.HubResourceGroupName : 'No VNET peering'
    SpokeResourceGroupName: deployHUB && deploySpokes && hubType == 'VNET' ? spokeVnets[i].outputs.spokeResourceGroupName : 'No peering'
    HubVnetName: deployHUB && deploySpokes && hubType == 'VNET' ? hubVnet.outputs.hubVnetName : 'No VNET peering'
    SpokeVnetID: deployHUB && deploySpokes && hubType == 'VNET' ? spokeVnets[i].outputs.spokeVnetID : 'No VNET peering'
    HubVnetID: deployHUB && deploySpokes && hubType == 'VNET' ? hubVnet.outputs.hubVnetID : 'No VNET peering'
    SpokeVnetName: deployHUB && deploySpokes && hubType == 'VNET' ? spokeVnets[i].outputs.spokeVnetName : 'No VNET peering'
    counter: i
    GatewayDeployed: deployGatewayInHub
    hubSubscriptionID: hubSubscriptionID
    spokeSubscriptionID: spokeSubscriptionID
  }
}]

// VNET Connections to Azure vWAN
@batchSize(1)
module vnetConnections 'vWanVnetConnections.bicep' = [for i in range(0, amountOfSpokes): if (deployHUB && deploySpokes && hubType == 'VWAN') {
  name: '${hubRgName}-VnetConnection${i + 1}-${location}'
  params: {
    HubResourceGroupName: deployHUB && deploySpokes && hubType == 'VWAN' ? vwan.outputs.HubResourceGroupName : 'No VNET peering'
    SpokeVnetID: deployHUB && deploySpokes && hubType == 'VWAN' ? spokeVnets[i].outputs.spokeVnetID : 'No VNET peering'
    vwanHubName: deployHUB && deploySpokes && hubType == 'VWAN' ? vwan.outputs.vwanHubName : 'No VNET peering'
    deployFirewallInHub: deployFirewallInHub && hubType == 'VWAN'
    counter: i
    hubSubscriptionID: hubSubscriptionID
  }
}]

// Deploy OnPrem VNET including VM, Bastion, Network Security Group and Virtual Network Gateway
module onprem 'OnPremResourceGroup.bicep' = if (deployOnPrem) {
  scope: subscription(onPremSubscriptionID)
  name: '${onpremRgName}-${location}'
  params: {
    location: location
    adminPassword: adminPassword
    adminUsername: adminUsername
    AddressSpace: AddressSpace
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
  }
}

// Deploy S2s VPN from OnPrem Gateway to Hub Gateway
module s2s 'VpnConnections.bicep' = if (deployGatewayInHub && deployGatewayinOnPrem && deploySiteToSite && hubType == 'VNET') {
  name: '${hubRgName}-s2s-Hub-OnPrem-${location}'
  params: {
    location: location
    HubRgName: deployHUB && hubType == 'VNET' ? hubRgName : 'none'
    HubGatewayID: deployGatewayInHub && hubType == 'VNET' ? hubVnet.outputs.hubGatewayID : 'none'
    HubGatewayPublicIP: deployGatewayInHub && hubType == 'VNET' ? hubVnet.outputs.hubGatewayPublicIP : 'none'
    HubAddressPrefixes: deployHUB && hubType == 'VNET' ? AllAddressSpaces : []
    HubLocalGatewayName: deploySiteToSite && hubType == 'VNET' ? 'LocalGateway-Hub' : 'none'
    OnPremRgName: deployOnPrem && hubType == 'VNET' ? onpremRgName : 'none'
    OnPremGatewayID: deployGatewayinOnPrem && hubType == 'VNET' ? onprem.outputs.OnPremGatewayID : 'none'
    OnPremGatewayPublicIP: deployGatewayinOnPrem && hubType == 'VNET' ? onprem.outputs.OnPremGatewayPublicIP : 'none'
    OnPremAddressPrefixes: deployOnPrem && hubType == 'VNET' ? array(onprem.outputs.OnPremAddressSpace) : []
    OnPremLocalGatewayName: deploySiteToSite && hubType == 'VNET' ? 'LocalGateway-OnPrem' : 'none'
    tagsByResource: tagsByResource
    enableBgp: hubBgp && onpremBgp
    HubBgpAsn: hubBgpAsn
    HubBgpPeeringAddress: deployGatewayInHub && hubBgp && hubType == 'VNET' ? hubVnet.outputs.HubGwBgpPeeringAddress : 'none'
    OnPremBgpAsn: onpremBgpAsn
    OnPremBgpPeeringAddress: deployGatewayinOnPrem && onpremBgp && hubType == 'VNET' ? onprem.outputs.OnPremGwBgpPeeringAddress : 'none'
    sharedKey: deploySiteToSite ? sharedKey : 'none'
    hubSubscriptionID: hubSubscriptionID
    onPremSubscriptionID: onPremSubscriptionID
  }
}

// Deploy s2s VPN from OnPrem Gateway to vWan Hub Gateway
module vwans2s 'vWanVpnConnections.bicep' = if (deployGatewayInHub && deployGatewayinOnPrem && deploySiteToSite && hubType == 'VWAN') {
  name: '${hubRgName}-s2s-Hub-vWan-OnPrem-${location}'
  params: {
    location: location
    vwanGatewayName: deployHUB && deployGatewayInHub && hubType == 'VWAN' ? vwan.outputs.vpnGwName : 'none'
    vwanLinkBgpAsn: deployOnPrem && deployGatewayinOnPrem && onpremBgp ? onprem.outputs.OnPremGwBgpAsn : 65515
    vwanLinkPublicIP: deployOnPrem && deployGatewayinOnPrem ? onprem.outputs.OnPremGatewayPublicIP : 'none'
    vwanVpnGwInfo: deployHUB && deployGatewayInHub && hubType == 'VWAN' ? vwan.outputs.vpnGwBgpIp : []
    vwanLinkBgpPeeringAddress: deployOnPrem && deployGatewayinOnPrem && onpremBgp && hubType == 'VWAN' ? onprem.outputs.OnPremGwBgpPeeringAddress : 'none'
    vwanVpnSiteName: 'OnPrem'
    vwanID: deployHUB && hubType == 'VWAN' ? vwan.outputs.vWanID : 'none'
    vwanHubName: deployHUB && hubType == 'VWAN' ? vwan.outputs.vwanHubName : 'none'
    OnPremVpnGwID: deployOnPrem && deployGatewayinOnPrem ? onprem.outputs.OnPremGatewayID : 'none'
    OnPremRgName: deployOnPrem ? onpremRgName : 'none'
    HubRgName: deployHUB ? hubRgName : 'none'
    tagsByResource: tagsByResource
    deployFirewallInHub: deployFirewallInHub && hubType == 'VWAN'
    sharedKey: deploySiteToSite ? sharedKey : 'none'
    hubSubscriptionID: hubSubscriptionID
    onPremSubscriptionID: onPremSubscriptionID
  }
}

// Outputs
output VNET_AzFwPrivateIp string = deployFirewallInHub && deployHUB && hubType == 'VNET' ? hubVnet.outputs.azFwIp : 'none'
output VWAN_AzFwPublicIp array = deployFirewallInHub && deployHUB && hubType == 'VWAN' ? vwan.outputs.vWanFwPublicIP : []
output HubVnetID string = deployHUB && hubType == 'VNET' ? hubVnet.outputs.hubVnetID : 'none'
output HubVnetAddressSpace string = deployHUB && hubType == 'VNET' ? hubVnet.outputs.hubVnetAddressSpace : 'none'
output HubGatewayPublicIP string = deployGatewayInHub && hubType == 'VNET' ? hubVnet.outputs.hubGatewayPublicIP : 'none'
output HubGatewayID string = deployGatewayInHub && hubType == 'VNET' ? hubVnet.outputs.hubGatewayID : 'none'
output HubBgpPeeringAddress string = deployGatewayInHub && hubType == 'VNET' ? hubVnet.outputs.HubGwBgpPeeringAddress : 'none'
output vWanHubID string = deployHUB && hubType == 'VWAN' ? vwan.outputs.vWanHubID : 'none'
output vWanID string = deployHUB && hubType == 'VWAN' ? vwan.outputs.vWanID : 'none'
output vWanVpnGwID string = deployHUB && deployGatewayInHub && hubType == 'VWAN' ? vwan.outputs.vWanVpnGwID : 'none'
output vWanVpnGwPip array = deployHUB && deployGatewayInHub && hubType == 'VWAN' ? vwan.outputs.vWanVpnGwPip : []
output vWanVpnBgpIp array = deployHUB && deployGatewayInHub && hubType == 'VWAN' ? vwan.outputs.vpnGwBgpIp : []
output vWanVpnBgpAsn int = deployHUB && deployGatewayInHub && hubType == 'VWAN' ? vwan.outputs.vpnGwBgpAsn : 0
output vWanHubAddressSpace string = deployHUB && hubType == 'VWAN' ? vwan.outputs.vWanHubAddressSpace : 'none'
output OnPremVnetAddressSpace string = deployOnPrem ? onprem.outputs.OnPremAddressSpace : 'none'
output OnPremGatewayPublicIP string = deployGatewayinOnPrem ? onprem.outputs.OnPremGatewayPublicIP : 'none'
output OnPremGatewayID string = deployGatewayinOnPrem ? onprem.outputs.OnPremGatewayID : 'none'
output OnPremBgpPeeringAddress string = deployGatewayinOnPrem ? onprem.outputs.OnPremGwBgpPeeringAddress : 'none'
output SpokeVnets array = [for i in range(0, amountOfSpokes): deploySpokes ? {
  SpokeVnetId: spokeVnets[i].outputs.spokeVnetID
  SpokeVnetAddressSpace: spokeVnets[i].outputs.spokeVnetAddressSpace
} : 'none']
