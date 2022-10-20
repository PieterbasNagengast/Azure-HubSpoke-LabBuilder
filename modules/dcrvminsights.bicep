param location string
param diagnosticWorkspaceId string
param tagsByResource object = {}

resource dcr 'Microsoft.Insights/dataCollectionRules@2021-04-01' =  {
  name: 'MSVMI-${split(diagnosticWorkspaceId, '/')[8]}'
  location: location
  properties: {
    description: 'Data collection rule for VM Insights.'
    dataSources: {
      performanceCounters: [
        {
          name: 'VMInsightsPerfCounters'
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\VmInsights\\DetailedMetrics'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'VMInsightsPerf-Logs-Dest'
          workspaceResourceId: diagnosticWorkspaceId
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
      }
    ]
  }
  tags: contains(tagsByResource, 'Microsoft.Insights/dataCollectionRules') ? tagsByResource['Microsoft.Insights/dataCollectionRules'] : {}
}

output dcrID string = dcr.id
