param location string
param avnmName string
param tagsByResource object = {}

@allowed([
  'Connectivity'
  'Routing'
  'SecurityAdmin'
])
param avnmScopeAccesses array = [
  'Connectivity'
  'Routing'
  'SecurityAdmin'
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

module userAssignedIdentity 'uai.bicep' = {
  name: 'UserAssignedIdentityForAVNM'
  params: {
    location: location
    uaiName: avnmName
    tagsByResource: tagsByResource
  }
}

module roleAssignment 'avnmroleassignment.bicep' = {
  name: 'RoleAssignmentForAVNMDeploymentScript'
  params: {
    principalID: userAssignedIdentity.outputs.principalID
    avnmName: avnmName
  }
}

output id string = avnm.id
output name string = avnm.name
output uaiId string = userAssignedIdentity.outputs.id
