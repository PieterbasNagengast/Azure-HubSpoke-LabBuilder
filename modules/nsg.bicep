param location string
param nsgName string
param tagsByResource object = {}

param diagnosticWorkspaceId string

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: nsgName
  location: location
  tags: contains(tagsByResource, 'Microsoft.Network/networkSecurityGroups') ? tagsByResource['Microsoft.Network/networkSecurityGroups'] : {}
}

resource nsg_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticWorkspaceId))  {
  name: 'LabBuilder-diagnosticSettings'
  properties: {
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    logs: [
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
  scope: nsg
}

output nsgID string = nsg.id
