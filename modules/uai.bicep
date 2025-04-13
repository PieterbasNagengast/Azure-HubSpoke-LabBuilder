param location string
param uaiName string
param tagsByResource object = {}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: '${uaiName}-${location}'
  location: location
  tags: tagsByResource[?'Microsoft.ManagedIdentity/userAssignedIdentities'] ?? {}
}

output id string = userAssignedIdentity.id
output name string = userAssignedIdentity.name
output principalID string = userAssignedIdentity.properties.principalId
