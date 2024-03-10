param remoteVnetID string
param peeringName string
param allowForwardedTraffic bool = true
param allowGatewayTransit bool
param allowVirtualNetworkAccess bool = true
param useRemoteGateways bool

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-06-01' = {
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
