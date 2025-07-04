targetScope = 'subscription'
param shortLocationCode string
param vwanHubName string
param SpokeVnetID string
param HubResourceGroupName string
param counter int
param deployFirewallInHub bool
param hubSubscriptionID string
param enableRoutingIntent bool = true

var spokeName = split(SpokeVnetID, '/')[8]

resource hubrg 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  scope: subscription(hubSubscriptionID)
  name: HubResourceGroupName
}

module vWanVnetConnection 'modules/vwanvnetconnection.bicep' = {
  scope: hubrg
  name: 'VWAN-VnetConnection${counter + 1}-${shortLocationCode}'
  params: {
    SpokeVnetID: SpokeVnetID
    vwanHubName: vwanHubName
    spokeName: spokeName
    enableInternetSecurity: deployFirewallInHub
    propagateToNoneRouteTable: deployFirewallInHub
    enableRoutingIntent: enableRoutingIntent
  }
}
