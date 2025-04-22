targetScope = 'subscription'

import { _VPNGatewaySettings } from './types.bicep'

param HubVPN _VPNGatewaySettings
param OnPrem _VPNGatewaySettings

@secure()
param sharedKey string
param tagsByResource object

// Deploy s2s VPN Cross Region from OnPrem Gateway to Hub Gateway
module s2s 'VpnConnections.bicep' = {
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
