param location string
param vpnGatewayName string
param vpnGatewaySubnetID string
param vpnGatewaySKU string = 'VpnGw1'
param vpnGatewayType string = 'Vpn'
param vpnGatewayVPNtype string = 'RouteBased'
param vpnGatewayGen string = 'Generation1'
param vpnGatewayEnableBgp bool
param vpnGatewayBgpAsn int
param tagsByResource object = {}

var pipName = '${vpnGatewayName}-pip'

resource vpngw 'Microsoft.Network/virtualNetworkGateways@2023-06-01' = {
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

resource vpngwpip 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: pipName
  location: location
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
