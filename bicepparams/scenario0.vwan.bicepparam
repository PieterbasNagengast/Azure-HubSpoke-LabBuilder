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
param deployVMsInSpokes = false
param deployHUB = true
param hubType = 'VWAN'
param deployBastionInHub = false
param deployGatewayInHub = false
param deployFirewallInHub = false
param AzureFirewallTier = 'Standard'
param deployFirewallrules = false
param hubBgp = false
param hubBgpAsn = 65515
param deployOnPrem = true
param deployBastionInOnPrem = false
param deployVMinOnPrem = false
param deployGatewayinOnPrem = false
param deploySiteToSite = false
param sharedKey = ''
param onpremBgp = false
param onpremBgpAsn = 65020
