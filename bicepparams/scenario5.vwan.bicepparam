using '../main.bicep'
param adminUsername = ''
param adminPassword = ''
param tagsByResource = {
  'Microsoft.Resources/subscriptions/resourceGroups': {
    LabBuilder: 'validation'
    LabBuilderType: 'vwan'
  }
}
param deploySpokes = true
param amountOfSpokes = 2
param deployVMsInSpokes = true
param deployHUB = true
param hubType = 'VWAN'
param deployBastionInHub = false
param deployGatewayInHub = true
param deployFirewallInHub = true
param AzureFirewallTier = 'Standard'
param deployFirewallrules = true
param hubBgp = true
param hubBgpAsn = 65515
param deployOnPrem = true
param deployBastionInOnPrem = true
param deployVMinOnPrem = true
param deployGatewayinOnPrem = true
param deploySiteToSite = true
param sharedKey = ''
param onpremBgp = true
param onpremBgpAsn = 65020
