param location string
param vWanName string
@allowed([
  'Standard'
  'Basic'
])
param vWanType string = 'Standard'
param tagsByResource object = {}
// param AddressPrefix string

resource vWan 'Microsoft.Network/virtualWans@2024-05-01' = {
  name: vWanName
  location: location
  properties: {
    type: vWanType
    disableVpnEncryption: false
    allowBranchToBranchTraffic: true
  }
  tags: tagsByResource[?'Microsoft.Network/virtualWans'] ?? {}
}

output ID string = vWan.id
