# Azure IoT Hub Terraform Module

## Description

This Terraform module provisions an **Azure IoT Hub**, the cloud gateway for IoT devices. It supports managed identity, custom message routing endpoints, message routes, enrichments, fallback route, and cloud-to-device messaging configuration.

> **Important:** Endpoints, routes, enrichments, and fallback_route can be defined either inline within this module **or** via the corresponding `azurerm_iothub_endpoint_*`, `azurerm_iothub_route`, `azurerm_iothub_enrichment`, and `azurerm_iothub_fallback_route` resources — but **never both** for the same IoT Hub. Mixing approaches causes spurious plan diffs.

## Usage

### Minimal example

```hcl
module "iothub" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/iothub?ref=main"

  name                = "coffee-iot-hub"
  resource_group_name = "my-resource-group"
  location            = "North Europe"
}
```

### With System Assigned Identity and EventHub endpoint (IoT Coffee pattern)

```hcl
module "iothub" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/iothub?ref=main"

  name                         = "coffee-iot-hub"
  resource_group_name          = "my-resource-group"
  location                     = "North Europe"
  sku_name                     = "S1"
  sku_capacity                 = 1
  local_authentication_enabled = false
  min_tls_version              = "1.2"

  identity = {
    type = "SystemAssigned"
  }

  endpoints = [
    {
      type              = "AzureIotHub.EventHub"
      name              = "coffee-eventhub-endpoint"
      connection_string = module.eventhub.namespace_default_primary_connection_string
    }
  ]

  routes = [
    {
      name           = "telemetry-to-eventhub"
      source         = "DeviceMessages"
      condition      = "true"
      endpoint_names = ["coffee-eventhub-endpoint"]
      enabled        = true
    }
  ]

  fallback_route = {
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["events"]
    enabled        = true
  }
}
```

### With Device Provisioning Service integration (IoT Coffee pattern)

```hcl
module "iothub" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/iothub?ref=main"

  name                = "coffee-iot-hub"
  resource_group_name = "my-resource-group"
  location            = "North Europe"
  sku_name            = "S1"
  sku_capacity        = 1
}

module "iothub_dps" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/iothub-dps?ref=main"

  name                = "coffee-iot-dps"
  resource_group_name = "my-resource-group"
  location            = "North Europe"
  allocation_policy   = "Hashed"

  linked_hubs = [
    {
      connection_string = module.iothub.shared_access_policy[0].primary_connection_string
      location          = "North Europe"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | The name of the IoT Hub. | `string` | — | Yes |
| `resource_group_name` | The name of the resource group. | `string` | — | Yes |
| `location` | The Azure region. | `string` | `"North Europe"` | No |
| `sku_name` | SKU name: `B1`, `B2`, `B3`, `F1`, `S1`, `S2`, `S3`. | `string` | `"S1"` | No |
| `sku_capacity` | Number of provisioned units. | `number` | `1` | No |
| `local_authentication_enabled` | Enable SAS token authentication. | `bool` | `true` | No |
| `public_network_access_enabled` | Allow public network access. | `bool` | `true` | No |
| `min_tls_version` | Minimum TLS version: `1.0`, `1.1`, `1.2`. | `string` | `"1.2"` | No |
| `identity` | Managed identity configuration. See [identity block](#identity-block). | `object` | `null` | No |
| `endpoints` | List of custom routing endpoints. See [endpoints block](#endpoints-block). | `list(object)` | `[]` | No |
| `routes` | List of message routing rules. See [routes block](#routes-block). | `list(object)` | `[]` | No |
| `enrichments` | List of message enrichments. | `list(object)` | `[]` | No |
| `fallback_route` | Fallback route for unmatched messages. | `object` | `null` | No |
| `cloud_to_device` | Cloud-to-device messaging settings. | `object` | `null` | No |

### `identity` block

| Name | Description | Required |
|------|-------------|----------|
| `type` | `SystemAssigned`, `UserAssigned`, or `SystemAssigned, UserAssigned` | Yes |
| `identity_ids` | List of User Assigned Managed Identity resource IDs | No |

### `endpoints` block

| Name | Description | Required |
|------|-------------|----------|
| `type` | `AzureIotHub.StorageContainer`, `AzureIotHub.ServiceBusQueue`, `AzureIotHub.ServiceBusTopic`, `AzureIotHub.EventHub` | Yes |
| `name` | Endpoint name | Yes |
| `connection_string` | Connection string (for `keyBased` auth) | No |
| `authentication_type` | `keyBased` or `identityBased` | No |
| `identity_id` | User Assigned Identity ID (for `identityBased` auth) | No |
| `container_name` | Storage container name (for `StorageContainer`) | No |
| `encoding` | `Avro`, `AvroDeflate`, or `JSON` | No |
| `file_name_format` | Blob file naming format | No |
| `batch_frequency_in_seconds` | Write interval (60–720s) | No |
| `max_chunk_size_in_bytes` | Chunk size (10MB–500MB) | No |

> **Note:** `endpoints` is marked `sensitive = true` because it may contain connection strings.

### `routes` block

| Name | Description | Required |
|------|-------------|----------|
| `name` | Route name | Yes |
| `source` | `DeviceMessages`, `DeviceConnectionStateEvents`, `DeviceLifecycleEvents`, etc. | Yes |
| `endpoint_names` | List of target endpoint names | Yes |
| `condition` | Routing condition expression | No |
| `enabled` | Whether the route is active | No |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `id` | The resource ID of the IoT Hub. | No |
| `name` | The name of the IoT Hub. | No |
| `hostname` | The hostname of the IoT Hub. | No |
| `event_hub_events_endpoint` | EventHub-compatible endpoint for device telemetry. | No |
| `event_hub_events_path` | EventHub-compatible path for device telemetry. | No |
| `event_hub_operations_endpoint` | EventHub-compatible endpoint for device operations. | No |
| `event_hub_operations_path` | EventHub-compatible path for device operations. | No |
| `identity` | The managed identity block (contains `principal_id`, `tenant_id`). | No |
| `shared_access_policy` | Shared access policies with connection strings and keys. | Yes |

## Breaking Change

This module does **not** create or manage resource groups.

**You must provide a pre-existing resource group** via `resource_group_name`. Resource groups should be created and managed outside of this module (e.g. at the subscription/landing-zone level).