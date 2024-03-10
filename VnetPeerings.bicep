targetScope = 'subscription'
param HubResourceGroupName string
param SpokeResourceGroupName string
param HubVnetName string
param SpokeVnetName string
param HubVnetID string
param SpokeVnetID string
param counter int
param GatewayDeployed bool
param hubSubscriptionID string
param spokeSubscriptionID string

resource hubrg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  scope: subscription(hubSubscriptionID)
  name: HubResourceGroupName
}

module peeringToSpoke 'modules/vnetpeeering.bicep' = {
  scope: hubrg
  name: 'peeringToSpoke${counter + 1}'
  params: {
    peeringName: '${HubVnetName}/peeringToSpoke${counter + 1}'
    remoteVnetID: SpokeVnetID
    useRemoteGateways: false
    allowGatewayTransit: GatewayDeployed
  }
}

resource spokerg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  scope: subscription(spokeSubscriptionID)
  name: SpokeResourceGroupName
}

module peeringToHub 'modules/vnetpeeering.bicep' = {
  scope: spokerg
  name: 'peeringToHub${counter + 1}'
  params: {
    peeringName: '${SpokeVnetName}/peeringToHub${counter + 1}'
    remoteVnetID: HubVnetID
    useRemoteGateways: GatewayDeployed
    allowGatewayTransit: false
  }
  dependsOn: [
    peeringToSpoke
  ]
}
