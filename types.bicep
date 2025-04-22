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
  Hub: _VPNGatewaySettings
  OnPrem: _VPNGatewaySettings
}

@export()
type _VPNGatewaySettings = {
  GatewayID: string
  GatewayPublicIP: string
  AddressPrefixes: array
  BgpAsn: int
  BgpPeeringAddress: string
  Location: string
  shortLocationCode: string
  enableBgp: bool
}
