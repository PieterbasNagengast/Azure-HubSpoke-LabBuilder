targetScope = 'subscription'
param location string
param startAddressSpace string
param deployBastionInSHub bool
param adminUsername string
@secure()
param adminPassword string
param deployVMinHub bool
param deployFirewallInHub bool

var vmName = 'VM-Hub1'

resource hubrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-Hub'
  location: location
}

module hub 'HubVnet.bicep' = {
  name: 'Hub-VNET'
  scope: hubrg
  params: {
    location: location
    vnetname: 'Hub-VNET'
    vnetAddressSpcae: '${startAddressSpace}0.0/24'
    deployBastionInHub: deployBastionInSHub
  }
}

module vm 'vm.bicep' = if (deployVMinHub) {
  scope: hubrg
  name: vmName
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    location: location
    subnetID: hub.outputs.hubSubnetID
    vmName: vmName
  }
}

module firewall 'firewall.bicep' = if (deployFirewallInHub) {
  name: 'firewall'
  scope: hubrg
  params: {
    location: location
    firewallName: 'AzFw'
    azfwsubnetid: hub.outputs.hubFWsubnetID
  }
}

output hubVnetID string = hub.outputs.hubVnetID
output azFwIP string = firewall.outputs.azFwIP

