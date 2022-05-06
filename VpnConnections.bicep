targetScope = 'subscription'

param location string
@secure()
param sharedKey string = uniqueString(newGuid())
param tagsByResource object

//OnPrem
param OnPremGatewayID string
param OnPremRgName string
param HubGatewayPublicIP string
param HubLocalGatewayName string
param HubAddressPrefixes array

//Hub
param HubGatewayID string
param HubRgName string
param OnPremGatewayPublicIP string 
param OnPremLocalGatewayName string 
param OnPremAddressPrefixes array

resource onpremrg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: OnPremRgName
}

module onprem2hub 'modules/vpnconnection.bicep' = {
  scope: onpremrg
  name: HubLocalGatewayName
  params: {
    LocalGatewayAddressPrefixes: HubAddressPrefixes
    LocalGatewayName: HubLocalGatewayName
    LocalGatewayPublicIP: HubGatewayPublicIP
    location: location
    connectionName: 'VPNtoHub'
    sharedKey: sharedKey
    VpnGatewayID: OnPremGatewayID
    tagsByResource: tagsByResource
  }
}

resource hubrg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: HubRgName
}

module hub2onprem 'modules/vpnconnection.bicep' = {
  scope: hubrg
  name: OnPremLocalGatewayName
  params: {
    LocalGatewayAddressPrefixes: OnPremAddressPrefixes
    LocalGatewayName: OnPremLocalGatewayName
    LocalGatewayPublicIP: OnPremGatewayPublicIP
    location: location
    connectionName: 'VPNtoOnPrem'
    sharedKey:sharedKey
    VpnGatewayID: HubGatewayID
    tagsByResource: tagsByResource
  }
}
