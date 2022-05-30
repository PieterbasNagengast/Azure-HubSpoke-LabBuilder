param location string
param LocalGatewayName string
param LocalGatewayPublicIP string
param LocalGatewayAddressPrefixes array
param VpnGatewayID string
param connectionName string
@secure()
param sharedKey string
param tagsByResource object = {}
param enableBgp bool
param BgpAsn int
param BgpPeeringAddress string

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2021-05-01' = {
  name: LocalGatewayName
  location: location
  properties: {
    gatewayIpAddress: LocalGatewayPublicIP
    bgpSettings: enableBgp ? {
      asn: BgpAsn
      bgpPeeringAddress: BgpPeeringAddress
    } : {}
    localNetworkAddressSpace: enableBgp ? {} : {
      addressPrefixes: LocalGatewayAddressPrefixes
    }
  }
  tags: contains(tagsByResource, 'Microsoft.Network/localNetworkGateways') ? tagsByResource['Microsoft.Network/localNetworkGateways'] : {}
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
    enableBgp: enableBgp
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
  tags: contains(tagsByResource, 'Microsoft.Network/connections') ? tagsByResource['Microsoft.Network/connections'] : {}
}
