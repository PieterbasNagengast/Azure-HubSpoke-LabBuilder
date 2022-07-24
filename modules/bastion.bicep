param location string
param bastionName string
param subnetID string
@allowed([
  'Basic'
  'Standard'
])
param bastionSku string
param tagsByResource object = {}

param diagnosticWorkspaceId string

resource bastion 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: bastionName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: subnetID
          }
          publicIPAddress: {
            id: bastionpip.id
          }
        }
      }
    ]
  }
  sku: {
    name: bastionSku
  }
  tags: contains(tagsByResource, 'Microsoft.Network/bastionHosts') ? tagsByResource['Microsoft.Network/bastionHosts'] : {}
}

resource bastion_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticWorkspaceId))  {
  name: 'LabBuilder-diagnosticSettings'
  properties: {
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
  scope: bastion
}

resource bastionpip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${bastionName}-pip'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    tier: 'Regional'
    name: 'Standard'
  }
  tags: contains(tagsByResource, 'Microsoft.Network/publicIPAddresses') ? tagsByResource['Microsoft.Network/publicIPAddresses'] : {}
}

resource bastionpip_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticWorkspaceId))  {
  name: 'LabBuilder-diagnosticSettings'
  properties: {
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
  scope: bastionpip
}
