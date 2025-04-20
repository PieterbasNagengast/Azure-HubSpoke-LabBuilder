param rtName string
param location string
param disableRouteProp bool = true
param tagsByResource object = {}
param isFirewallSubnet bool = false

resource rt 'Microsoft.Network/routeTables@2023-06-01' = {
  name: rtName
  location: location
  properties: {
    disableBgpRoutePropagation: disableRouteProp
    routes: isFirewallSubnet
      ? [
          {
            name: 'toInternet'
            properties: {
              nextHopType: 'Internet'
              addressPrefix: '0.0.0.0/0'
            }
          }
        ]
      : []
  }
  tags: tagsByResource[?'Microsoft.Network/routeTables'] ?? {}
}

output rtID string = rt.id
output rtName string = rt.name
