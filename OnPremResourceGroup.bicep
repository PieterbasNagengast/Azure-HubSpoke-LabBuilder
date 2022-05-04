targetScope = 'subscription'

param location string
param AddressSpace string 
param deployBastionInOnPrem bool = false
param adminUsername string
@secure()
param adminPassword string
param deployVMsInOnPrem bool = false
param deployGatewayInOnPrem bool = false
param OnPremRgName string

var vnetName = 'VNET-OnPrem'
var vmName = 'VM-OnPrem'
var nsgName = 'NSG-OnPrem'
var bastionName = 'Bastion-OnPrem'
var gatewayName = 'Gateway-OnPrem'

var vnetAddressSpace = replace(AddressSpace,'0.0/16', '255.0/24')
var defaultSubnetPrefix = replace(vnetAddressSpace, '/24', '/26')
var bastionSubnetPrefix = replace(vnetAddressSpace, '0/24', '128/27')
var gatewaySubnetPrefix = replace(vnetAddressSpace, '0/24', '160/27')

resource onpremrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: OnPremRgName
  location: location
}

module vnet 'modules/vnet.bicep' = {
  scope: onpremrg
  name: vnetName
  params: {
    location: location
    vnetAddressSpcae: vnetAddressSpace
    nsgID: nsg.outputs.nsgID
    vnetname: vnetName
    defaultSubnetPrefix: defaultSubnetPrefix
    bastionSubnetPrefix: deployBastionInOnPrem ? bastionSubnetPrefix : ''
    GatewaySubnetPrefix: gatewaySubnetPrefix
    deployBastionSubnet: deployBastionInOnPrem
    deployGatewaySubnet: true
  }
}

module vm 'modules/vm.bicep' = if (deployVMsInOnPrem) {
  scope: onpremrg
  name: vmName
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    location: location
    subnetID: vnet.outputs.defaultSubnetID
    vmName: vmName
  }
}

module nsg 'modules/nsg.bicep' = {
  scope: onpremrg
  name: nsgName
  params: {
    location: location
    nsgName: nsgName
  }
}

module bastion 'modules/bastion.bicep' = if (deployBastionInOnPrem) {
  scope: onpremrg
  name: bastionName
  params: {
    location: location
    subnetID: deployBastionInOnPrem ? vnet.outputs.bastionSubnetID : ''
    bastionName: bastionName
  }
}

module vpngw 'modules/vpngateway.bicep' = if (deployGatewayInOnPrem) {
  scope: onpremrg
  name: 'Gateway'
  params: {
    location: location
    vpnGatewayName: gatewayName
    vpnGatewaySubnetID: deployGatewayInOnPrem ? vnet.outputs.gatewaySubnetID : ''
  }
}

output OnPremGatewayPublicIP string = deployGatewayInOnPrem ? vpngw.outputs.vpnGwPublicIP : 'none'
output OnPremGatewayID string = deployGatewayInOnPrem ? vpngw.outputs.vpnGwID : 'none'
output OnPremAddressSpace string = vnetAddressSpace
