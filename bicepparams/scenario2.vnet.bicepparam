using '../main.bicep'
param adminUsername = ''
param adminPassword = ''
param tagsByResource = {
  'Microsoft.Resources/subscriptions/resourceGroups': {
    LabBuilder: 'validation'
    LabBuilderType: 'vnet'
  }
}
param deploySpokes = true
param amountOfSpokes = 2
param deployVMsInSpokes = true
param deployHUB = true
param hubType = 'VNET'
param deployBastionInHub = true
param deployGatewayInHub = false
param deployFirewallInHub = false
param AzureFirewallTier = 'Standard'
param deployFirewallrules = false
param hubBgp = false
param hubBgpAsn = 65010
param deployOnPrem = true
param deployBastionInOnPrem = true
param deployVMinOnPrem = true
param deployGatewayinOnPrem = false
param deploySiteToSite = false
param sharedKey = ''
param onpremBgp = false
param onpremBgpAsn = 65020
