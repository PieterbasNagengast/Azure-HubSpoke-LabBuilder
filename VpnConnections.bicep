targetScope = 'subscription'

param location string
@secure()
param sharedKey string
param enableBgp bool
param tagsByResource object

//OnPrem
param OnPremGatewayID string
param OnPremRgName string
param OnPremBgpAsn int
param OnPremBgpPeeringAddress string
param HubGatewayPublicIP string
param HubLocalGatewayName string
param HubAddressPrefixes array

//Hub
param HubGatewayID string
param HubRgName string
param HubBgpAsn int
param HubBgpPeeringAddress string
param OnPremGatewayPublicIP string
param OnPremLocalGatewayName string
param OnPremAddressPrefixes array

// subscriptions
param hubSubscriptionID string
param onPremSubscriptionID string

resource onpremrg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  scope: subscription(onPremSubscriptionID)
  name: OnPremRgName
}

module onprem2hub 'modules/vpnconnection.bicep' = {
  scope: onpremrg
  name: HubLocalGatewayName
  params: {
    LocalGatewayAddressPrefixes: HubAddressPrefixes
    LocalGatewayName: HubLocalGatewayName
    LocalGatewayPublicIP: HubGatewayPublicIP
    location: location
    connectionName: 'VPNtoHub'
    sharedKey: sharedKey
    VpnGatewayID: OnPremGatewayID
    tagsByResource: tagsByResource
    enableBgp: enableBgp
    BgpAsn: HubBgpAsn
    BgpPeeringAddress: HubBgpPeeringAddress
  }
}

resource hubrg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  scope: subscription(hubSubscriptionID)
  name: HubRgName
}

module hub2onprem 'modules/vpnconnection.bicep' = {
  scope: hubrg
  name: OnPremLocalGatewayName
  params: {
    LocalGatewayAddressPrefixes: OnPremAddressPrefixes
    LocalGatewayName: OnPremLocalGatewayName
    LocalGatewayPublicIP: OnPremGatewayPublicIP
    location: location
    connectionName: 'VPNtoOnPrem'
    sharedKey: sharedKey
    VpnGatewayID: HubGatewayID
    tagsByResource: tagsByResource
    enableBgp: enableBgp
    BgpAsn: OnPremBgpAsn
    BgpPeeringAddress: OnPremBgpPeeringAddress
  }
}
