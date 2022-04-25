param location string
param vnetname string
param vnetAddressSpcae string
param deployBastionInHub bool

var defaultSubnetPrefix = replace(vnetAddressSpcae, '/24', '/25')
var bastionSubnetPrefix = replace(vnetAddressSpcae, '0/24', '192/26')
var firewallSubnetPrefix = replace(vnetAddressSpcae, '0/24', '128/26')

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
      {
        name: 'AzureFirewallSubnet' 
        properties: {
          addressPrefix: firewallSubnetPrefix
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

resource bastionPIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = if (deployBastionInHub) {
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

resource bastion 'Microsoft.Network/bastionHosts@2021-05-01' = if (deployBastionInHub) {
  name: '${vnetname}-Bastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
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

output hubSubnetID string = vnet.properties.subnets[0].id
output hubFWsubnetID string = vnet.properties.subnets[2].id
output hubVnetID string = vnet.id
