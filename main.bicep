// Shared parameters
@description('Deploy Spoke VNETs')
param DeploySpokes bool = true

@description('Admin username for VM')
param adminUsername string

@description('Admin Password for VM')
@secure()
param adminPassword string

@description('IP Address space used for VNETs in deployment. Only enter the two first octets of a /16 subnet. Default = 172.16.  ')
param startAddressSpace string = '172.16.'

@description('Azure Region. Defualt = Deployment location')
param location string = deployment().location

// Spoke VNET Parameters
@description('Amount of Spoke VNETs you want to deploy. Default = 2')
param amountOfSpokes int = 2

@description('Deploy VM in every Spoke VNET')
param deployVMsInSpokes bool = true

@description('Deploy Bastion Host in every Spoke VNET')
param deployBastionInSpoke bool = true

// Hub VNET Parameters
@description('Deploy Hub VNET')
param DeployHUB bool = true

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
param AzureFirewallTier string = 'Standard'

// variables
var hubVnetName = 'hub-vnet'

targetScope = 'subscription'

// Deploy Hub VNET including VM, Bastion Host, Route Table, Network Security group and Azure Firewall
module hubVnet 'HubResourceGroup.bicep' = if (DeployHUB) {
  name: 'HubResourceGroup'
  params: {
    deployBastionInHub: deployBastionInHub
    location: location
    startAddressSpace: startAddressSpace
    adminPassword: adminPassword
    adminUsername: adminUsername
    deployVMinHub: deployVMinHub
    deployFirewallInHub: deployFirewallInHub
    hubVnetName: hubVnetName
    AzureFirewallTier: AzureFirewallTier
  }
}

// Deploy Spoke VNET's
module spokeVnets 'SpokeResourceGroup.bicep' =  [for i in range(1, amountOfSpokes): if(DeploySpokes) {
  name: 'SpokeResourceGroup${i}'
  params: {
    location: location
    counter: i
    startAddressSpace: startAddressSpace
    deployBastionInSpoke: deployBastionInSpoke
    adminPassword: adminPassword
    adminUsername: adminUsername
    deployVMsInSpokes: deployVMsInSpokes
    deployFirewallInHub: deployFirewallInHub
    AzureFirewallpip: DeployHUB ? hubVnet.outputs.azFwIp : 'Not deployed'
    HubDeployed: DeployHUB
  }
}]

// VNET Peerings
module vnetPeerings 'Vnetpeerings.bicep' = [for i in range(0, amountOfSpokes): if (DeployHUB && DeploySpokes) {
  name: 'VnetPeering${i}'
  params: {
    HubResourceGroupName: hubVnet.outputs.HubResourceGroupName
    SpokeResourceGroupName: spokeVnets[i].outputs.spokeResourceGroupName
    HubVnetName: hubVnet.outputs.hubVnetName
    SpokeVnetID: spokeVnets[i].outputs.spokeVnetID
    HubVnetID:  hubVnet.outputs.hubVnetID
    SpokeVnetName: spokeVnets[i].outputs.spokeVnetName
    counter: i
  }
}]

output AzureFirewallpip string = deployFirewallInHub && DeployHUB ? hubVnet.outputs.azFwIp : 'none'
output HubVnetID string = DeployHUB ? hubVnet.outputs.hubVnetID : 'none'
output SpokeVnetIDs array = [for i in range(0, amountOfSpokes): DeploySpokes ? {
  SpokeVnetId: spokeVnets[i].outputs.spokeVnetID
}: 'none']

