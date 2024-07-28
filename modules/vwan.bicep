param location string
param vWanName string
@allowed([
  'Standard'
  'Basic'
])
param vWanType string = 'Standard'
param tagsByResource object = {}
param AddressPrefix string

resource vWan 'Microsoft.Network/virtualWans@2022-11-01' = {
  name: vWanName
  location: location
  properties: {
    type: vWanType
    disableVpnEncryption: false
    allowBranchToBranchTraffic: true
  }
  tags: tagsByResource[?'Microsoft.Network/virtualWans'] ?? {}
}

resource vWanHub 'Microsoft.Network/virtualHubs@2022-11-01' = {
  name: 'HUB-${location}'
  location: location
  properties: {
    allowBranchToBranchTraffic: true
    hubRoutingPreference: 'ExpressRoute'
    virtualRouterAsn: 65515
    virtualRouterAutoScaleConfiguration: {
      minCapacity: 2
    }
    addressPrefix: AddressPrefix
    virtualWan: {
      id: vWan.id
    }
  }
}

output vWanID string = vWan.id
output vWanHubID string = vWanHub.id
output vWanHubAddressSpace string = vWanHub.properties.addressPrefix
output vWanHubName string = vWanHub.name
