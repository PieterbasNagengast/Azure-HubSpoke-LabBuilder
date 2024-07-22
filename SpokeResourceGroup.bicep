targetScope = 'subscription'

param location string
param AddressSpace string
param counter int
param deployBastionInSpoke bool
param bastionSku string
param adminUsername string
@secure()
param adminPassword string
param deployVMsInSpokes bool
param deployFirewallInHub bool
param deployUDRs bool
param AzureFirewallpip string
param HubDeployed bool
param spokeRgNamePrefix string
param vmSize string
param tagsByResource object
param osType string
param hubDefaultSubnetPrefix string
param firewallDNSproxy bool

param diagnosticWorkspaceId string

param dcrID string

var vnetName = 'VNET-Spoke${counter}'
var vmName = 'VM-Spoke${counter}'
var rtName = 'RT-Spoke${counter}'
var nsgName = 'NSG-Spoke${counter}'
var bastionName = 'Bastion-Spoke${counter}'

var defaultSubnetPrefix = cidrSubnet(AddressSpace, 26, 0)
var bastionSubnetPrefix = cidrSubnet(AddressSpace, 27, 4)

resource spokerg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${spokeRgNamePrefix}${counter}'
  location: location
  tags: tagsByResource[?'Microsoft.Resources/subscriptions/resourceGroups']
    ? tagsByResource['Microsoft.Resources/subscriptions/resourceGroups']
    : {}
}

module vnet 'modules/vnet.bicep' = {
  scope: spokerg
  name: vnetName
  params: {
    location: location
    vnetAddressSpcae: AddressSpace
    nsgID: nsg.outputs.nsgID
    rtDefID: deployFirewallInHub && HubDeployed && deployUDRs ? rt.outputs.rtID : 'none'
    vnetname: vnetName
    defaultSubnetPrefix: defaultSubnetPrefix
    bastionSubnetPrefix: deployBastionInSpoke ? bastionSubnetPrefix : ''
    deployBastionSubnet: deployBastionInSpoke
    tagsByResource: tagsByResource
    firewallDNSproxy: firewallDNSproxy
    azFwIp: AzureFirewallpip
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
    diagnosticWorkspaceId: diagnosticWorkspaceId
    dcrID: dcrID
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
  name: bastionName
  params: {
    location: location
    subnetID: deployBastionInSpoke ? vnet.outputs.bastionSubnetID : ''
    bastionName: bastionName
    tagsByResource: tagsByResource
    bastionSku: bastionSku
  }
}

module rt 'modules/routetable.bicep' = if (deployFirewallInHub && HubDeployed && deployUDRs) {
  scope: spokerg
  name: rtName
  params: {
    location: location
    rtName: rtName
    tagsByResource: tagsByResource
  }
}

module route1 'modules/route.bicep' = if (deployFirewallInHub && HubDeployed && deployUDRs) {
  scope: spokerg
  name: 'RouteToInternet'
  params: {
    routeAddressPrefix: '0.0.0.0/0'
    routeName: deployFirewallInHub && HubDeployed && deployUDRs ? '${rt.outputs.rtName}/toInternet' : 'dummy1'
    routeNextHopIpAddress: deployFirewallInHub && HubDeployed && deployUDRs ? AzureFirewallpip : '1.2.3.4'
  }
}

module route2 'modules/route.bicep' = if (deployFirewallInHub && HubDeployed && deployUDRs) {
  scope: spokerg
  name: 'RouteToLocal'
  params: {
    routeAddressPrefix: hubDefaultSubnetPrefix
    routeName: deployFirewallInHub && HubDeployed && deployUDRs ? '${rt.outputs.rtName}/toHubDefaultSubnet' : 'dummy2'
    routeNextHopIpAddress: deployFirewallInHub && HubDeployed && deployUDRs ? AzureFirewallpip : '1.2.3.4'
  }
}

output spokeVnetID string = vnet.outputs.vnetID
output spokeVnetAddressSpace string = AddressSpace
output spokeResourceGroupName string = spokerg.name
output spokeVnetName string = vnet.outputs.vnetName
output spokeVmResourceID string = deployVMsInSpokes ? vm.outputs.vmResourceID : 'none'
