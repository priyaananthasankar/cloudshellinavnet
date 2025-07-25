# Cloud Shell in VNET - Agent Automation

This repository contains automated workflows for setting up Azure Cloud Shell in a Virtual Network (VNET) using VS Code with GitHub Copilot in Agent mode.

## Overview

The project demonstrates how to:
- Create Azure infrastructure for Cloud Shell VNET integration
- Set up private networking with Azure Relay
- Configure private DNS zones for internal resolution
- Simulate network disconnection scenarios (TBD)
- Clean up resources automatically 

## Prerequisites

### Required Tools
1. **VS Code** with GitHub Copilot extension
2. **Azure CLI** installed and authenticated
3. **Azure Subscription** with appropriate permissions

### Azure CLI Setup
```bash
# Install Azure CLI (if not already installed)
# macOS
brew install azure-cli

# Login to Azure
az login

# Verify login
az account show
```

### VS Code Extensions
- GitHub Copilot (required for agent mode)
- Azure Account (recommended)
- Azure CLI Tools (recommended)

## How to Run in VS Code Agent Mode

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

Note: If you want to set this up step by step, use the `vnet_step_by_step.md`.