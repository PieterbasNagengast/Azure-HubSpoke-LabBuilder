targetScope = 'subscription'

param vnetIDA string
param useRemoteGatewaysVnetA bool = false
param allowGatewayTransitVnetA bool = false
param vnetIDB string
param useRemoteGatewaysVnetB bool = false
param allowGatewayTransitVnetB bool = false

var subscriptionA = split(vnetIDA, '/')[2]
var subscriptionB = split(vnetIDB, '/')[2]

var rgNameA = split(vnetIDA, '/')[4]
var rgNameB = split(vnetIDB, '/')[4]

var vnetNameA = split(vnetIDA, '/')[8]
var vnetNameB = split(vnetIDB, '/')[8]

resource rgA 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  scope: subscription(subscriptionA)
  name: rgNameA
}

module peeringToSpoke 'modules/vnetpeeering.bicep' = {
  scope: rgA
  name: 'peeringTo${vnetNameB}'
  params: {
    peeringName: '${vnetNameA}/peeringTo${vnetNameB}'
    remoteVnetID: vnetIDB
    useRemoteGateways: useRemoteGatewaysVnetA
    allowGatewayTransit: allowGatewayTransitVnetA
  }
}

resource rgB 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  scope: subscription(subscriptionB)
  name: rgNameB
}

module peeringToHub 'modules/vnetpeeering.bicep' = {
  scope: rgB
  name: 'peeringTo${vnetNameA}'
  params: {
    peeringName: '${vnetNameB}/peeringTo${vnetNameA}'
    remoteVnetID: vnetIDA
    useRemoteGateways: useRemoteGatewaysVnetB
    allowGatewayTransit: allowGatewayTransitVnetB
  }
}
