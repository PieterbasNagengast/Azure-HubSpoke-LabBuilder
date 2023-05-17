param vwanHubName string
param AzFirewallID string
param deployFirewallInHub bool

resource vWanRoutes 'Microsoft.Network/virtualHubs/hubRouteTables@2022-11-01' = if (!deployFirewallInHub) {
  name: '${vwanHubName}/defaultRouteTable'
  properties: {
    routes: []
    labels: [
      'default'
    ]
  }
}

resource vWanSecureRoutes 'Microsoft.Network/virtualHubs/hubRouteTables@2022-11-01' = if (deployFirewallInHub) {
  name: '${vwanHubName}/defaultRouteTable'
  properties: {
    routes: [
      {
        name: 'all_traffic'
        destinationType: 'CIDR'
        destinations: [
          '10.0.0.0/8'
          '172.16.0.0/12'
          '192.168.0.0/16'
          '0.0.0.0/0'
        ]
        nextHopType: 'ResourceId'
        nextHop: AzFirewallID
      }
    ]
    labels: [
      'default'
    ]
  }
}
