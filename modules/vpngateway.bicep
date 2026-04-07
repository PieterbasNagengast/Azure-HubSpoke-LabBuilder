param location string
param vpnGatewayName string
param vpnGatewaySubnetID string
@allowed([
  'VpnGw1AZ'
  'VpnGw2AZ'
  'VpnGw3AZ'
  'VpnGw4AZ'
  'VpnGw5AZ'
])
param vpnGatewaySKU string = 'VpnGw1AZ'
param vpnGatewayType string = 'Vpn'
param vpnGatewayVPNtype string = 'RouteBased'
param vpnGatewayGen string = 'Generation2'
param vpnGatewayEnableBgp bool
param vpnGatewayBgpAsn int
param tagsByResource object = {}

var pipName = '${vpnGatewayName}-pip'

resource vpngw 'Microsoft.Network/virtualNetworkGateways@2025-05-01' = {
  name: vpnGatewayName
  location: location
  properties: {
    gatewayType: vpnGatewayType
    vpnType: vpnGatewayVPNtype
    enableBgp: vpnGatewayEnableBgp
    bgpSettings: {
      asn: vpnGatewayBgpAsn
    }
    sku: {
      name: vpnGatewaySKU
      tier: vpnGatewaySKU
    }
    vpnGatewayGeneration: vpnGatewayGen
    activeActive: false
    ipConfigurations: [
      {
        name: 'ipConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vpnGatewaySubnetID
          }
          publicIPAddress: {
            id: vpngwpip.id
          }
        }
      }
    ]
  }
  tags: tagsByResource[?'Microsoft.Network/virtualNetworkGateways'] ?? {}
}

resource vpngwpip 'Microsoft.Network/publicIPAddresses@2025-05-01' = {
  name: pipName
  location: location
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    tier: 'Regional'
    name: 'Standard'
  }
  tags: tagsByResource[?'Microsoft.Network/publicIPAddresses'] ?? {}
}

output vpnGwPublicIP string = vpngwpip.properties.ipAddress
output vpnGwID string = vpngw.id
output vpnGwBgpPeeringAddress string = vpngw.properties.bgpSettings.bgpPeeringAddress
output vpnGwName string = vpngw.name
output vpnGwAsn int = vpngw.properties.bgpSettings.asn
