param location string
param userAssignedIdentityId string
param avnmName string
param configurationId string
param deploymentScriptName string
@allowed([
  'Connectivity'
  'Routing'
])
param configType string
param tagsByResource object = {}
param timeStamp string = utcNow()

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: deploymentScriptName
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    forceUpdateTag: timeStamp
    azPowerShellVersion: '8.3'
    retentionInterval: 'PT1H'
    timeout: 'PT1H'
    arguments: '-networkManagerName "${avnmName}" -targetLocations ${location} -configIds ${configurationId} -subscriptionId ${subscription().subscriptionId} -configType ${configType} -resourceGroupName ${resourceGroup().name}'
    scriptContent: '''
    param (
      # AVNM subscription id
      [parameter(mandatory=$true)][string]$subscriptionId,

      # AVNM resource name
      [parameter(mandatory=$true)][string]$networkManagerName,

      # string with comma-separated list of config ids to deploy. ids must be of the same config type
      [parameter(mandatory=$true)][string[]]$configIds,

      # string with comma-separated list of deployment target regions
      [parameter(mandatory=$true)][string[]]$targetLocations,

      # configuration type to deploy. must be either connecticity or securityadmin
      [parameter(mandatory=$true)][ValidateSet('Connectivity','Routing')][string]$configType,

      # AVNM resource group name
      [parameter(mandatory=$true)][string]$resourceGroupName
    )
  
    $null = Login-AzAccount -Identity -Subscription $subscriptionId
  
    [System.Collections.Generic.List[string]]$configIdList = @()  
    $configIdList.addRange($configIds) 
    [System.Collections.Generic.List[string]]$targetLocationList = @() # target locations for deployment
    $targetLocationList.addRange($targetLocations)     
    
    $deployment = @{
        Name = $networkManagerName
        ResourceGroupName = $resourceGroupName
        ConfigurationId = $configIdList
        TargetLocation = $targetLocationList
        CommitType = $configType
    }
  
    try {
      Deploy-AzNetworkManagerCommit @deployment -ErrorAction Stop
    }
    catch {
      Write-Error "Deployment failed with error: $_"
      throw "Deployment failed with error: $_"
    }
    '''
  }
  tags: tagsByResource[?'Microsoft.Resources/deploymentScripts'] ?? {}
}
