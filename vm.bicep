param location string 
param vmName string
param adminUsername string
@secure()
param adminPassword string
param subnetID string
param vmSize string = 'Standard_B2s'
param storageType string = 'StandardSSD_LRS'
@allowed([
  '2022-datacenter'
  '2019-datacenter'
  '2016-datacenter'
  '2012-R2-datacenter'
 ])
 param OSVersion string = '2022-datacenter'

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmName
  location: location
  properties: {
   osProfile: {
     computerName: vmName
     adminUsername: adminUsername
     adminPassword: adminPassword
   }
   storageProfile: {
     imageReference: {
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: OSVersion
      version: 'latest'
     }
     osDisk: {
       createOption: 'FromImage'
       managedDisk: {
         storageAccountType: storageType
       }
       osType: 'Windows'
     }
   }   
   networkProfile: {
     networkInterfaces: [
       {
         id: nic.id
       }
     ]
   }
   hardwareProfile: {
     vmSize: vmSize
   }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          primary: true
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetID
          }
        }
      }
    ]
  }
}

// resource customScript 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
//   name: '${vm.name}/EnableICMP'
//   location: location
//   properties: {
//     publisher: 'Microsoft.Compute'
//     type: 'CustomScriptExtension'
//     typeHandlerVersion: '1.4'
//     settings: {     
//     }
//   }
// }
