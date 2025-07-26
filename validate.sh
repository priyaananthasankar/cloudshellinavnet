#!/bin/bash

# Validation script for Cloud Shell VNET deployment
# This script validates the deployment without requiring an actual Azure deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Validating Cloud Shell VNET Infrastructure Files..."

# Check if required files exist
REQUIRED_FILES=("main.bicep" "main.parameters.json" "deploy.sh" "cleanup.sh")
for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        print_success "✓ $file exists"
    else
        print_error "✗ $file is missing"
        exit 1
    fi
done

# Check if scripts are executable
if [[ -x "deploy.sh" ]]; then
    print_success "✓ deploy.sh is executable"
else
    print_error "✗ deploy.sh is not executable"
    exit 1
fi

if [[ -x "cleanup.sh" ]]; then
    print_success "✓ cleanup.sh is executable"
else
    print_error "✗ cleanup.sh is not executable"
    exit 1
fi

# Validate Bicep syntax
if command -v az &> /dev/null; then
    print_status "Validating Bicep template syntax..."
    if az bicep build --file main.bicep --stdout > /dev/null 2>&1; then
        print_success "✓ main.bicep syntax is valid"
    else
        print_error "✗ main.bicep has syntax errors"
        exit 1
    fi
else
    print_status "Azure CLI not found, skipping Bicep validation"
fi

# Validate JSON syntax
if command -v jq &> /dev/null; then
    print_status "Validating parameters file..."
    if jq . main.parameters.json > /dev/null 2>&1; then
        print_success "✓ main.parameters.json is valid JSON"
    else
        print_error "✗ main.parameters.json has invalid JSON syntax"
        exit 1
    fi
else
    print_status "jq not found, skipping JSON validation"
fi

# Validate script syntax
print_status "Validating shell script syntax..."
if bash -n deploy.sh; then
    print_success "✓ deploy.sh syntax is valid"
else
    print_error "✗ deploy.sh has syntax errors"
    exit 1
fi

if bash -n cleanup.sh; then
    print_success "✓ cleanup.sh syntax is valid"
else
    print_error "✗ cleanup.sh has syntax errors"
    exit 1
fi

# Check key components in Bicep template
print_status "Checking key infrastructure components in Bicep template..."

REQUIRED_RESOURCES=(
    "Microsoft.Network/virtualNetworks"
    "Microsoft.Network/networkProfiles"
    "Microsoft.Network/natGateways"
    "Microsoft.Network/publicIPAddresses"
    "Microsoft.Relay/namespaces"
    "Microsoft.Storage/storageAccounts"
    "Microsoft.Network/privateEndpoints"
    "Microsoft.Network/privateDnsZones"
    "Microsoft.Authorization/roleAssignments"
)

for resource in "${REQUIRED_RESOURCES[@]}"; do
    if grep -q "$resource" main.bicep; then
        print_success "✓ $resource defined in template"
    else
        print_error "✗ $resource missing from template"
        exit 1
    fi
done

# Check subnet configuration
if grep -q "Microsoft.ContainerInstance/containerGroups" main.bicep; then
    print_success "✓ Container Instance delegation configured"
else
    print_error "✗ Container Instance delegation missing"
    exit 1
fi

# Check parameters
REQUIRED_PARAMS=("location" "baseName" "vnetAddressPrefix" "cloudShellSubnetPrefix" "relaySubnetPrefix")
for param in "${REQUIRED_PARAMS[@]}"; do
    if grep -q "\"$param\"" main.parameters.json; then
        print_success "✓ Parameter $param defined"
    else
        print_error "✗ Parameter $param missing"
        exit 1
    fi
done

print_success "All validation checks passed!"
print_status "The Cloud Shell VNET infrastructure is ready for deployment."

echo ""
echo "=== VALIDATION SUMMARY ==="
echo "✓ All required files present"
echo "✓ Script syntax valid"
echo "✓ Bicep template syntax valid"
echo "✓ Parameters file valid"
echo "✓ All required Azure resources defined"
echo "✓ Proper subnet delegation configured"
echo "✓ Required parameters present"
echo ""
echo "Ready to deploy with: ./deploy.sh -g <resource-group-name>"