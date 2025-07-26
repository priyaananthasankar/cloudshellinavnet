#!/bin/bash

# Cloud Shell in VNET - Deployment Script
# This script deploys all the infrastructure required for Azure Cloud Shell in a VNET

set -e  # Exit on any error

# Default values
LOCATION="eastus"
RESOURCE_GROUP_NAME=""
BASE_NAME="cloudshell"
PARAMETERS_FILE="main.parameters.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -g, --resource-group NAME    Resource group name (required)"
    echo "  -l, --location LOCATION      Azure region (default: eastus)"
    echo "  -b, --base-name NAME         Base name for resources (default: cloudshell)"
    echo "  -p, --parameters FILE        Parameters file (default: main.parameters.json)"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -g my-cloudshell-rg"
    echo "  $0 -g my-cloudshell-rg -l westus2 -b myshell"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP_NAME="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -b|--base-name)
            BASE_NAME="$2"
            shift 2
            ;;
        -p|--parameters)
            PARAMETERS_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$RESOURCE_GROUP_NAME" ]]; then
    print_error "Resource group name is required. Use -g or --resource-group option."
    show_usage
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in to Azure
print_status "Checking Azure CLI authentication..."
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Get current subscription info
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
SUBSCRIPTION_NAME=$(az account show --query name --output tsv)
print_success "Using subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Update parameters file with provided values
if [[ -f "$PARAMETERS_FILE" ]]; then
    print_status "Updating parameters file with provided values..."
    # Create a temporary updated parameters file
    jq --arg location "$LOCATION" --arg baseName "$BASE_NAME" \
       '.parameters.location.value = $location | .parameters.baseName.value = $baseName' \
       "$PARAMETERS_FILE" > "${PARAMETERS_FILE}.tmp"
    mv "${PARAMETERS_FILE}.tmp" "$PARAMETERS_FILE"
    print_success "Parameters file updated"
else
    print_warning "Parameters file '$PARAMETERS_FILE' not found. Using inline parameters."
fi

# Create resource group
print_status "Creating resource group '$RESOURCE_GROUP_NAME' in '$LOCATION'..."
if az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION" &> /dev/null; then
    print_success "Resource group created successfully"
else
    print_warning "Resource group might already exist or there was an issue creating it"
fi

# Deploy the Bicep template
print_status "Starting Bicep template deployment..."
print_status "This may take 10-15 minutes to complete..."

DEPLOYMENT_NAME="cloudshell-vnet-$(date +%Y%m%d-%H%M%S)"

if [[ -f "$PARAMETERS_FILE" ]]; then
    # Deploy with parameters file
    az deployment group create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file main.bicep \
        --parameters "@$PARAMETERS_FILE" \
        --name "$DEPLOYMENT_NAME" \
        --verbose
else
    # Deploy with inline parameters
    az deployment group create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file main.bicep \
        --parameters location="$LOCATION" baseName="$BASE_NAME" \
        --name "$DEPLOYMENT_NAME" \
        --verbose
fi

if [[ $? -eq 0 ]]; then
    print_success "Deployment completed successfully!"
    
    # Get deployment outputs
    print_status "Retrieving deployment outputs..."
    
    VNET_ID=$(az deployment group show --resource-group "$RESOURCE_GROUP_NAME" --name "$DEPLOYMENT_NAME" --query properties.outputs.vnetId.value --output tsv)
    NETWORK_PROFILE_ID=$(az deployment group show --resource-group "$RESOURCE_GROUP_NAME" --name "$DEPLOYMENT_NAME" --query properties.outputs.networkProfileId.value --output tsv)
    RELAY_NAMESPACE_NAME=$(az deployment group show --resource-group "$RESOURCE_GROUP_NAME" --name "$DEPLOYMENT_NAME" --query properties.outputs.relayNamespaceName.value --output tsv)
    STORAGE_ACCOUNT_NAME=$(az deployment group show --resource-group "$RESOURCE_GROUP_NAME" --name "$DEPLOYMENT_NAME" --query properties.outputs.storageAccountName.value --output tsv)
    
    echo ""
    echo "=== DEPLOYMENT SUMMARY ==="
    echo "Resource Group: $RESOURCE_GROUP_NAME"
    echo "Location: $LOCATION"
    echo "VNET ID: $VNET_ID"
    echo "Network Profile ID: $NETWORK_PROFILE_ID"
    echo "Relay Namespace: $RELAY_NAMESPACE_NAME"
    echo "Storage Account: $STORAGE_ACCOUNT_NAME"
    echo "File Share: testshare"
    echo ""
    
    print_success "Cloud Shell VNET infrastructure is ready!"
    print_status "You can now configure Azure Cloud Shell to use this VNET infrastructure."
    print_status "In the Azure Portal, go to Cloud Shell and select 'Use existing private virtual network'."
    print_status "Use the network profile ID: $NETWORK_PROFILE_ID"
    
else
    print_error "Deployment failed. Please check the error messages above."
    exit 1
fi