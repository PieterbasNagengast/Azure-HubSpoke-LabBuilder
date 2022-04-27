param location string
param bastionName string
param subnetID string
param bastionSku string = 'Basic'

resource bastion 'Microsoft.Network/bastionHosts@2021-03-01' = {
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
}

resource bastionpip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
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
}
