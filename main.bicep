targetScope = 'subscription'

// Shared parameters
@description('Admin username for VM')
param adminUsername string = ''

@description('Admin Password for VM')
@secure()
param adminPassword string = ''

@description('IP Address space used for VNETs in deployment. Only enter a /16 subnet. Default = 172.16.0.0/16')
param AddressSpace string = '172.16.0.0/16'

@description('Azure Region. Defualt = Deployment location')
param location string = deployment().location

// Spoke VNET Parameters
@description('Deploy Spoke VNETs')
param deploySpokes bool = true

@description('Spoke resource group prefix name')
param spokeRgNamePrefix string = 'rg-spoke'

@description('Amount of Spoke VNETs you want to deploy. Default = 2')
param amountOfSpokes int = 2

@description('Deploy VM in every Spoke VNET')
param deployVMsInSpokes bool = true

@description('Deploy Bastion Host in every Spoke VNET')
param deployBastionInSpoke bool = false

// Hub VNET Parameters
@description('Deploy Hub VNET')
param deployHUB bool = true

@description('Hub resource group pre-fix name')
param hubRgName string = 'rg-hub'

@description('Deploy Bastion Host in Hub VNET')
param deployBastionInHub bool = true

@description('Deploy VM in Hub VNET')
param deployVMinHub bool = true

@description('Deploy Azure Firewall in Hub VNET. includes deployment of custom route tables in Spokes and Hub VNETs')
param deployFirewallInHub bool = true

@description('Azure Firewall Tier: Standard or Premium')
@allowed([
  'Standard'
  'Premium'
])
param AzureFirewallTier string = 'Premium'

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
  }
}

// Deploy Spoke VNET's including VM, Bastion Host, Route Table, Network Security group
module spokeVnets 'SpokeResourceGroup.bicep' =  [for i in range(1, amountOfSpokes): if(deploySpokes) {
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
    HubVnetID:  deployHUB && deploySpokes ? hubVnet.outputs.hubVnetID : 'No VNET peering'
    SpokeVnetName: deployHUB && deploySpokes ? spokeVnets[i].outputs.spokeVnetName : 'No VNET peering'
    counter: i
  }
}]

output AzureFirewallpip string = deployFirewallInHub && deployHUB ? hubVnet.outputs.azFwIp : 'none'
output HubVnetID string = deployHUB ? hubVnet.outputs.hubVnetID : 'none'
output SpokeVnetIDs array = [for i in range(0, amountOfSpokes): deploySpokes ? {
  SpokeVnetId: spokeVnets[i].outputs.spokeVnetID
}: 'none']

