#!/bin/bash

# Cloud Shell in VNET - Cleanup Script
# This script removes all resources created for Azure Cloud Shell in a VNET

set -e  # Exit on any error

# Default values
RESOURCE_GROUP_NAME=""
FORCE_DELETE=false

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
    echo "  -g, --resource-group NAME    Resource group name to delete (required)"
    echo "  -f, --force                  Skip confirmation prompt"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -g my-cloudshell-rg"
    echo "  $0 -g my-cloudshell-rg --force"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP_NAME="$2"
            shift 2
            ;;
        -f|--force)
            FORCE_DELETE=true
            shift
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

# Check if resource group exists
print_status "Checking if resource group '$RESOURCE_GROUP_NAME' exists..."
if ! az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
    print_warning "Resource group '$RESOURCE_GROUP_NAME' does not exist or you don't have access to it."
    exit 0
fi

# List resources in the group
print_status "Resources in '$RESOURCE_GROUP_NAME':"
az resource list --resource-group "$RESOURCE_GROUP_NAME" --output table

# Confirmation prompt (unless force flag is used)
if [[ "$FORCE_DELETE" != true ]]; then
    echo ""
    print_warning "⚠️  This will DELETE ALL RESOURCES in the resource group '$RESOURCE_GROUP_NAME'!"
    print_warning "This action CANNOT be undone!"
    echo ""
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " -r
    if [[ ! $REPLY =~ ^yes$ ]]; then
        print_status "Operation cancelled."
        exit 0
    fi
fi

# Delete the resource group
print_status "Deleting resource group '$RESOURCE_GROUP_NAME'..."
print_status "This may take several minutes to complete..."

# Use --no-wait for async deletion, then poll for completion
az group delete --name "$RESOURCE_GROUP_NAME" --yes --no-wait

print_status "Deletion initiated. Monitoring progress..."

# Poll for completion
while az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; do
    print_status "Still deleting resources... (checking again in 30 seconds)"
    sleep 30
done

print_success "Resource group '$RESOURCE_GROUP_NAME' has been successfully deleted!"
print_success "All Cloud Shell VNET infrastructure has been cleaned up."

echo ""
echo "=== CLEANUP SUMMARY ==="
echo "Resource Group: $RESOURCE_GROUP_NAME (DELETED)"
echo "All associated resources have been removed:"
echo "  ✓ Virtual Network and Subnets"
echo "  ✓ Network Profile"
echo "  ✓ NAT Gateway and Public IP"
echo "  ✓ Azure Relay Namespace"
echo "  ✓ Storage Account and File Share"
echo "  ✓ Private Endpoints"
echo "  ✓ Private DNS Zones"
echo "  ✓ Role Assignments"
echo ""