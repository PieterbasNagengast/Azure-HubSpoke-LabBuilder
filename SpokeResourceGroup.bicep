targetScope = 'subscription'

param location string
param AddressSpace string
param counter int
param deployBastionInSpoke bool
param adminUsername string
@secure()
param adminPassword string
param deployVMsInSpokes bool
param deployFirewallInHub bool
param AzureFirewallpip string
param HubDeployed bool
param spokeRgNamePrefix string
param vmSize string
param tagsByResource object
param osType string

var vnetName = 'VNET-Spoke${counter}'
var vmName = 'VM-Spoke${counter}'
var rtName = 'RT-Spoke${counter}'
var nsgName = 'NSG-Spoke${counter}'
var bastionName = 'Bastion-Spoke${counter}'

var vnetAddressSpace = replace(AddressSpace,'0.0/16', '${counter}.0/24')
var defaultSubnetPrefix = replace(vnetAddressSpace, '/24', '/26')
var bastionSubnetPrefix = replace(vnetAddressSpace, '0/24', '128/27')

resource spokerg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${spokeRgNamePrefix}${counter}'
  location: location
}

module vnet 'modules/vnet.bicep' = {
  scope: spokerg
  name: vnetName
  params: {
    location: location
    vnetAddressSpcae: vnetAddressSpace
    nsgID: nsg.outputs.nsgID
    rtID: deployFirewallInHub && HubDeployed ? rt.outputs.rtID : 'none'
    vnetname: vnetName
    defaultSubnetPrefix: defaultSubnetPrefix
    bastionSubnetPrefix: deployBastionInSpoke ? bastionSubnetPrefix : ''
    deployBastionSubnet: deployBastionInSpoke
    tagsByResource: tagsByResource
  }
}

module vm 'modules/vm.bicep' = if (deployVMsInSpokes) {
  scope: spokerg
  name: vmName
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    location: location
    subnetID: vnet.outputs.defaultSubnetID
    vmName: vmName
    vmSize: vmSize
    tagsByResource: tagsByResource
    osType: osType
  }
}

module nsg 'modules/nsg.bicep' = {
  scope: spokerg
  name: nsgName
  params: {
    location: location
    nsgName: nsgName
    tagsByResource: tagsByResource
  }
}

module bastion 'modules/bastion.bicep' = if (deployBastionInSpoke) {
  scope: spokerg
  name: 'bastion'
  params: {
    location: location
    subnetID: deployBastionInSpoke ? vnet.outputs.bastionSubnetID : ''
    bastionName: bastionName
    tagsByResource: tagsByResource
  }
}

module rt 'modules/routetable.bicep' = if (deployFirewallInHub && HubDeployed) {
  scope: spokerg
  name: rtName
  params: {
    location: location
    rtName: rtName
    tagsByResource: tagsByResource
  }
}

module route 'modules/route.bicep' = if (deployFirewallInHub && HubDeployed) {
  scope: spokerg
  name: 'Route'
  params: {
    routeAddressPrefix: '0.0.0.0/0'
    routeName: deployFirewallInHub && HubDeployed ? '${rt.outputs.rtName}/toInternet' : 'none'
    routeNextHopIpAddress: deployFirewallInHub && HubDeployed ? AzureFirewallpip : '1.2.3.4'
  }
}

output spokeVnetID string = vnet.outputs.vnetID
output spokeVnetAddressSpace string = vnetAddressSpace
output spokeResourceGroupName string = spokerg.name
output spokeVnetName string = vnet.outputs.vnetName
