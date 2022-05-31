param location string
param vnetname string
param vnetAddressSpcae string
param defaultSubnetPrefix string
param bastionSubnetPrefix string = ''
param firewallSubnetPrefix string = ''
param GatewaySubnetPrefix string = ''
param nsgID string
param rtDefID string = 'none'
param rtGwID string = 'none'
param deployBastionSubnet bool = false
param deployFirewallSubnet bool = false
param deployGatewaySubnet bool = false
param tagsByResource object = {}

var defaultSubnet = [
  {
    name: 'default'
    properties: {
      addressPrefix: defaultSubnetPrefix
      networkSecurityGroup: {
        id: nsgID
      }
      routeTable: rtDefID == 'none' ? json('null') : json('{"id": "${rtDefID}"}"')
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

var gatewaySubnet = !deployGatewaySubnet && !deployFirewallSubnet ? [] : [
  {
    name: 'GatewaySubnet'
    properties: {
      addressPrefix: GatewaySubnetPrefix
      routeTable: rtGwID == 'none' ? json('null') : json('{"id": "${rtGwID}"}"')
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
  tags: contains(tagsByResource, 'Microsoft.Network/virtualNetworks') ? tagsByResource['Microsoft.Network/virtualNetworks'] : {}
}

output vnetName string = vnet.name
output vnetID string = vnet.id
output defaultSubnetID string = vnet.properties.subnets[0].id
output bastionSubnetID string = deployBastionSubnet ? resourceId('Microsoft.Network/VirtualNetworks/subnets',vnetname,'AzureBastionSubnet'): 'Not deployed' 
output firewallSubnetID string = deployFirewallSubnet ? resourceId('Microsoft.Network/VirtualNetworks/subnets',vnetname,'AzureFirewallSubnet'): 'Not deployed' 
output gatewaySubnetID string = deployGatewaySubnet ? resourceId('Microsoft.Network/VirtualNetworks/subnets',vnetname,'GatewaySubnet'): 'Not deployed' 
