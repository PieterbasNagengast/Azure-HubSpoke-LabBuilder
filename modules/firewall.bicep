param firewallName string
param location string
param azfwSKUname string = 'AZFW_VNet'
param azfwTier string
param azfwsubnetid string
param tagsByResource object = {}

var pipName = '${firewallName}-pip'
var firewallPolicyName = '${firewallName}-policy'

resource azfw 'Microsoft.Network/azureFirewalls@2021-05-01' = {
  name: firewallName
  location: location
  zones: []
  properties: {
    sku: {
      name: azfwSKUname
      tier: azfwTier
    }
    firewallPolicy: {
       id: azfwpolicy.id
    }
    ipConfigurations: [
      {
        properties: {
          publicIPAddress: {
            id: azfwpip.id
          }
          subnet: {
            id: azfwsubnetid
          }
        }
        name: 'ipconfig1'
      }
    ]
  }
  tags: contains(tagsByResource, 'Microsoft.Network/azureFirewalls') ? tagsByResource['Microsoft.Network/azureFirewalls'] : {}

}

resource azfwpolicy 'Microsoft.Network/firewallPolicies@2021-05-01' = {
  name: firewallPolicyName
  location: location
  properties: {
    sku: {
      tier: azfwTier
    }
  }
  tags: contains(tagsByResource, 'Microsoft.Network/firewallPolicies') ? tagsByResource['Microsoft.Network/firewallPolicies'] : {}

}

resource azfwpip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: pipName
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    tier: 'Regional'
    name: 'Standard'
  }
  tags: contains(tagsByResource, 'Microsoft.Network/publicIPAddresses') ? tagsByResource['Microsoft.Network/publicIPAddresses'] : {}

}

output azFwIP string = azfw.properties.ipConfigurations[0].properties.privateIPAddress
output azFwPolicyName string = azfwpolicy.name
