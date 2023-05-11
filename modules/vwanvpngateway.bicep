param location string
param vWanHubID string
param vpnGwName string
@minValue(1)
@maxValue(25)
param vpnGwScaleUnits int = 1

resource vpngw 'Microsoft.Network/vpnGateways@2022-11-01' = {
  name: vpnGwName
  location: location
  properties: {
    bgpSettings: {
      asn: 65515
    }
    vpnGatewayScaleUnit: vpnGwScaleUnits
    virtualHub: {
      id: vWanHubID
    }
  }
}

output vpnGwID string = vpngw.id
output vpnGwPip array = vpngw.properties.ipConfigurations
output vpnGwBgpIp array = vpngw.properties.bgpSettings.bgpPeeringAddresses
output vpnGwBgpAsn int = vpngw.properties.bgpSettings.asn
output vpnGwName string = vpngw.name
