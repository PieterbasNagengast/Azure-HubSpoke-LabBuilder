param location string
param vnetname string
param vnetAddressSpcae string
param defaultSubnetPrefix string
param bastionSubnetPrefix string
param firewallSubnetPrefix string
param nsgID string
param rtID string
param deployBastionSubnet bool
param deployFirewallSubnet bool = false

var defaultSubnet = [
  {
    name: 'default'
    properties: {
      addressPrefix: defaultSubnetPrefix
      networkSecurityGroup: {
        id: nsgID
      }
      routeTable: rtID == 'none' ? json('null') : json('{"id": "${rtID}"}"')
    }
  }
]

var bastionSubnet = !deployBastionSubnet ? [] : [
  {
    name: 'AzureBastionSubnet'
    properties: {
      addressPrefix: bastionSubnetPrefix
    }
  }
]

var firewallSubnet = !deployFirewallSubnet ? [] : [
  {
    name: 'AzureFirewallSubnet'
    properties: {
      addressPrefix: firewallSubnetPrefix
    }
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetname
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpcae
      ]
    }
    subnets: concat(defaultSubnet, bastionSubnet, firewallSubnet)
  }
}

output vnetName string = vnet.name
output vnetID string = vnet.id
output defaultSubnetID string = vnet.properties.subnets[0].id
output bastionSubnetID string = deployBastionSubnet ? vnet.properties.subnets[1].id : 'Not deployed'
output firewallSubnetID string = deployFirewallSubnet ? vnet.properties.subnets[2].id : 'Not deployed'
