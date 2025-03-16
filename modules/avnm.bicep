param location string
param avnmName string
param tagsByResource object = {}

@allowed([
  'Connectivity'
  'Routing'
  'SecurityAdmin'
  'SecurityUser'
])
param avnmScopeAccesses array = [
  'Connectivity'
  'Routing'
  'SecurityAdmin'
  'SecurityUser'
]
param avnmSubscriptionScopes array

resource avnm 'Microsoft.Network/networkManagers@2024-05-01' = {
  name: avnmName
  location: location
  properties: {
    networkManagerScopeAccesses: avnmScopeAccesses
    networkManagerScopes: {
      subscriptions: avnmSubscriptionScopes
    }
  }
  tags: tagsByResource[?'Microsoft.Network/networkManagers'] ?? {}
}

output id string = avnm.id
output name string = avnm.name
