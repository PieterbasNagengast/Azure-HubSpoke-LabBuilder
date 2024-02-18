param location string
param nsgName string
param tagsByResource object = {}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: nsgName
  location: location
  tags: contains(tagsByResource, 'Microsoft.Network/networkSecurityGroups') ? tagsByResource['Microsoft.Network/networkSecurityGroups'] : {}
}

output nsgID string = nsg.id
