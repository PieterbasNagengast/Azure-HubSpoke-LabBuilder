param azFwPolicyName string
param ruleCollectiongroupName string = 'HubSpokeLabBuilderCollectionGroup'
param AddressSpace string
param SecondRegionAddressSpace string
param isMultiRegion bool

var addressSpaces = union(array(AddressSpace), isMultiRegion ? array(SecondRegionAddressSpace) : [])

resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-07-01' = {
  name: '${azFwPolicyName}/${ruleCollectiongroupName}'
  properties: {
    priority: 400
    ruleCollections: [
      {
        name: 'NetworkRules'
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        priority: 100
        rules: [
          {
            name: 'AllowLocalTraffic'
            ruleType: 'NetworkRule'
            sourceAddresses: addressSpaces
            destinationAddresses: addressSpaces
            ipProtocols: [
              'Any'
            ]
            destinationPorts: [
              '*'
            ]
          }
        ]
      }
      {
        name: 'ApplicationRules'
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        priority: 200
        rules: [
          {
            name: 'AllowHttpHttps'
            ruleType: 'ApplicationRule'
            sourceAddresses: [
              AddressSpace
            ]
            sourceIpGroups: []
            destinationAddresses: []
            terminateTLS: false
            fqdnTags: []
            webCategories: []
            targetUrls: []
            targetFqdns: [
              '*'
            ]
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
          }
        ]
      }
    ]
  }
}
