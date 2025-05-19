targetScope = 'subscription'

param OnPremLocation string
param OnPremShortLocationCode string
param HubLocation string
param HubShortLocationCode string

@secure()
param sharedKey string
param enableBgp bool
param tagsByResource object

//OnPrem -> Hub
param OnPremRgName string
param OnPremGatewayID string
param HubLocalGatewayName string
param HubAddressPrefixes array
param vwanVpnGwInfo array

//Hub -> OnPrem
param HubRgName string
param OnPremBgpAsn int
param OnPremBgpPeeringAddress string
param OnPremGatewayPublicIP string
param OnPremAddressPrefixes array
param vwanGatewayName string
param vwanHubName string
param vwanID string
param deployFirewallInHub bool

// subscriptions
param hubSubscriptionID string
param onPremSubscriptionID string

param routingIntent bool = false

param isCrossRegion bool = false

var vWanCrossRegionPostfix = isCrossRegion ? '-CrossRegion' : ''

// OnPrem VPN Local Gateway and Connection
resource onpremrg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  scope: subscription(onPremSubscriptionID)
  name: OnPremRgName
}

module vpnOnPrem 'modules/vpnconnection.bicep' = [
  for (vwan, i) in vwanVpnGwInfo: {
    scope: onpremrg
    name: '${HubLocalGatewayName}${i + 1}'
    params: {
      LocalGatewayAddressPrefixes: HubAddressPrefixes
      LocalGatewayName: '${HubLocalGatewayName}${i + 1}'
      LocalGatewayPublicIP: vwan.tunnelIpAddresses[0]
      location: OnPremLocation
      connectionName: 'VPNtoVWAN${i + 1}-${HubShortLocationCode}'
      sharedKey: sharedKey
      VpnGatewayID: OnPremGatewayID
      tagsByResource: tagsByResource
      enableBgp: enableBgp
      BgpAsn: 65515
      BgpPeeringAddress: vwan.defaultBgpIpAddresses[0]
    }
  }
]

// vWAN VPN Site and VPN Connection
resource hubrg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  scope: subscription(hubSubscriptionID)
  name: HubRgName
}

module vpnvWan 'modules/vwanvpnconnection.bicep' = {
  scope: hubrg
  name: 'vwanVPNsites-${OnPremLocation}'
  params: {
    enableBgp: enableBgp
    addressPrefixes: OnPremAddressPrefixes
    linkBgpAsn: OnPremBgpAsn
    linkBgpPeeringAddress: OnPremBgpPeeringAddress
    linkPublicIP: OnPremGatewayPublicIP
    location: HubLocation
    vpnSiteName: 'VPNtoOnPrem-${OnPremShortLocationCode}${vWanCrossRegionPostfix}'
    vwanGatewayName: vwanGatewayName
    vwanHubName: vwanHubName
    vwanID: vwanID
    sharedKey: sharedKey
    tagsByResource: tagsByResource
    propagateToNoneRouteTable: deployFirewallInHub
    routingIntent: routingIntent
  }
}
