param remoteVnetID string
param peeringName string
param allowForwardedTraffic bool = true
param allowGatewayTransit bool
param allowVirtualNetworkAccess bool = true
param useRemoteGateways bool

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
