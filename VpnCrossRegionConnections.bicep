targetScope = 'subscription'

import { _VPNSettings } from './types.bicep'

param HubVPN _VPNSettings.Hub
param OnPrem _VPNSettings.OnPrem

@secure()
param sharedKey string
param tagsByResource object

param routingIntent bool

var isvWan = HubVPN.type == 'VWAN'
var isvNet = HubVPN.type == 'VNET'

// Deploy s2s VPN Cross Region from OnPrem Gateway to Hub Gateway
module s2s 'VpnConnections.bicep' = if (isvNet) {
  name: 'VPN-s2s-CrossRegion-${HubVPN.shortLocationCode}-${OnPrem.shortLocationCode}'
  params: {
    HubLocation: HubVPN.Location
    HubRgName: split(HubVPN.GatewayID, '/')[4]
    HubGatewayID: HubVPN.GatewayID
    HubGatewayPublicIP: HubVPN.GatewayPublicIP
    HubAddressPrefixes: HubVPN.AddressPrefixes
    HubLocalGatewayName: 'LocalGateway-Hub-${HubVPN.shortLocationCode}'
    HubBgpAsn: HubVPN.BgpAsn
    HubBgpPeeringAddress: HubVPN.BgpPeeringAddress

    OnPremLocation: OnPrem.Location
    OnPremRgName: split(OnPrem.GatewayID, '/')[4]
    OnPremGatewayID: OnPrem.GatewayID
    OnPremGatewayPublicIP: OnPrem.GatewayPublicIP
    OnPremAddressPrefixes: OnPrem.AddressPrefixes
    OnPremLocalGatewayName: 'LocalGateway-OnPrem-${OnPrem.shortLocationCode}'
    OnPremBgpAsn: OnPrem.BgpAsn
    OnPremBgpPeeringAddress: OnPrem.BgpPeeringAddress

    tagsByResource: tagsByResource
    enableBgp: HubVPN.enableBgp && HubVPN.enableBgp
    sharedKey: sharedKey
    hubSubscriptionID: split(HubVPN.GatewayID, '/')[2]
    onPremSubscriptionID: split(OnPrem.GatewayID, '/')[2]
  }
}

// Deploy s2s VPN from OnPrem Gateway to vWan Hub Gateway
module vwans2s 'vWanVpnConnections.bicep' = if (isvWan) {
  name: 'VPN-s2s-CrossRegion-${HubVPN.shortLocationCode}-${OnPrem.shortLocationCode}'
  params: {
    HubLocation: HubVPN.Location
    HubShortLocationCode: HubVPN.shortLocationCode
    HubRgName: split(HubVPN.vWanID, '/')[4]
    vwanVpnGwInfo: HubVPN.vwanVpnGwInfo
    vwanGatewayName: HubVPN.vWanGatewayName
    vwanID: HubVPN.vWanID
    vwanHubName: HubVPN.vWanHubName
    HubAddressPrefixes: HubVPN.AddressPrefixes
    HubLocalGatewayName: 'LocalGateway-Hub-${HubVPN.shortLocationCode}'

    OnPremLocation: OnPrem.Location
    OnPremShortLocationCode: OnPrem.shortLocationCode
    OnPremRgName: split(OnPrem.GatewayID, '/')[4]
    OnPremGatewayID: OnPrem.GatewayID
    OnPremGatewayPublicIP: OnPrem.GatewayPublicIP
    OnPremAddressPrefixes: OnPrem.AddressPrefixes
    OnPremBgpPeeringAddress: OnPrem.BgpPeeringAddress
    OnPremBgpAsn: OnPrem.BgpAsn

    tagsByResource: tagsByResource
    enableBgp: HubVPN.enableBgp && HubVPN.enableBgp
    sharedKey: sharedKey
    hubSubscriptionID: split(HubVPN.vWanID, '/')[2]
    onPremSubscriptionID: split(OnPrem.GatewayID, '/')[2]
    deployFirewallInHub: HubVPN.propagateToNoneRouteTable
    isCrossRegion: true
    routingIntent: routingIntent
  }
}
