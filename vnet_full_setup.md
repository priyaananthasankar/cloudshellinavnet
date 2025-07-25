# Workflows

## Workflow 1: Set Up Cloud Shell in a VNET

1. Choose a location.
2.  🛠️ Make a resource group.
3. In the resource group:
  - 🌐 Make a VNET.
  - 🧩 Make two subnets (use default IP ranges):
    - `cloudshellsubnet` (for container groups)
    - `relaysubnet`
  - 🏗️ Make a network profile using an ARM template. Use the resource ID of `cloudshellsubnet`.
    - 🏗️ Use the network profile ARM template.
  - 🔍 Make a relay namespace.
  - 🔒 Make a private endpoint for `relaysubnet` and link it to a private DNS zone. Add an A record for the relay namespace in the private DNS zone.
  - 📄 Add a NAT gateway with a public IP
  - 🧩 Associate it with cloud shell subnet
  - 🏦 Create a storage account and a file share called testshare
  - 🔐 Add a private endpoint for the storage account

## Cleanup

- 🗑️ Delete the resource group along with all its resources, ensuring that dependencies are properly handled to avoid deletion errors.

---

## Diagram

```mermaid
flowchart TD
    A[Resource Group] --> B[VNET]
    B --> C[cloudshellsubnet]
    B --> D[relaysubnet]
    C --> E[Network Profile<br/>ARM Template]
    B --> F[Relay Namespace]
    D --> G[Private Endpoint]
    G --> H[Private DNS Zone]
    F --> G
    H --> I[A Record for Relay]
    F --> I
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#e8f5e8
    style D fill:#e8f5e8
    style E fill:#fff3e0
    style F fill:#fce4ec
    style G fill:#f1f8e9
    style H fill:#e3f2fd
    style I fill:#e3f2fd
```