targetScope = 'subscription'
param SpokeResourceGroupName string
param SpokeVnetName string
param spokeVnets array
param spokeSubscriptionID string

resource spokerg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  scope: subscription(spokeSubscriptionID)
  name: SpokeResourceGroupName
}

module peeringToHub 'modules/vnetpeeering.bicep' = [for spokeVnet in spokeVnets: if (SpokeVnetName != spokeVnet.Name) {
  scope: spokerg
  name: 'peeringMesh${SpokeVnetName}To${spokeVnet.Name}'
  params: {
    peeringName: '${SpokeVnetName}/peeringMesh${SpokeVnetName}To${spokeVnet.Name}'
    remoteVnetID: spokeVnet.ID
    useRemoteGateways: false
    allowGatewayTransit: false
  }
}]
