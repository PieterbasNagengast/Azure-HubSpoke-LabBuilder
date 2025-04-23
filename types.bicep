@export()
@maxLength(2)
type _Locations = {
  region: string
  regionAddressSpace: string
  hubSubscriptionID: string
  spokeSubscriptionID: string
  onPremSubscriptionID: string
}[]

@export()
type _VPNSettings = {
  @discriminator('type')
  Hub: _VPNGatewaySettingsVNET | _VPNGatewaySettingsVWAN
  @discriminator('type')
  OnPrem: _VPNGatewaySettingsVNET | _VPNGatewaySettingsVWAN
}

@export()
type _VPNGatewaySettingsVNET = {
  type: 'VNET'
  GatewayID: string
  GatewayPublicIP: string
  AddressPrefixes: array
  BgpAsn: int
  BgpPeeringAddress: string
  Location: string
  shortLocationCode: string
  enableBgp: bool
}

@export()
type _VPNGatewaySettingsVWAN = {
  type: 'VWAN'
  vWanID: string
  vWanHubName: string
  vWanGatewayName: string
  vwanVpnGwInfo: array
  AddressPrefixes: array
  BgpAsn: int
  Location: string
  shortLocationCode: string
  enableBgp: bool
  propagateToNoneRouteTable: bool
}
