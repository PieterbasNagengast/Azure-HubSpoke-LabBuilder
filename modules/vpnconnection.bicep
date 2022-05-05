param location string
param LocalGatewayName string
param LocalGatewayPublicIP string
param LocalGatewayAddressPrefixes array
param VpnGatewayID string
param connectionName string
param sharedKey string

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2021-05-01' = {
  name: LocalGatewayName
  location: location
  properties: {
    gatewayIpAddress: LocalGatewayPublicIP
    localNetworkAddressSpace: {
      addressPrefixes: LocalGatewayAddressPrefixes
    }
  }
}

resource connection 'Microsoft.Network/connections@2021-05-01' = {
  name: connectionName
  location: location
  properties: {
    connectionType: 'IPsec'
    connectionMode: 'Default'
    connectionProtocol: 'IKEv2'
    useLocalAzureIpAddress: false
    usePolicyBasedTrafficSelectors: false
    sharedKey: sharedKey
    virtualNetworkGateway1: {
      id: VpnGatewayID
      properties: {}
    }
    localNetworkGateway2: {
      id: localNetworkGateway.id
      properties: {}
    }
  }
}

