targetScope = 'subscription'
param location string
param startAddressSpace string
param counter int
param deployBastionInSpoke bool
param hubVnetID string
param adminUsername string
@secure()
param adminPassword string
param deployVMsInSpokes bool
param deployFirewallInHub bool
param azFWip string


var hubRgName = split(hubVnetID, '/')[4]
var hubVnetName = split(hubVnetID, '/')[8]
var vmName = 'VM-Spoke${counter}'
var rtName = 'RT-Spoke${counter}'

resource spokerg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-Spoke${counter}'
  location: location
}

module spoke 'SpokeVnet.bicep' = {
  name: 'Spoke-VNET-${counter}'
  scope: spokerg
  params: {
    location: location
    vnetname: 'Spoke-VNET-${counter}'
    vnetAddressSpcae: '${startAddressSpace}${counter}.0/24'
    deployBastionInSpoke: deployBastionInSpoke
    rtID: empty(rt.outputs.rtID)  ? '' : rt.outputs.rtID
  }
}

resource hubrg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: hubRgName
}

module peeringToHub 'vnetPeeerings.bicep' = {
  scope: spokerg
  name: 'peeringTo${hubVnetName}'
  params: {
    remoteVnetID: hubVnetID
    peeringName: '${spoke.name}/peeringTo${hubVnetName}'
    useRemoteGateways: false
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
  }
}

module peeringToSpoke 'vnetPeeerings.bicep' = {
  scope: hubrg
  name: 'peeringTo${spoke.name}'
  params: {
    remoteVnetID: spoke.outputs.spokeVnetID
    peeringName: '${hubVnetName}/peeringTo${spoke.name}'
    useRemoteGateways: false
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
  }
}

module vm 'vm.bicep' = if (deployVMsInSpokes) {
  scope: spokerg
  name: vmName
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    location: location
    subnetID: spoke.outputs.defaultSubnetID
    vmName: vmName
  }
}

module rt 'routetable.bicep' = if (deployFirewallInHub) {
  scope: spokerg
  name: rtName
  params: {
    location: location
    rtName: rtName
    azFWip: azFWip
  }
}
