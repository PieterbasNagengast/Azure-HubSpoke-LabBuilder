param location string
param vWanID string
param vpnGwName string

param tagsByResource object = {}

resource vpngw 'Microsoft.Network/vpnGateways@2021-08-01' = {
  name: vpnGwName
  location: location
  properties: {
   vpnGatewayScaleUnit: 1
   virtualHub: {
    id: vWanID
   } 
  }
  tags: contains(tagsByResource, 'Microsoft.Network/vpnGateways') ? tagsByResource['Microsoft.Network/vpnGateways'] : {}
}
