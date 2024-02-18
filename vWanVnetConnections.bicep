targetScope = 'subscription'
param vwanHubName string
param SpokeVnetID string
param HubResourceGroupName string
param counter int
param deployFirewallInHub bool
param hubSubscriptionID string
param enableRoutingIntent bool = true

var spokeName = split(SpokeVnetID, '/')[8]

resource hubrg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  scope: subscription(hubSubscriptionID)
  name: HubResourceGroupName
}

module vWanVnetConnection 'modules/vwanvnetconnection.bicep' = {
  scope: hubrg
  name: 'VnetConnection${counter + 1}'
  params: {
    SpokeVnetID: SpokeVnetID
    vwanHubName: vwanHubName
    spokeName: spokeName
    enableInternetSecurity: deployFirewallInHub
    propagateToNoneRouteTable: deployFirewallInHub
    enableRoutingIntent: enableRoutingIntent
  }
}
