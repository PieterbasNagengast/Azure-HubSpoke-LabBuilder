targetScope = 'subscription'

param location string
param shortLocationCode string
param AddressSpace string
param counter int
param adminUsername string
@secure()
param adminPassword string
param deployVMsInSpokes bool
param deployFirewallInHub bool
param deployUDRs bool
param AzureFirewallpip string
param HubDeployed bool
param spokeRgName string
param vmSize string
param tagsByResource object
param osType string
param firewallDNSproxy bool
param defaultOutboundAccess bool

param diagnosticWorkspaceId string

param dcrID string

var vnetName = 'VNET-Spoke${counter}-${shortLocationCode}'
var vmName = 'VM-Spoke${counter}-${shortLocationCode}'
var rtName = 'RT-Spoke${counter}-${shortLocationCode}'
var nsgName = 'NSG-Spoke${counter}-${shortLocationCode}'

var defaultSubnetPrefix = cidrSubnet(AddressSpace, 26, 0)

resource spokerg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: spokeRgName
  location: location
  tags: tagsByResource[?'Microsoft.Resources/subscriptions/resourceGroups'] ?? {}
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
    deployDefaultSubnet: true
    defaultSubnetPrefix: defaultSubnetPrefix
    tagsByResource: tagsByResource
    firewallDNSproxy: firewallDNSproxy
    azFwIp: AzureFirewallpip
    defaultOutboundAccess: defaultOutboundAccess
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

output spokeVnetID string = vnet.outputs.vnetID
