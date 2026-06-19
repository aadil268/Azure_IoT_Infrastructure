# Azure EventHub Terraform Module

## Description

This Terraform module provisions an **Azure Event Hub** — the event stream resource within an Event Hub Namespace.

This module follows the **single-resource module pattern** where each module creates exactly one Azure resource. This simplifies Terraform state management and allows for flexible composition at the project level using `for_each` loops.

This module is part of the **Commercial IoT Coffee project** and is designed to work with the `eventhub-namespace` and `eventhub-consumer-group` modules. It can also be used as the downstream event streaming layer for the `iothub` module.

## Usage

### Minimal example

```hcl
module "eventhub_namespace" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub-namespace?ref=main"

  resource_group_name = "my-resource-group"
  namespace_name      = "coffee-eventhub-ns"
}

module "eventhub" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub?ref=main"

  namespace_id  = module.eventhub_namespace.id
  eventhub_name = "coffee-telemetry"
}
```

### Multiple Event Hubs using for_each

```hcl
module "eventhub_namespace" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub-namespace?ref=main"

  resource_group_name = "coffee-iot-rg"
  namespace_name      = "coffee-eventhub-ns"
}

locals {
  eventhubs = {
    telemetry = {
      name              = "coffee-telemetry"
      partition_count   = 4
      message_retention = 7
    }
    commands = {
      name              = "coffee-commands"
      partition_count   = 2
      message_retention = 1
    }
  }
}

module "eventhubs" {
  source   = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub?ref=main"
  for_each = local.eventhubs

  namespace_id      = module.eventhub_namespace.id
  eventhub_name     = each.value.name
  partition_count   = each.value.partition_count
  message_retention = each.value.message_retention
}
```

### With Capture to Blob Storage (Managed Identity)

```hcl
module "eventhub_namespace" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub-namespace?ref=main"

  resource_group_name          = "my-resource-group"
  namespace_name               = "coffee-eventhub-ns"
  local_authentication_enabled = false

  identity = {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.eventhub.id]
  }
}

module "eventhub" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub?ref=main"

  namespace_id      = module.eventhub_namespace.id
  eventhub_name     = "coffee-telemetry"
  partition_count   = 4
  message_retention = 7

  capture_description = {
    enabled  = true
    encoding = "Avro"
    destination = {
      name                        = "EventHubArchive.AzureBlockBlob"
      archive_name_format         = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
      blob_container_name         = "eventhub-archive"
      storage_account_id          = azurerm_storage_account.archive.id
      storage_authentication_type = "ManagedIdentity"
      storage_authentication_id   = azurerm_user_assigned_identity.eventhub.id
    }
  }
}
```

### IoT Coffee project pattern (with IoT Hub routing)

```hcl
module "eventhub_namespace" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub-namespace?ref=main"

  resource_group_name           = "coffee-iot-rg"
  namespace_name                = "coffee-eventhub-ns"
  sku                           = "Standard"
  capacity                      = 2
  public_network_access_enabled = false
  local_authentication_enabled  = false
}

module "eventhub" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub?ref=main"

  namespace_id      = module.eventhub_namespace.id
  eventhub_name     = "coffee-telemetry"
  partition_count   = 4
  message_retention = 7
}

module "iothub" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/iothub?ref=main"

  name                = "coffee-iot-hub"
  resource_group_name = "coffee-iot-rg"
  location            = "North Europe"

  endpoints = [
    {
      type              = "AzureIotHub.EventHub"
      name              = "coffee-telemetry-endpoint"
      connection_string = module.eventhub_namespace.default_primary_connection_string
    }
  ]

  routes = [
    {
      name           = "telemetry-route"
      source         = "DeviceMessages"
      endpoint_names = ["coffee-telemetry-endpoint"]
      enabled        = true
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `namespace_id` | The resource ID of the EventHub Namespace. | `string` | — | Yes |
| `eventhub_name` | The name of the Event Hub. | `string` | — | Yes |
| `partition_count` | Number of partitions (1–32 for Basic/Standard, 1–1024 for Premium). | `number` | `2` | No |
| `message_retention` | Days to retain events (1–7 for Basic/Standard). Set to `null` for Premium tier. | `number` | `1` | No |
| `status` | `Active`, `Disabled`, or `SendDisabled`. | `string` | `"Active"` | No |
| `capture_description` | Archive settings for Blob Storage capture. See [capture_description block](#capture_description-block). | `object` | `null` | No |

### `capture_description` block

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `enabled` | Whether capture is enabled. | `bool` | — | Yes |
| `encoding` | Encoding format: `Avro` or `AvroDeflate`. | `string` | — | Yes |
| `interval_in_seconds` | Capture interval in seconds (60–900). | `number` | `300` | No |
| `size_limit_in_bytes` | Capture size limit in bytes (10485760–524288000). | `number` | `314572800` | No |
| `skip_empty_archives` | Skip writing empty archive files. | `bool` | `false` | No |
| `destination` | Destination configuration block. | `object` | — | Yes |

#### `destination` block

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | The name of the capture destination (must be `EventHubArchive.AzureBlockBlob`). | `string` | — | Yes |
| `archive_name_format` | Blob naming format (e.g., `{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}`). | `string` | — | Yes |
| `blob_container_name` | Name of the storage container. | `string` | — | Yes |
| `storage_account_id` | Resource ID of the storage account. | `string` | — | Yes |
| `storage_authentication_type` | Authentication type: `SAS` or `ManagedIdentity`. | `string` | `"SAS"` | No |
| `storage_authentication_id` | Resource ID of a User Assigned Managed Identity (required when using `ManagedIdentity`). | `string` | `null` | No |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource ID of the Event Hub. |
| `name` | Name of the Event Hub. |
| `partition_ids` | List of partition IDs for the Event Hub. |

## Notes

- This module does **not** create or manage namespaces, resource groups, or consumer groups.
- The namespace must be created separately using the `eventhub-namespace` module.
- For creating consumer groups, use the `eventhub-consumer-group` module.
- For Premium tier namespaces, set `message_retention` to `null`.
- Use `for_each` at the project level to create multiple Event Hubs within the same namespace.
