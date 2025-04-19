targetScope = 'subscription'

// Define the locations for the Lab deployment. max 2 locations. min 1 location.
param locations _Locations = [
  {
    region: 'westeurope'
    regionAddressSpace: '172.16.0.0/16'
    hubSubscriptionID: subscription().subscriptionId
    spokeSubscriptionID: subscription().subscriptionId
    onPremSubscriptionID: subscription().subscriptionId
  }

  {
    region: 'northeurope'
    regionAddressSpace: '172.31.0.0/16'
    hubSubscriptionID: subscription().subscriptionId
    spokeSubscriptionID: subscription().subscriptionId
    onPremSubscriptionID: subscription().subscriptionId
  }
]

@maxLength(2)
type _Locations = {
  region: string
  regionAddressSpace: string
  hubSubscriptionID: string
  spokeSubscriptionID: string
  onPremSubscriptionID: string
}[]

// // Subscriptions
// @description('SubscriptionID for HUB deployemnt')
// param hubSubscriptionID string = subscription().subscriptionId

// @description('SubscriptionID for Spoke deployemnt')
// param spokeSubscriptionID string = subscription().subscriptionId

// @description('SubscriptionID for OnPrem deployemnt')
// param onPremSubscriptionID string = subscription().subscriptionId

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

// // Shared parameters
// @description('IP Address space used for VNETs in deployment. Only enter a /16 subnet. Default = 172.16.0.0/16')
// param AddressSpace string = '172.16.0.0/16'

// @description('Azure Region. Defualt = Deployment location')
// param location string = deployment().location

@description('Tags by resource types. Default = empty')
param tagsByResource object = {}

@description('LogAnalytics Workspace resourceID')
param diagnosticWorkspaceId string = ''

// Spoke VNET Parameters
@description('Deploy Spoke VNETs. Default = true')
param deploySpokes bool = true

@description('Spoke resource group prefix name. Default = rg-spoke')
param spokeRgNamePrefix string = 'rg-spoke'

@description('Amount of Spoke VNETs you want to deploy. Default = 2')
param amountOfSpokes int = 2

@description('Deploy VM in every Spoke VNET')
param deployVMsInSpokes bool = false

@description('Directly connect VNET Spokes (Fully Meshed Topology)')
param deployVnetPeeringMesh bool = false

@description('Let Azure Virtual Network Manager manage UDRs in Spoke VNETs')
param deployAvnmUDRs bool = false

@description('Enable Private Subnet in Default Subnet in Spoke VNETs')
param defaultOutboundAccess bool = true

// Hub VNET Parameters
@description('Deploy Hub')
param deployHUB bool = true

@description('Deploy Hub VNET or Azuere vWAN. Default = VNET')
@allowed([
  'VNET'
  'VWAN'
])
param hubType string = 'VNET'

@description('Hub resource group pre-fix name. Default = rg-hub')
param hubRgName string = 'rg-hub'

@description('Deploy Bastion Host in Hub VNET. Default = true')
param deployBastionInHub bool = false

@description('Hub Bastion SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param bastionInHubSKU string = 'Basic'

@description('Deploy Virtual Network Gateway in Hub VNET')
param deployGatewayInHub bool = false

@description('Deploy Azure Firewall in Hub VNET. includes deployment of custom route tables in Spokes and Hub VNETs')
param deployFirewallInHub bool = false

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

// Define the short codes for regions, three letters, capitalized. Only exclude restricted regions.
var regionShortCodes = {
  southafricanorth: 'SAN'
  australiaeast: 'AUE'
  centralindia: 'CIN'
  eastasia: 'EAS'
  indonesiacentral: 'IDC'
  japaneast: 'JAE'
  japanwest: 'JAW'
  koreacentral: 'KOC'
  newzealandnorth: 'NZN'
  southeastasia: 'SEA'
  canadacentral: 'CAC'
  francecentral: 'FRC'
  germanywestcentral: 'GWC'
  italynorth: 'ITN'
  northeurope: 'NEU'
  norwayeast: 'NOE'
  polandcentral: 'POC'
  spaincentral: 'SCE'
  swedencentral: 'SCE'
  switzerlandnorth: 'SWN'
  uksouth: 'UKS'
  westeurope: 'WEU'
  mexicocentral: 'MEC'
  israelcentral: 'ISC'
  qatarcentral: 'QAC'
  uaenorth: 'UAE'
  brazilsouth: 'BRS'
  centralus: 'CUS'
  eastus: 'EUS'
  southcentralus: 'SCU'
  westus2: 'WUS'
  westus3: 'WUS'
}

module deployRegion 'mainRegion.bicep' = [
  for location in locations: {
    name: 'deployRegion-${regionShortCodes[location.region]}'
    params: {
      location: location.region
      shortLocationCode: regionShortCodes[location.region]
      hubSubscriptionID: location.hubSubscriptionID
      spokeSubscriptionID: location.spokeSubscriptionID
      onPremSubscriptionID: location.onPremSubscriptionID
      adminUsername: adminUsername
      adminPassword: adminPassword
      vmSizeSpoke: vmSizeSpoke
      vmSizeOnPrem: vmSizeOnPrem
      osTypeSpoke: osTypeSpoke
      osTypeOnPrem: osTypeOnPrem
      AddressSpace: location.regionAddressSpace
      amountOfSpokes: amountOfSpokes
      spokeRgNamePrefix: spokeRgNamePrefix
      AzureFirewallTier: AzureFirewallTier
      bastionInHubSKU: bastionInHubSKU
      bastionInOnPremSKU: bastionInOnPremSKU
      hubBgp: hubBgp
      defaultOutboundAccess: defaultOutboundAccess
      deployAvnmUDRs: deployAvnmUDRs
      deployBastionInHub: deployBastionInHub
      deployBastionInOnPrem: deployBastionInOnPrem
      deployFirewallInHub: deployFirewallInHub
      deployGatewayInHub: deployGatewayInHub
      deployGatewayinOnPrem: deployGatewayinOnPrem
      deployHUB: deployHUB
      deployOnPrem: deployOnPrem
      deploySpokes: deploySpokes
      deployVMsInSpokes: deployVMsInSpokes
      deployVnetPeeringMesh: deployVnetPeeringMesh
      deployVnetPeeringAVNM: deployVnetPeeringAVNM
      deployUDRs: deployUDRs
      diagnosticWorkspaceId: diagnosticWorkspaceId
      tagsByResource: tagsByResource
      internetTrafficRoutingPolicy: internetTrafficRoutingPolicy
      privateTrafficRoutingPolicy: privateTrafficRoutingPolicy
      sharedKey: sharedKey
      hubBgpAsn: hubBgpAsn
      onpremBgpAsn: onpremBgpAsn
      onpremBgp: onpremBgp
      deployFirewallrules: deployFirewallrules
      firewallDNSproxy: firewallDNSproxy
      deploySiteToSite: deploySiteToSite
      deployVMinOnPrem: deployVMinOnPrem
      hubRgName: hubRgName
      onpremRgName: onpremRgName
      hubType: hubType
    }
  }
]

module deployGlobalVnetPeerings 'VnetPeeringsNEW.bicep' = if (length(locations) == 2) {
  name: 'deployGlobalVnetPeerings'
  params: {
    vnetIDA: deployRegion[0].outputs.HubVnetID
    vnetIDB: deployRegion[1].outputs.HubVnetID
  }
}
