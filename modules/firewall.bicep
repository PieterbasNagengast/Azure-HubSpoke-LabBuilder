param firewallName string
param location string
@allowed([
  'Standard'
  'Premium'
])
param azfwTier string
param azfwsubnetid string = ''
param tagsByResource object = {}
param vWanID string = ''
param vWanAzFwPublicIPcount int = 1
param deployInVWan bool = false
param firewallDNSproxy bool = false

var azfwSKUname = deployInVWan ? 'AZFW_Hub' : 'AZFW_VNet'

var pipName = '${firewallName}-pip'
var firewallPolicyName = '${firewallName}-policy'

resource azfw 'Microsoft.Network/azureFirewalls@2023-06-01' = {
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
    ipConfigurations: deployInVWan
      ? null
      : [
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
    virtualHub: deployInVWan
      ? {
          id: vWanID
        }
      : null
    hubIPAddresses: deployInVWan
      ? {
          publicIPs: {
            count: vWanAzFwPublicIPcount
          }
        }
      : null
  }
  tags: tagsByResource[?'Microsoft.Network/azureFirewalls'] ?? {}
}

resource azfwpolicy 'Microsoft.Network/firewallPolicies@2023-06-01' = {
  name: firewallPolicyName
  location: location
  properties: {
    sku: {
      tier: azfwTier
    }
    threatIntelMode: 'Alert'
    dnsSettings: {
      enableProxy: firewallDNSproxy
    }
  }
  tags: tagsByResource[?'Microsoft.Network/firewallPolicies'] ?? {}
}

resource azfwpip 'Microsoft.Network/publicIPAddresses@2023-06-01' = if (!deployInVWan) {
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
  tags: tagsByResource[?'Microsoft.Network/publicIPAddresses'] ?? {}
}

output azFwIP string = deployInVWan
  ? azfw.properties.hubIPAddresses.privateIPAddress
  : azfw.properties.ipConfigurations[0].properties.privateIPAddress
output azFwIPvWan array = deployInVWan ? azfw.properties.hubIPAddresses.publicIPs.addresses : []
output azFwID string = azfw.id
output azFwPolicyName string = azfwpolicy.name
