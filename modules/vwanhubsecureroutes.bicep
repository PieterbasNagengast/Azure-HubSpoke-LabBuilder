param vwanHubName string
param AzFirewallID string

resource vWanSecureRoutes 'Microsoft.Network/virtualHubs/hubRouteTables@2020-05-01' = {
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
