param location string
param vWanHubName string = 'HUB'
param vWanName string
@allowed([
  'Standard'
  'Basic'
])
param vWanType string = 'Standard'
param tagsByResource object = {}
param AddressPrefix string
param deployFirewallInHub bool
param AzureFirewallTier string
// param deployFirewallrules bool
param deployGatewayInHub bool
// param AllSpokeAddressSpaces array
param azfwSKUname string = 'AZFW_Hub'

resource vWan 'Microsoft.Network/virtualWans@2020-07-01' = {
  name: vWanName
  location: location
  properties: {
    type: vWanType
    disableVpnEncryption: false
    allowBranchToBranchTraffic: true
    allowVnetToVnetTraffic: true
  }
  tags: contains(tagsByResource, 'Microsoft.Network/virtualWans') ? tagsByResource['Microsoft.Network/virtualWans'] : {}
}

resource vWanHub 'Microsoft.Network/virtualHubs@2021-05-01' = {
  name: '${vWanHubName}-${location}'
  location: location
  properties: {
    addressPrefix: AddressPrefix
    virtualWan: {
      id: vWan.id
    }
  }
  tags: contains(tagsByResource, 'Microsoft.Network/virtualHubs') ? tagsByResource['Microsoft.Network/virtualHubs'] : {}
}

resource vWanFirewall 'Microsoft.Network/azureFirewalls@2021-05-01' = if (deployFirewallInHub) {
  name: '${vWanHubName}-Firewall-${location}'
  location: location
  properties: {
    sku: {
      name: azfwSKUname
      tier: AzureFirewallTier
    }
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
    firewallPolicy: {
       id: vWanFirewallPolicy.id
    }
    virtualHub: {
       id: vWanHub.id
    }
  }
}

resource vWanFirewallPolicy 'Microsoft.Network/firewallPolicies@2021-05-01' = if (deployFirewallInHub) {
  name: '${vWanHubName}-FirewallPolicy-${location}'
  location: location
  properties: {
    sku: {
       tier: AzureFirewallTier
    }
  }
}

resource vWanVpnGateway 'Microsoft.Network/vpnGateways@2021-08-01' = if (deployGatewayInHub) {
  name: '${vWanHubName}-VpnGateway-${location}'
  location: location
  properties: {
    vpnGatewayScaleUnit: 1
    virtualHub: {
      id: vWanHub.id
    }
  }
}

output azFwIP string = deployFirewallInHub ? vWanFirewall.properties.ipConfigurations[0].properties.privateIPAddress : 'none'
output azFwPolicyName string = deployFirewallInHub ? vWanFirewallPolicy.name : 'none'
output vpnGwPublicIP string = deployGatewayInHub ? vWanVpnGateway.properties.ipConfigurations[0].publicIpAddress : 'none'
output vpnGwID string = deployGatewayInHub ? vWanVpnGateway.id : 'none'
