targetScope = 'subscription'

param location string
param shortLocationCode string
param AddressSpace string
param deployBastionInOnPrem bool
param bastionSku string
param adminUsername string
@secure()
param adminPassword string
param deployVMsInOnPrem bool
param deployGatewayInOnPrem bool
param OnPremRgName string
param vmSize string
param tagsByResource object
param osType string

param vpnGwEnebaleBgp bool
param vpnGwBgpAsn int

param dcrID string

var vnetName = 'VNET-OnPrem-${shortLocationCode}'
var vmName = 'VM-OnPrem-${shortLocationCode}'
var nsgName = 'NSG-OnPrem-${shortLocationCode}'
var bastionName = 'Bastion-OnPrem-${shortLocationCode}'
var gatewayName = 'Gateway-OnPrem-${shortLocationCode}'
var bastionNsgName = 'NSG-Bastion-OnPrm-${shortLocationCode}'
var varOnPremRgName = '${OnPremRgName}-${shortLocationCode}'

var defaultSubnetPrefix = cidrSubnet(AddressSpace, 26, 0)
var bastionSubnetPrefix = cidrSubnet(AddressSpace, 26, 1)
var gatewaySubnetPrefix = cidrSubnet(AddressSpace, 26, 2)

// Create a resource group
resource onpremrg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: varOnPremRgName
  location: location
  tags: tagsByResource[?'Microsoft.Resources/subscriptions/resourceGroups'] ?? {}
}

module bastioNsg 'modules/nsg.bicep' = if (deployBastionInOnPrem) {
  scope: onpremrg
  name: bastionNsgName
  params: {
    location: location
    nsgName: bastionNsgName
    isBastionNSG: true
    tagsByResource: tagsByResource
  }
}

// Create a VNET
module vnet 'modules/vnet.bicep' = {
  scope: onpremrg
  name: vnetName
  params: {
    location: location
    vnetAddressSpcae: AddressSpace
    nsgID: nsg.outputs.nsgID
    bastionNSGID: deployBastionInOnPrem ? bastioNsg.outputs.nsgID : 'none'
    vnetname: vnetName
    deployDefaultSubnet: true
    defaultSubnetPrefix: defaultSubnetPrefix
    bastionSubnetPrefix: bastionSubnetPrefix
    GatewaySubnetPrefix: gatewaySubnetPrefix
    deployBastionSubnet: deployBastionInOnPrem
    deployGatewaySubnet: deployGatewayInOnPrem
    tagsByResource: tagsByResource
  }
}

// Create a VM
module vm 'modules/vm.bicep' = if (deployVMsInOnPrem) {
  scope: onpremrg
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
    dcrID: dcrID
  }
}

// Create a NSG
module nsg 'modules/nsg.bicep' = {
  scope: onpremrg
  name: nsgName
  params: {
    location: location
    nsgName: nsgName
    tagsByResource: tagsByResource
  }
}

// Create a Bastion
module bastion 'modules/bastion.bicep' = if (deployBastionInOnPrem) {
  scope: onpremrg
  name: bastionName
  params: {
    location: location
    subnetID: deployBastionInOnPrem ? vnet.outputs.bastionSubnetID : ''
    bastionName: bastionName
    tagsByResource: tagsByResource
    bastionSku: bastionSku
  }
}

// Create a VPN Gateway
module vpngw 'modules/vpngateway.bicep' = if (deployGatewayInOnPrem) {
  scope: onpremrg
  name: gatewayName
  params: {
    location: location
    vpnGatewayName: gatewayName
    vpnGatewaySubnetID: deployGatewayInOnPrem ? vnet.outputs.gatewaySubnetID : ''
    tagsByResource: tagsByResource
    vpnGatewayBgpAsn: vpnGwEnebaleBgp ? vpnGwBgpAsn : 65515
    vpnGatewayEnableBgp: vpnGwEnebaleBgp
  }
}

output OnPremRgName string = onpremrg.name
output OnPremGatewayPublicIP string = deployGatewayInOnPrem ? vpngw.outputs.vpnGwPublicIP : 'none'
output OnPremGatewayID string = deployGatewayInOnPrem ? vpngw.outputs.vpnGwID : 'none'
output OnPremAddressSpace string = AddressSpace
output OnPremGwBgpPeeringAddress string = deployGatewayInOnPrem ? vpngw.outputs.vpnGwBgpPeeringAddress : 'none'
output OnPremGwBgpAsn int = deployGatewayInOnPrem && vpnGwEnebaleBgp ? vpngw.outputs.vpnGwAsn : 0
