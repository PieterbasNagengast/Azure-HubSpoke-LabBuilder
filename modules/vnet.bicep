param location string
param vnetname string
param vnetAddressSpcae string
param defaultSubnetPrefix string
param bastionSubnetPrefix string = ''
param firewallSubnetPrefix string = ''
param GatewaySubnetPrefix string = ''
param nsgID string
param rtID string = 'none'
param deployBastionSubnet bool = false
param deployFirewallSubnet bool = false
param deployGatewaySubnet bool = false

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

var gatewaySubnet = !deployGatewaySubnet ? [] : [
  {
    name: 'GatewaySubnet'
    properties: {
      addressPrefix: GatewaySubnetPrefix
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
    subnets: concat(defaultSubnet, bastionSubnet, firewallSubnet, gatewaySubnet)
  }
}

output vnetName string = vnet.name
output vnetID string = vnet.id
output defaultSubnetID string = vnet.properties.subnets[0].id
output bastionSubnetID string = deployBastionSubnet ? resourceId('Microsoft.Network/VirtualNetworks/subnets',vnetname,'AzureBastionSubnet'): 'Not deployed' 
output firewallSubnetID string = deployFirewallSubnet ? resourceId('Microsoft.Network/VirtualNetworks/subnets',vnetname,'AzureFirewallSubnet'): 'Not deployed' 
output gatewaySubnetID string = deployGatewaySubnet ? resourceId('Microsoft.Network/VirtualNetworks/subnets',vnetname,'GatewaySubnet'): 'Not deployed' 
