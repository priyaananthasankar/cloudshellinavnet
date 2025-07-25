# Workflows

# Workflow 1: Create basic Cloud Shell in a VNET setup
- Prompt the user to specify a location/region before creating a new resource group. Do not make assumptions about the location unless the user explicitly requests it.

Inside this resource group:
- Create a VNET
- Create 2 subnets (use default values for IP ranges)
  - cloudshellsubnet (delegate container groups to this subnet)
  - relaysubnet
- Create an ARM template for network profile and use cloudshellsubnet resource id in the template in current folder.
- Apply the network profile ARM template located in current folder.
- Create a relay namespace

# Workflow 2: Add private link

Workflows 1 is a prerequisite for this:

- Create a private endpoint for relaysubnet and make sure it is integrated with a private DNS zone.
- Create A record for the relay namespace in the private DNS zone

# Workflow 3: Add a storage account

Workflows 1 and 2 are prerequisites for this:

- Create a storage account
- Create another subnet in the VNET called storagesubnet and add a service endpoint for storage accounts.