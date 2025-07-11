param principalID string
@allowed([
  'ServicePrincipal'
  'Group'
  'User'
  'ForeignGroup'
])
param principalType string = 'ServicePrincipal'
param roleID string = '4d97b98b-1d4f-4787-a291-c67834d212e7' // Network Contributor: 4d97b98b-1d4f-4787-a291-c67834d212e7
param avnmName string

resource avnmExisting 'Microsoft.Network/networkManagers@2024-05-01' existing = {
  name: avnmName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: avnmExisting
  name: guid(resourceGroup().id, principalID)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleID)
    principalId: principalID
    principalType: principalType
  }
}

output id string = roleAssignment.id
