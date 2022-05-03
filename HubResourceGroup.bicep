targetScope = 'subscription'

param location string
param startAddressSpace string
param deployBastionInHub bool
param adminUsername string
@secure()
param adminPassword string
param deployVMinHub bool
param deployFirewallInHub bool
param AzureFirewallTier string
param hubRgName string

var vmName = 'VM-Hub'
var vnetAddressSpace = '${startAddressSpace}0.0/24'
var defaultSubnetPrefix = replace(vnetAddressSpace, '/24', '/25')
var bastionSubnetPrefix = replace(vnetAddressSpace, '0/24', '192/26')
var firewallSubnetPrefix = replace(vnetAddressSpace, '0/24', '128/26')
var nsgName = 'NSG-Hub'
var bastionName = 'Bastion-Hub'
var rtName = 'RT-Hub'
var hubVnetName = 'VNET-Hub'
var firewallName = 'Firewall-Hub'

resource hubrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hubRgName
  location: location
}

module vnet 'modules/vnet.bicep' = {
  scope: hubrg
  name: 'hubvnet'
  params: {
    location: location
    vnetAddressSpcae: vnetAddressSpace
    bastionSubnetPrefix: bastionSubnetPrefix
    firewallSubnetPrefix: firewallSubnetPrefix
    nsgID: nsg.outputs.nsgID
    rtID: deployFirewallInHub ? rt.outputs.rtID : 'none'
    vnetname: hubVnetName
    defaultSubnetPrefix: defaultSubnetPrefix
    deployBastionSubnet: deployBastionInHub
    deployFirewallSubnet: deployFirewallInHub
  }
}

module vm 'modules/vm.bicep' = if (deployVMinHub) {
  scope: hubrg
  name: 'virtualMachine'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    location: location
    subnetID: vnet.outputs.defaultSubnetID
    vmName: vmName
  }
}

module nsg 'modules/nsg.bicep' = {
  scope: hubrg
  name: 'nsg'
  params: {
    location: location
    nsgName: nsgName
  }
}

module bastion 'modules/bastion.bicep' = if (deployBastionInHub) {
  scope: hubrg
  name: 'bastion'
  params: {
    location: location
    subnetID: deployBastionInHub ? vnet.outputs.bastionSubnetID : ''
    bastionName: bastionName
  }
}

module firewall 'modules/firewall.bicep' = if (deployFirewallInHub) {
  scope: hubrg
  name: 'hubFirewall'
  params: {
    location: location
    firewallName: firewallName
    azfwsubnetid: deployFirewallInHub ? vnet.outputs.firewallSubnetID : ''
    azfwTier: AzureFirewallTier
  }
}

module rt 'modules/routetable.bicep' = if (deployFirewallInHub) {
  scope: hubrg
  name: 'routeTable'
  params: {
    location: location
    rtName: rtName
  }
}

module route 'modules/route.bicep' = if (deployFirewallInHub) {
  scope: hubrg
  name: 'Route'
  params: {
    routeAddressPrefix: '0.0.0.0/0'
    routeName: deployFirewallInHub ? '${rt.outputs.rtName}/toInternet' : 'dummy'
    routeNextHopIpAddress: deployFirewallInHub ? firewall.outputs.azFwIP : '1.2.3.4'
  }
}

output hubVnetID string = vnet.outputs.vnetID
output azFwIp string =  deployFirewallInHub ? firewall.outputs.azFwIP : '1.2.3.4'
output HubResourceGroupName string = hubrg.name
output hubVnetName string = vnet.outputs.vnetName
