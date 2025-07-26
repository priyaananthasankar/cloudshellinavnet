# Cloud Shell in VNET - Infrastructure Automation

This repository contains automated infrastructure-as-code solutions for setting up Azure Cloud Shell in a Virtual Network (VNET). The project provides both manual workflows for GitHub Copilot Agent mode and automated deployment scripts using Azure Bicep.

## Overview

The project demonstrates how to:
- Create Azure infrastructure for Cloud Shell VNET integration using Infrastructure-as-Code (Bicep)
- Set up private networking with Azure Relay
- Configure private DNS zones for internal resolution
- Deploy NAT gateway for outbound connectivity
- Provision storage accounts with private endpoints
- Clean up resources automatically 

## Prerequisites

### Required Tools
1. **Azure CLI** installed and authenticated
2. **Azure Subscription** with appropriate permissions
3. **jq** (for JSON processing in scripts)
4. **VS Code** with GitHub Copilot extension (for manual workflows)

### Azure CLI Setup
```bash
# Install Azure CLI (if not already installed)
# macOS
brew install azure-cli

# Linux (Ubuntu/Debian)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Windows
# Download from https://aka.ms/installazurecliwindows

# Login to Azure
az login

# Verify login and set subscription if needed
az account show
az account set --subscription "<your-subscription-id>"
```

### Install jq (for script JSON processing)
```bash
# macOS
brew install jq

# Linux (Ubuntu/Debian)
sudo apt-get install jq

# Windows (using chocolatey)
choco install jq
```

## Quick Start - Automated Deployment

### Option 1: Infrastructure-as-Code (Recommended)

The fastest way to set up Cloud Shell in a VNET is using the provided Bicep templates and deployment scripts.

#### 1. Deploy Infrastructure
```bash
# Basic deployment with default settings
./deploy.sh -g cloudshell-rg

# Deploy in a specific region with custom naming
./deploy.sh -g my-cloudshell-rg -l westus2 -b myshell

# Deploy with custom parameters file
./deploy.sh -g cloudshell-rg -p custom-parameters.json
```

#### 2. Configure Cloud Shell
1. Open the [Azure Portal](https://portal.azure.com/)
2. Click on the Cloud Shell icon in the top navigation
3. Choose "Bash" or "PowerShell"
4. In the setup dialog, select "Use an existing private virtual network"
5. Use the Network Profile ID from the deployment output
6. Complete the setup process

#### 3. Clean Up Resources
```bash
# Delete all resources (with confirmation)
./cleanup.sh -g cloudshell-rg

# Force delete without confirmation
./cleanup.sh -g cloudshell-rg --force
```

#### Architecture Components

The Bicep template (`main.bicep`) creates the following resources:
- **Resource Group**: Container for all resources
- **Virtual Network**: With cloudshellsubnet (delegated to Container Instances) and relaysubnet
- **Network Profile**: For Container Instance integration
- **NAT Gateway**: With public IP for outbound connectivity
- **Azure Relay Namespace**: For Cloud Shell communication
- **Storage Account**: With "testshare" file share for Cloud Shell storage
- **Private Endpoints**: For secure access to Relay and Storage
- **Private DNS Zones**: For private endpoint name resolution
- **Role Assignments**: Proper permissions for Azure Container Instance Service

#### Customization

Modify `main.parameters.json` to customize:
- **location**: Azure region for deployment
- **baseName**: Prefix for resource names
- **vnetAddressPrefix**: VNET address space (default: 10.0.0.0/16)
- **cloudShellSubnetPrefix**: Cloud Shell subnet range (default: 10.0.1.0/24)
- **relaySubnetPrefix**: Relay subnet range (default: 10.0.2.0/24)
- **fileShareName**: Storage file share name (default: testshare)

## Manual Workflow - GitHub Copilot Agent Mode

### VS Code Extensions
- GitHub Copilot (required for agent mode)
- Azure Account (recommended)
- Azure CLI Tools (recommended)

## Manual Workflow - GitHub Copilot Agent Mode

For step-by-step manual setup using GitHub Copilot, see the manual workflow instructions below.

### VS Code Extensions
- GitHub Copilot (required for agent mode)
- Azure Account (recommended)
- Azure CLI Tools (recommended)

### Method 1: Using the Agent Prompt File

1. **Open the Project**
   ```
   code /path/to/cloudshellinavnet
   ```

2. **Open the Agent Prompt**
   - Open `vnet_full_setup.md` in VS Code
   - This file contains the workflow definitions

3. **Activate GitHub Copilot Chat**
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type "Copilot: Open Chat"
   - Or use the chat icon in the sidebar

4. **Run Workflow 1 in Agent Mode**
   ```
   @workspace Run Workflow 1 in agent mode from agent_prompt.md
   ```
   
   Or more specifically:
   ```
   Execute the workflow in agent_prompt.md - I want to create Cloud Shell in VNET infrastructure
   ```

5. **Specify Location When Prompted**
   - The agent will ask for an Azure region
   - Example responses: `eastus`, `westus2`, `germanywestcentral`, etc.

6. **Monitor Progress**
   - The agent will execute each step automatically
   - View Azure CLI commands and outputs in the terminal
   - Infrastructure creation takes 5-10 minutes

7. **Launch Cloud Shell in a VNET**
    - Open the [Azure Portal](https://portal.azure.com/)
    - Navigate to "Cloud Shell" from the top navigation bar
    - Select "Bash" or "PowerShell" as preferred
    - In the Cloud Shell setup dialog, check "Use an existing private virtual network" and following the setup.
    - Complete the setup and verify Cloud Shell is running within your specified VNET

Note: If you want to set this up step by step manually, use the `vnet_step_by_step.md`.

## Files in this Repository

- `main.bicep` - Main Bicep template for infrastructure deployment
- `main.parameters.json` - Parameters file for customizing the deployment
- `deploy.sh` - Automated deployment script
- `cleanup.sh` - Automated cleanup script
- `vnet_full_setup.md` - Single workflow specification for GitHub Copilot Agent
- `vnet_step_by_step.md` - Detailed step-by-step manual workflows
- `README.md` - This documentation file

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure you have Contributor or Owner access to the subscription
2. **Quota Limits**: Check regional quotas for NAT Gateway, Public IPs, and other resources
3. **Naming Conflicts**: The deployment uses unique suffixes, but you can modify the baseName parameter
4. **Region Availability**: Some Azure services may not be available in all regions

### Deployment Validation

After deployment, verify:
```bash
# List all resources in the resource group
az resource list --resource-group <your-rg-name> --output table

# Check network profile
az network profile show --name cloudshell-networkprofile --resource-group <your-rg-name>

# Check relay namespace
az relay namespace show --name <relay-namespace-name> --resource-group <your-rg-name>
```