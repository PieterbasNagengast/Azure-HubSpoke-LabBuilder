targetScope = 'subscription'

param location string
@secure()
param sharedKey string = uniqueString(newGuid())

param OnPremRgName string
param HubRgName string

param vwanLinkBgpAsn int
param vwanLinkBgpPeeringAddress string
param vwanLinkPublicIP string
param vwanVpnSiteName string
param vwanID string
param vwanHubName string
param vwanGatewayName string
param vwanVpnGwInfo array 
param tagsByResource object = {}

param OnPremVpnGwID string

// vWAN VPN Site and VPN Connection
resource hubrg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: HubRgName
}

module vpnvWan 'modules/vwanvpnconnection.bicep' = {
  scope: hubrg
  name: 'vwanVPNsites'
  params: {
    linkBgpAsn: vwanLinkBgpAsn
    linkBgpPeeringAddress: vwanLinkBgpPeeringAddress
    linkPublicIP: vwanLinkPublicIP
    location: location
    vpnSiteName: vwanVpnSiteName
    vwanGatewayName: vwanGatewayName
    vwanHubName: vwanHubName
    vwanID: vwanID
    sharedKey: sharedKey
    tagsByResource: tagsByResource
  }
}

// OnPrem VPN Local Gateway and Connection
resource onpremrg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: OnPremRgName
}

@batchSize(1)
module vpnOnPrem 'modules/vpnconnection.bicep' = [for (item, i) in vwanVpnGwInfo: {
  scope: onpremrg
  name: 'vpnconnection${i + 1}'
  params: {
    connectionName: 'toVWAN${i + 1}'
    enableBgp: true
    LocalGatewayAddressPrefixes: []
    LocalGatewayName: 'VWAN${i + 1}'
    BgpPeeringAddress: vwanVpnGwInfo[i].defaultBgpIpAddresses[0]
    BgpAsn: 65515
    LocalGatewayPublicIP: vwanVpnGwInfo[i].tunnelIpAddresses[0]
    location: location
    sharedKey: sharedKey
    VpnGatewayID: OnPremVpnGwID
    tagsByResource: tagsByResource
  }
}]
