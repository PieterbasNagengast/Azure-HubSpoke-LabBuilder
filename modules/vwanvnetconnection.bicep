param vwanHubName string
param spokeName string
param SpokeVnetID string

param enableInternetSecurity bool = false
param propagateToNoneRouteTable bool = false

param allowHubToRemoteVnetTransit bool = true
param allowRemoteVnetToUseHubVnetGateways bool = true

param vnetLocalRouteOverrideCriteria string = 'Contains'

resource vWanVnetConnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2022-11-01' = {
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
            id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vwanHubName, propagateToNoneRouteTable ? 'noneRouteTable' : 'defaultRouteTable')
          }
        ]
      }
      vnetRoutes: {
        staticRoutes: []
        staticRoutesConfig: {
          vnetLocalRouteOverrideCriteria: vnetLocalRouteOverrideCriteria
        }
      }
    }
    remoteVirtualNetwork: {
      id: SpokeVnetID
    }
    allowHubToRemoteVnetTransit: allowHubToRemoteVnetTransit
    allowRemoteVnetToUseHubVnetGateways: allowRemoteVnetToUseHubVnetGateways
    enableInternetSecurity: enableInternetSecurity
  }
}
