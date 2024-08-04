param location string
param uaiName string
param tagsByResource object = {}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: '${uaiName}-${location}'
  location: location
  tags: tagsByResource[?'Microsoft.ManagedIdentity/userAssignedIdentities'] ?? {}
}

output id string = userAssignedIdentity.id
output name string = userAssignedIdentity.name
output principalID string = userAssignedIdentity.properties.principalId
