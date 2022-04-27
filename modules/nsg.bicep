param location string
param nsgName string

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: nsgName
  location: location
}

output nsgID string = nsg.id
