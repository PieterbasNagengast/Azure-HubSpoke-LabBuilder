param location string
param uaiName string
param tagsByResource object = {}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: '${uaiName}-${location}'
  location: location
  tags: contains(tagsByResource, 'Microsoft.ManagedIdentity/userAssignedIdentities') ? tagsByResource['Microsoft.ManagedIdentity/userAssignedIdentities'] : {}
}

output id string = userAssignedIdentity.id
output name string = userAssignedIdentity.name
output principalID string = userAssignedIdentity.properties.principalId
