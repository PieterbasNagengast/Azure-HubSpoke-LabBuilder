param vwanHubName string
param spokeName string
param SpokeVnetID string

param enableInternetSecurity bool = false
param propagateToNoneRouteTable bool = false

resource vWanVnetConnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2021-05-01' = {
  name: '${vwanHubName}/${vwanHubName}-to-${spokeName}'
  properties: {
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vwanHubName, 'defaultRouteTable')
      }
      propagatedRouteTables: {
        labels: [
          propagateToNoneRouteTable ? '' : 'default'
        ]
        ids: [
          {
            id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vwanHubName, propagateToNoneRouteTable ? 'noneRouteTable' : 'defaultRouteTable' )
          }
        ]
      }
    }
    remoteVirtualNetwork: {
      id: SpokeVnetID
    }
    enableInternetSecurity: enableInternetSecurity
  }
}
