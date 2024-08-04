param location string
param bastionName string
param subnetID string
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param bastionSku string
param tagsByResource object = {}

resource bastion 'Microsoft.Network/bastionHosts@2024-01-01' = {
  name: bastionName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: subnetID
          }
          publicIPAddress: {
            id: bastionpip.id
          }
        }
      }
    ]
  }
  sku: {
    name: bastionSku
  }
  tags: tagsByResource[?'Microsoft.Network/bastionHosts'] ?? {}
}

resource bastionpip 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: '${bastionName}-pip'
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
