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
- Create a file share for this storage account called testshare

# Workflow 4: Relay endpoint connectivity

Test net connection and lookup of relay namespace from laptop.

# Workflow 5: Storage account access

Test nslookup of storage account from laptop and it should succeed and show a public IP.

# Workflow 6: Storage behind a private endpoint

Add a private endpoint to the storage account and test nslookup of storage account (file endpoint only) from laptop and it should show public IP.

# Workflow 7: Lock down storage account

Workflow 3 and 6 are prerequisites.
Lock down storage by disabling public network access

# Workflow 8: Test connectivity

Create a test subnet in the VNET.

- Create a VM inside the test subnet (try different sizes etc to successfully create one) and inject it into the vnet to test storage connectivity. 

- If VM's are unavailable, use basic ubuntu ACI with subnetifref inside the test subnet (do not touch the existing network profile). 

- If ACI creation fails due to docker registry issues, then provide some way of definitive proof.

- Test connectivity of storage and relay endpoints.

# Workflow 9: Lock down Azure Relay

In Azure Relay networking, disable public access. Repeat workflow 8.

# Cleanup:

Delete the resource group and all resources inside it
