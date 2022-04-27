param rtName string
param location string
param disableRouteProp bool = true

resource rt 'Microsoft.Network/routeTables@2021-05-01' = {
  name: rtName
  location: location
  properties: {
    disableBgpRoutePropagation: disableRouteProp
  }
}

output rtID string = rt.id
output rtName string = rt.name
