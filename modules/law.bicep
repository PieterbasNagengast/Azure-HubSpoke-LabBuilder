param lawName string
param location string
param sku string = 'PerGB2018'
param retention int = 30
param tagsByResource object = {}

resource law 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: lawName
  location: location
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retention
  }
  tags: contains(tagsByResource, 'Microsoft.OperationalInsights/workspaces') ? tagsByResource['Microsoft.OperationalInsights/workspaces'] : {}
}

output resourceID string = law.id
output name string = law.name
