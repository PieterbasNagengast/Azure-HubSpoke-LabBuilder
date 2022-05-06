param location string
param bastionName string
param subnetID string
param bastionSku string = 'Basic'
param tagsByResource object = {}

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
  tags: contains(tagsByResource, 'Microsoft.Network/bastionHosts') ? tagsByResource['Microsoft.Network/bastionHosts'] : {}

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
  tags: contains(tagsByResource, 'Microsoft.Network/publicIPAddresses') ? tagsByResource['Microsoft.Network/publicIPAddresses'] : {}
}
