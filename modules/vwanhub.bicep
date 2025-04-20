param location string
param shortLocationCode string
param vWanID string
param tagsByResource object = {}
param AddressPrefix string

resource vWanHub 'Microsoft.Network/virtualHubs@2024-05-01' = {
  name: 'HUB-${shortLocationCode}'
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
      id: vWanID
    }
  }
  tags: tagsByResource[?'Microsoft.Network/virtualHubs'] ?? {}
}

output ID string = vWanHub.id
output Name string = vWanHub.name
