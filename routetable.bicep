param rtName string
param location string
param azFWip string

resource rt 'Microsoft.Network/routeTables@2021-05-01' = {
  name: rtName
  location: location
  properties: {
    routes: [
       {
          name: 'toInternet'
          properties: {
            nextHopType: 'VirtualAppliance'
            addressPrefix: '0.0.0.0/0'
            nextHopIpAddress: azFWip
          }
       }
    ]
  }
}

output rtID string = rt.id
