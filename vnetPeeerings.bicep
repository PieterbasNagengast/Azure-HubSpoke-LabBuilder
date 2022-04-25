param remoteVnetID string
param peeringName string
param allowForwardedTraffic bool = true
param allowGatewayTransit bool = true
param allowVirtualNetworkAccess bool = true
param useRemoteGateways bool = true

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: peeringName
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnetID
    }
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    useRemoteGateways: useRemoteGateways
  }
}
