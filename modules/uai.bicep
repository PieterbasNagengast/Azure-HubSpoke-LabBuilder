param location string
param uaiName string

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: '${uaiName}-${location}'
  location: location
}

output id string = userAssignedIdentity.id
output name string = userAssignedIdentity.name
output principalID string = userAssignedIdentity.properties.principalId
