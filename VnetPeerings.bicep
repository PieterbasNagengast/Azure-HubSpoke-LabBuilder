targetScope = 'subscription'
param HubResourceGroupName string
param SpokeResourceGroupName string
param HubVnetName string
param SpokeVnetName string
param HubVnetID string
param SpokeVnetID string
param counter int

resource hubrg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: HubResourceGroupName
}

module peeringToSpoke 'modules/vnetpeeering.bicep' = {
  scope: hubrg
  name: 'peeringToSpoke${counter+1}'
  params: {
    peeringName: '${HubVnetName}/peeringToSpoke${counter+1}'
    remoteVnetID: SpokeVnetID
    useRemoteGateways: false
    allowGatewayTransit: true
  }
  dependsOn: [
    peeringToHub
  ]
}

resource spokerg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: SpokeResourceGroupName
}

module peeringToHub 'modules/vnetpeeering.bicep' = {
  scope: spokerg
  name: 'peeringToHub${counter+1}'
  params: {
    peeringName: '${SpokeVnetName}/peeringToHub${counter+1}'
    remoteVnetID: HubVnetID
    useRemoteGateways: true 
    allowGatewayTransit: false
  }
}
