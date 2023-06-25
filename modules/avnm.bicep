param location string
param avnmName string
param tagsByResource object = {}

@allowed([
  'Connectivity'
  'SecurityAdmin'
])
param avnmScopeAccesses array = [
  'Connectivity'
]
param avnmSubscriptionScopes array

resource avnm 'Microsoft.Network/networkManagers@2022-11-01' = {
  name: avnmName
  location: location
  properties: {
    networkManagerScopeAccesses: avnmScopeAccesses
    networkManagerScopes: {
      subscriptions: avnmSubscriptionScopes
    }
  }
  tags: contains(tagsByResource, 'Microsoft.Network/networkManagers') ? tagsByResource['Microsoft.Network/networkManagers'] : {}
}

output id string = avnm.id
output name string = avnm.name
