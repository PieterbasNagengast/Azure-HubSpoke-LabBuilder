targetScope = 'subscription'

// Virtual Machine parameters
@description('Admin username for VM')
param adminUsername string = ''

@description('Admin Password for VM')
@secure()
param adminPassword string = ''

@description('Virtual Machine SKU. Default = Standard_B2s')
param vmSize string = 'Standard_B2s'

// Shared parameters
@description('IP Address space used for VNETs in deployment. Only enter a /16 subnet. Default = 172.16.0.0/16')
param AddressSpace string = '172.16.0.0/16'

@description('Azure Region. Defualt = Deployment location')
param location string = deployment().location

@description('Tags by resource types')
param tagsByResource object = {}

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

// Hub VNET Parameters
@description('Deploy Hub VNET')
param deployHUB bool = true

@description('Hub resource group pre-fix name')
param hubRgName string = 'rg-hub'

@description('Deploy Bastion Host in Hub VNET')
param deployBastionInHub bool = false

@description('Deploy VM in Hub VNET')
param deployVMinHub bool = true

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
param deployFirewallrules bool = false

// OnPrem parameters\
@description('Deploy Virtual Network Gateway in OnPrem')
param deployOnPrem bool = true

@description('OnPrem Resource Group Name')
param onpremRgName string = 'rg-onprem'

@description('Deploy Bastion Host in OnPrem VNET')
param deployBastionInOnPrem bool = false

@description('Deploy VM in OnPrem VNET')
param deployVMinOnPrem bool = false

@description('Deploy Virtual Network Gateway in OnPrem VNET')
param deployGatewayinOnPrem bool = false

@description('Deploy Site-to-Site VPN connection between OnPrem and Hub Gateways')
param deploySiteToSite bool = false

// Create array of all Address Spaces used for Hub and Spoke VNET's (used in site-to-site connection)
var AllAddressSpaces = [for i in range(0, amountOfSpokes + 1): replace(AddressSpace,'0.0/16','${i}.0/24')]

// Deploy Hub VNET including VM, Bastion Host, Route Table, Network Security group and Azure Firewall
module hubVnet 'HubResourceGroup.bicep' = if (deployHUB) {
  name: '${hubRgName}-${location}'
  params: {
    deployBastionInHub: deployBastionInHub
    location: location
    AddressSpace: AddressSpace
    adminPassword: adminPassword
    adminUsername: adminUsername
    deployVMinHub: deployVMinHub
    deployFirewallInHub: deployFirewallInHub
    AzureFirewallTier: AzureFirewallTier
    hubRgName: hubRgName
    deployFirewallrules: deployFirewallrules
    deployGatewayInHub: deployGatewayInHub
    vmSize: vmSize
    tagsByResource: tagsByResource
  }
}

// Deploy Spoke VNET's including VM, Bastion Host, Route Table, Network Security group
module spokeVnets 'SpokeResourceGroup.bicep' = [for i in range(1, amountOfSpokes): if (deploySpokes) {
  name: '${spokeRgNamePrefix}${i}-${location}'
  params: {
    location: location
    counter: i
    AddressSpace: AddressSpace
    deployBastionInSpoke: deployBastionInSpoke
    adminPassword: adminPassword
    adminUsername: adminUsername
    deployVMsInSpokes: deployVMsInSpokes
    deployFirewallInHub: deployFirewallInHub
    AzureFirewallpip: deployHUB ? hubVnet.outputs.azFwIp : 'Not deployed'
    HubDeployed: deployHUB
    spokeRgNamePrefix: spokeRgNamePrefix
    vmSize: vmSize
    tagsByResource: tagsByResource
  }
}]

// VNET Peerings
module vnetPeerings 'Vnetpeerings.bicep' = [for i in range(0, amountOfSpokes): if (deployHUB && deploySpokes) {
  name: 'VnetPeering${i}-${location}'
  params: {
    HubResourceGroupName: deployHUB && deploySpokes ? hubVnet.outputs.HubResourceGroupName : 'No VNET peering'
    SpokeResourceGroupName: deployHUB && deploySpokes ? spokeVnets[i].outputs.spokeResourceGroupName : 'No peering'
    HubVnetName: deployHUB && deploySpokes ? hubVnet.outputs.hubVnetName : 'No VNET peering'
    SpokeVnetID: deployHUB && deploySpokes ? spokeVnets[i].outputs.spokeVnetID : 'No VNET peering'
    HubVnetID: deployHUB && deploySpokes ? hubVnet.outputs.hubVnetID : 'No VNET peering'
    SpokeVnetName: deployHUB && deploySpokes ? spokeVnets[i].outputs.spokeVnetName : 'No VNET peering'
    counter: i
  }
}]

// Deploy OnPrem VNET including VM, Bastion, Network Security Group and Virtual Network Gateway
module onprem 'OnPremResourceGroup.bicep' = if (deployOnPrem) {
  name: onpremRgName
  params: {
    location: location
    adminPassword: adminPassword
    adminUsername: adminUsername
    AddressSpace: AddressSpace
    deployBastionInOnPrem: deployBastionInOnPrem
    deployGatewayInOnPrem: deployGatewayinOnPrem
    deployVMsInOnPrem: deployVMinOnPrem
    OnPremRgName: onpremRgName
    vmSize: vmSize
    tagsByResource: tagsByResource
  }
}

// Deploy S2s VPN from OnPrem Gateway to Hub Gateway
module s2s 'VpnConnections.bicep' = if(deployGatewayInHub && deployGatewayinOnPrem && deploySiteToSite) {
  name:'s2s-Hub-OnPrem'
  params: {
    location: location
    HubRgName: deployHUB ? hubRgName : 'none'
    HubGatewayID: deployGatewayInHub ? hubVnet.outputs.hubGatewayID : 'none'
    HubGatewayPublicIP: deployGatewayInHub ? hubVnet.outputs.hubGatewayPublicIP : 'none'
    HubAddressPrefixes: deployHUB ? AllAddressSpaces : []
    HubLocalGatewayName: deploySiteToSite ? 'LocalGateway-Hub' : 'none'
    OnPremRgName: deployOnPrem ? onpremRgName : 'none'
    OnPremGatewayID: deployGatewayinOnPrem ? onprem.outputs.OnPremGatewayID : 'none'
    OnPremGatewayPublicIP: deployGatewayinOnPrem ? onprem.outputs.OnPremGatewayPublicIP : 'none'
    OnPremAddressPrefixes: deployOnPrem ? array(onprem.outputs.OnPremAddressSpace) : []
    OnPremLocalGatewayName: deploySiteToSite ? 'LocalGateway-OnPrem' : 'none'
    tagsByResource: tagsByResource
  }
}

// Outputs
output AzureFirewallpip string = deployFirewallInHub && deployHUB ? hubVnet.outputs.azFwIp : 'none'
output HubVnetID string = deployHUB ? hubVnet.outputs.hubVnetID : 'none'
output HubVnetAddressSpace string = deployHUB ? hubVnet.outputs.hubVnetAddressSpace : 'none'
output HubGatewayPublicIP string = deployGatewayInHub ? hubVnet.outputs.hubGatewayPublicIP : 'none'
output HubGatewayID string = deployGatewayInHub ? hubVnet.outputs.hubGatewayID : 'none'
output OnPremVnetAddressSpace string = deployOnPrem ? onprem.outputs.OnPremAddressSpace : 'none'
output OnPremGatewayPublicIP string = deployGatewayinOnPrem ? onprem.outputs.OnPremGatewayPublicIP : 'none'
output OnPremGatewayID string = deployGatewayinOnPrem ? onprem.outputs.OnPremGatewayID : 'none'
output SpokeVnets array = [for i in range(0, amountOfSpokes): deploySpokes ? {
  SpokeVnetId: spokeVnets[i].outputs.spokeVnetID
  SpokeVnetAddressSpace: spokeVnets[i].outputs.spokeVnetAddressSpace
} : 'none']
