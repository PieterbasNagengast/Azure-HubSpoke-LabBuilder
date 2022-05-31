param location string
param vWanName string
@allowed([
  'Standard'
  'Basic'
])
param vWanType string = 'Standard'
param tagsByResource object = {}
param AddressPrefix string

resource vWan 'Microsoft.Network/virtualWans@2021-05-01' = {
  name: vWanName
  location: location
  properties: {
    type: vWanType
    disableVpnEncryption: false
    allowBranchToBranchTraffic: true
  }
  tags: contains(tagsByResource, 'Microsoft.Network/virtualWans') ? tagsByResource['Microsoft.Network/virtualWans'] : {}
}

resource vWanHub 'Microsoft.Network/virtualHubs@2021-05-01' = {
  name: 'HUB-${location}'
  location: location
  properties: {
    addressPrefix: AddressPrefix
    virtualWan: {
      id: vWan.id
    }    
  }
  tags: contains(tagsByResource, 'Microsoft.Network/virtualHubs') ? tagsByResource['Microsoft.Network/virtualHubs'] : {}
}

output vWanID string = vWan.id
output vWanHubID string = vWanHub.id
output vWanHubAddressSpace string = vWanHub.properties.addressPrefix
output vWanHubName string= vWanHub.name
