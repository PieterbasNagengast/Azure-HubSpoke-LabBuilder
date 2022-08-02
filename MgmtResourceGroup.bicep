targetScope = 'subscription'

param location string
param mgmtRgName string 
param lawRetention int = 30
param tagsByResource object = {}

var lawName = 'LAW-MGMT'

resource mgmtrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: mgmtRgName
  location: location
  tags: contains(tagsByResource, 'Microsoft.Resources/subscriptions/resourceGroups') ? tagsByResource['Microsoft.Resources/subscriptions/resourceGroups'] : {}
}

module law 'modules/law.bicep' = {
  scope: mgmtrg
  name: lawName
  params: {
    lawName: lawName
    location: location
    retention: lawRetention
    tagsByResource: tagsByResource
  }
}

output LawResourceID string = law.outputs.resourceID
output LawName string = law.outputs.name
