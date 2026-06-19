# Azure EventHub Namespace Terraform Module

## Description

This Terraform module provisions an **Azure EventHub Namespace** — the container for one or more Event Hubs.

This module follows the **single-resource module pattern** where each module creates exactly one Azure resource. This simplifies Terraform state management and allows for flexible composition at the project level using `for_each` loops.

This module is part of the **Commercial IoT Coffee project** and is designed to work with the `eventhub` and `eventhub-consumer-group` modules.

## Usage

### Minimal example

```hcl
module "eventhub_namespace" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub-namespace?ref=main"

  resource_group_name = "my-resource-group"
  location            = "North Europe"
  namespace_name      = "coffee-eventhub-ns"
}
```

### Production example with managed identity

```hcl
module "eventhub_namespace" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub-namespace?ref=main"

  resource_group_name          = "coffee-iot-rg"
  location                     = "North Europe"
  namespace_name               = "coffee-eventhub-ns"
  sku                          = "Standard"
  capacity                     = 2
  auto_inflate_enabled         = true
  maximum_throughput_units     = 20
  public_network_access_enabled = false
  local_authentication_enabled  = false
  minimum_tls_version          = "1.2"

  identity = {
    type = "SystemAssigned"
  }
}
```

### With User Assigned Managed Identity

```hcl
module "eventhub_namespace" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub-namespace?ref=main"

  resource_group_name = "my-resource-group"
  namespace_name      = "coffee-eventhub-ns"

  identity = {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.example.id]
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `resource_group_name` | The name of the resource group. | `string` | — | Yes |
| `location` | The Azure region. | `string` | `"North Europe"` | No |
| `namespace_name` | The name of the EventHub Namespace. | `string` | — | Yes |
| `sku` | Namespace tier: `Basic`, `Standard`, or `Premium`. | `string` | `"Standard"` | No |
| `capacity` | Throughput units (1–2 for this configuration). | `number` | `1` | No |
| `auto_inflate_enabled` | Enable Auto Inflate (Standard only). | `bool` | `false` | No |
| `maximum_throughput_units` | Max throughput when auto inflate is on (1–40). | `number` | `null` | No |
| `public_network_access_enabled` | Allow public network access. | `bool` | `true` | No |
| `local_authentication_enabled` | Enable SAS authentication. | `bool` | `true` | No |
| `minimum_tls_version` | Minimum TLS version: `1.0`, `1.1`, `1.2`. | `string` | `"1.2"` | No |
| `identity` | Managed identity configuration. | `object` | `null` | No |

### `identity` block

| Name | Description | Required |
|------|-------------|----------|
| `type` | Identity type: `SystemAssigned` or `UserAssigned` | Yes |
| `identity_ids` | List of User Assigned Managed Identity IDs (required when type is `UserAssigned`) | No |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `id` | Resource ID of the EventHub Namespace. | No |
| `name` | Name of the EventHub Namespace. | No |
| `default_primary_connection_string` | Primary connection string (RootManageSharedAccessKey). | Yes |
| `default_secondary_connection_string` | Secondary connection string. | Yes |
| `default_primary_key` | Primary access key. | Yes |
| `default_secondary_key` | Secondary access key. | Yes |
| `identity` | Managed identity block of the namespace. | No |

## Notes

- This module does **not** create or manage resource groups. You must provide a pre-existing resource group via `resource_group_name`.
- For creating Event Hubs within this namespace, use the `eventhub` module.
- For creating consumer groups, use the `eventhub-consumer-group` module.
