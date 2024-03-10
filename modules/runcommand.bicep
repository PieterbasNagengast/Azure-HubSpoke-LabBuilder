param location string
param vmName string
param runName string = 'RunCommand'
param runCommand string

resource run 'Microsoft.Compute/virtualMachines/runCommands@2023-09-01' = {
  name: '${vmName}/${runName}'
  location: location
  properties: {
    source: {
      script: runCommand
    }
    timeoutInSeconds: 60
  }
}
