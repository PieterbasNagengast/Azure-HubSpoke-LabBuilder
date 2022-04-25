param location string
param vnetname string
param vnetAddressSpcae string
param deployBastionInSpoke bool
param rtID string

var defaultSubnetPrefix = replace(vnetAddressSpcae, '/24', '/25')
var bastionSubnetPrefix = replace(vnetAddressSpcae, '0/24', '192/26')

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetname
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpcae
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: defaultSubnetPrefix
          networkSecurityGroup: {
            id: nsg1.id
          }
          routeTable: {
            id: rtID
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: []
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: []
        }
      }
    ]
  }
}

resource nsg1 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${vnetname}-NSG-defaultSubent'
  location: location
}

resource bastionPIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = if (deployBastionInSpoke) {
  name: '${vnetname}-Bastion-Pip'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    tier: 'Regional'
    name: 'Standard'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-03-01' = if (deployBastionInSpoke) {
  name: '${vnetname}-Bastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.properties.subnets[1].id
          }
          publicIPAddress: {
            id: bastionPIP.id
          }
        }
      }
    ]
  }
  sku: {
    name: 'Basic'
  }
}

output defaultSubnetID string = vnet.properties.subnets[0].id
output spokeVnetID string = vnet.id
