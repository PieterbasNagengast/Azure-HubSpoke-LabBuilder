param avnmName string
param avnmNetworkGroupId string
param AzFwPrivateIP string
param avnmRoutingConfigName string

resource avnmRoutingConfig 'Microsoft.Network/networkManagers/routingConfigurations@2024-05-01' = {
  name: '${avnmName}/${avnmRoutingConfigName}'
  properties: {
    description: 'LabBuilder AVNM - Routing Configuration'
  }
}

resource avnmRoutingConfigRuleCollection 'Microsoft.Network/networkManagers/routingConfigurations/ruleCollections@2024-05-01' = {
  name: '${avnmName}-RuleCollection'
  parent: avnmRoutingConfig
  properties: {
    description: 'LabBuilder AVNM - Routing Configuration Rule Collection'
    appliesTo: [
      {
        networkGroupId: avnmNetworkGroupId
      }
    ]
    disableBgpRoutePropagation: 'True'
  }
}

resource avnmRoutingConfigRuleCollectionsRule 'Microsoft.Network/networkManagers/routingConfigurations/ruleCollections/rules@2024-05-01' = {
  name: 'toInternet'
  parent: avnmRoutingConfigRuleCollection
  properties: {
    description: 'LabBuilder AVNM - Routing Configuration Rule'
    destination: {
      destinationAddress: '0.0.0.0/0'
      type: 'AddressPrefix'
    }
    nextHop: {
      nextHopType: 'VirtualAppliance'
      nextHopAddress: AzFwPrivateIP
    }
  }
}

output id string = avnmRoutingConfig.id
output name string = avnmRoutingConfig.name
