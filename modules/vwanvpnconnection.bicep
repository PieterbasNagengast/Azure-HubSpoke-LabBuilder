param location string
param enableBgp bool
param linkBgpAsn int
param linkBgpPeeringAddress string
param linkPublicIP string
param vpnSiteName string
param vwanID string
param vwanHubName string
param vwanGatewayName string
@secure()
param sharedKey string
param tagsByResource object = {}
param propagateToNoneRouteTable bool
param addressPrefixes array
param routingIntent bool

resource vpnsiteNoBgp 'Microsoft.Network/vpnSites@2024-05-01' = if (!enableBgp) {
  name: vpnSiteName
  location: location
  properties: {
    deviceProperties: {
      deviceModel: 'LabBuilder'
      deviceVendor: 'LabBuilder'
      linkSpeedInMbps: 1000
    }
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    vpnSiteLinks: [
      {
        name: '${vpnSiteName}-Link'
        properties: {
          linkProperties: {
            linkProviderName: 'Azure'
            linkSpeedInMbps: 1000
          }
          ipAddress: linkPublicIP
        }
      }
    ]
    virtualWan: {
      id: vwanID
    }
  }
  tags: tagsByResource[?'Microsoft.Network/vpnSites'] ?? {}
}

resource vpnsiteBgp 'Microsoft.Network/vpnSites@2024-05-01' = if (enableBgp) {
  name: vpnSiteName
  location: location
  properties: {
    deviceProperties: {
      deviceModel: 'LabBuilder'
      deviceVendor: 'LabBuilder'
      linkSpeedInMbps: 1000
    }
    addressSpace: {
      addressPrefixes: []
    }
    vpnSiteLinks: [
      {
        name: '${vpnSiteName}-Link'
        properties: {
          linkProperties: {
            linkProviderName: 'Azure'
            linkSpeedInMbps: 1000
          }
          ipAddress: linkPublicIP
          bgpProperties: {
            asn: linkBgpAsn
            bgpPeeringAddress: linkBgpPeeringAddress
          }
        }
      }
    ]
    virtualWan: {
      id: vwanID
    }
  }
  tags: tagsByResource[?'Microsoft.Network/vpnSites'] ?? {}
}

resource vpnconnection 'Microsoft.Network/vpnGateways/vpnConnections@2024-05-01' = {
  name: '${vwanGatewayName}/Connection-${vpnSiteName}'
  properties: {
    remoteVpnSite: {
      id: enableBgp ? vpnsiteBgp.id : vpnsiteNoBgp.id
    }
    routingConfiguration: routingIntent
      ? {}
      : {
          associatedRouteTable: {
            id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vwanHubName, 'defaultRouteTable')
          }
          propagatedRouteTables: {
            ids: [
              {
                id: resourceId(
                  'Microsoft.Network/virtualHubs/hubRouteTables',
                  vwanHubName,
                  propagateToNoneRouteTable ? 'noneRouteTable' : 'defaultRouteTable'
                )
              }
            ]
            labels: [
              propagateToNoneRouteTable ? '' : 'default'
            ]
          }
          vnetRoutes: {
            staticRoutes: []
          }
        }
    vpnLinkConnections: [
      {
        name: '${vpnSiteName}-Link'
        properties: {
          vpnSiteLink: {
            id: enableBgp ? vpnsiteBgp!.properties.vpnSiteLinks[0].id : vpnsiteNoBgp!.properties.vpnSiteLinks[0].id
          }
          enableBgp: enableBgp
          vpnConnectionProtocolType: 'IKEv2'
          sharedKey: sharedKey
          ipsecPolicies: []
          enableRateLimiting: false
          useLocalAzureIpAddress: false
          usePolicyBasedTrafficSelectors: false
          vpnLinkConnectionMode: 'Default'
        }
      }
    ]
  }
}
