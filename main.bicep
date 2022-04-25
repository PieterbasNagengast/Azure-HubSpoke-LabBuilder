param amountOfSpokes int = 2
param location string = deployment().location
param startAddressSpace string = '172.16.'
param deployBastionInSpoke bool = false
param deployBastionInSHub bool = true
param deployVMsInSpokes bool = true
param deployVMinHub bool = true
param adminUsername string
@secure()
param adminPassword string
param deployFirewallInHub bool = true

targetScope = 'subscription'

// Deploy Hub VNET
module hubVnet 'HubResourceGroup.bicep' = {
  name: 'HubResourceGroup'
  params: {
    deployBastionInSHub: deployBastionInSHub
    location: location
    startAddressSpace: startAddressSpace
    adminPassword: adminPassword
    adminUsername: adminUsername
    deployVMinHub: deployVMinHub
    deployFirewallInHub: deployFirewallInHub
  }
}

// Deploy Spoke VNET's
module spokeVnets 'SpokeResourceGroup.bicep' = [for i in range(1, amountOfSpokes): {
  name: 'SpokeResourceGroup${i}'
  params: {
    location: location
    counter: i
    startAddressSpace: startAddressSpace
    deployBastionInSpoke: deployBastionInSpoke
    hubVnetID: hubVnet.outputs.hubVnetID
    adminPassword: adminPassword
    adminUsername: adminUsername
    deployVMsInSpokes: deployVMsInSpokes
    deployFirewallInHub: deployFirewallInHub
    azFWip: hubVnet.outputs.azFwIP
  }
}]
