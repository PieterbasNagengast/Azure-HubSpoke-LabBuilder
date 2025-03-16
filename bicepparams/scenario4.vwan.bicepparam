using '../main.bicep'
param adminUsername = ''
param adminPassword = ''
param AddressSpace = '172.16.0.0/16'
param tagsByResource = {
  'Microsoft.Resources/subscriptions/resourceGroups': {
    LabBuilder: 'validation'
    LabBuilderType: 'vwan'
  }
}
param deploySpokes = true
param spokeRgNamePrefix = 'LabBuilderValidation-spoke'
param amountOfSpokes = 2
param deployVMsInSpokes = true
param deployHUB = true
param hubType = 'VWAN'
param hubRgName = 'LabBuilderValidation-hub'
param deployBastionInHub = false
param deployGatewayInHub = true
param deployFirewallInHub = true
param AzureFirewallTier = 'Standard'
param deployFirewallrules = true
param hubBgp = true
param hubBgpAsn = 65515
param deployOnPrem = true
param onpremRgName = 'LabBuilderValidation-onprem'
param deployBastionInOnPrem = true
param deployVMinOnPrem = true
param deployGatewayinOnPrem = true
param deploySiteToSite = false
param sharedKey = ''
param onpremBgp = true
param onpremBgpAsn = 65020
