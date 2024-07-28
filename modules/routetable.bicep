param rtName string
param location string
param disableRouteProp bool = true
param tagsByResource object = {}

resource rt 'Microsoft.Network/routeTables@2023-06-01' = {
  name: rtName
  location: location
  properties: {
    disableBgpRoutePropagation: disableRouteProp
  }
  tags: tagsByResource[?'Microsoft.Network/routeTables'] ?? {}
}

output rtID string = rt.id
output rtName string = rt.name
