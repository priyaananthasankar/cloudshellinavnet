@description('Location for all resources')
param location string = resourceGroup().location

@description('Base name for all resources')
param baseName string = 'cloudshell'

@description('VNET address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Cloud Shell subnet address prefix')
param cloudShellSubnetPrefix string = '10.0.1.0/24'

@description('Relay subnet address prefix')
param relaySubnetPrefix string = '10.0.2.0/24'

@description('Storage account file share name')
param fileShareName string = 'testshare'

// Variables
var vnetName = '${baseName}-vnet'
var cloudShellSubnetName = 'cloudshellsubnet'
var relaySubnetName = 'relaysubnet'
var networkProfileName = '${baseName}-networkprofile'
var relayNamespaceName = '${baseName}-relay-${uniqueString(resourceGroup().id)}'
var natGatewayName = '${baseName}-natgateway'
var publicIpName = '${baseName}-nat-pip'
var storageAccountName = '${baseName}storage${uniqueString(resourceGroup().id)}'
var privateDnsZoneName = 'privatelink.servicebus.windows.net'
var relayPrivateEndpointName = '${baseName}-relay-pe'
var storagePrivateEndpointName = '${baseName}-storage-pe'
var storagePrivateDnsZoneName = 'privatelink.file.${environment().suffixes.storage}'

// Azure Container Instance Service Principal ID
var aciServicePrincipalId = '6bb8e274-af5d-4df2-98a3-4fd78b4cafd9'

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: cloudShellSubnetName
        properties: {
          addressPrefix: cloudShellSubnetPrefix
          delegations: [
            {
              name: 'Microsoft.ContainerInstance.containerGroups'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
          natGateway: {
            id: natGateway.id
          }
        }
      }
      {
        name: relaySubnetName
        properties: {
          addressPrefix: relaySubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// Public IP for NAT Gateway
resource natPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// NAT Gateway
resource natGateway 'Microsoft.Network/natGateways@2023-05-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: natPublicIp.id
      }
    ]
    idleTimeoutInMinutes: 4
  }
}

// Network Profile
resource networkProfile 'Microsoft.Network/networkProfiles@2023-05-01' = {
  name: networkProfileName
  location: location
  properties: {
    containerNetworkInterfaceConfigurations: [
      {
        name: 'eth0'
        properties: {
          ipConfigurations: [
            {
              name: 'ipconfigprofile1'
              properties: {
                subnet: {
                  id: '${vnet.id}/subnets/${cloudShellSubnetName}'
                }
              }
            }
          ]
        }
      }
    ]
  }
}

// Azure Relay Namespace
resource relayNamespace 'Microsoft.Relay/namespaces@2021-11-01' = {
  name: relayNamespaceName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Role Assignment: Network Contributor for ACI Service on Network Profile
resource networkContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(networkProfile.id, aciServicePrincipalId, 'NetworkContributor')
  scope: networkProfile
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7') // Network Contributor
    principalId: aciServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Role Assignment: Contributor for ACI Service on Relay
resource relayContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(relayNamespace.id, aciServicePrincipalId, 'Contributor')
  scope: relayNamespace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: aciServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Private DNS Zone for Relay
resource relayPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

// Private DNS Zone VNET Link for Relay
resource relayPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'vnet-link'
  parent: relayPrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Private Endpoint for Relay
resource relayPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: relayPrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/${relaySubnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: 'relay-connection'
        properties: {
          privateLinkServiceId: relayNamespace.id
          groupIds: [
            'namespace'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group for Relay Private Endpoint
resource relayPrivateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'default'
  parent: relayPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'relay-config'
        properties: {
          privateDnsZoneId: relayPrivateDnsZone.id
        }
      }
    ]
  }
}

// A Record for Relay in Private DNS Zone will be automatically created by the private DNS zone group

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// File Share
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: '${storageAccount.name}/default/${fileShareName}'
  properties: {
    shareQuota: 100
  }
}

// Private DNS Zone for Storage
resource storagePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: storagePrivateDnsZoneName
  location: 'global'
}

// Private DNS Zone VNET Link for Storage
resource storagePrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'vnet-link'
  parent: storagePrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Private Endpoint for Storage
resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: storagePrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/${relaySubnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group for Storage Private Endpoint
resource storagePrivateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'default'
  parent: storagePrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'storage-config'
        properties: {
          privateDnsZoneId: storagePrivateDnsZone.id
        }
      }
    ]
  }
}

// Outputs
output vnetId string = vnet.id
output networkProfileId string = networkProfile.id
output relayNamespaceId string = relayNamespace.id
output storageAccountId string = storageAccount.id
output relayPrivateEndpointId string = relayPrivateEndpoint.id
output storagePrivateEndpointId string = storagePrivateEndpoint.id
output relayNamespaceName string = relayNamespaceName
output storageAccountName string = storageAccountName
output fileShareName string = fileShareName