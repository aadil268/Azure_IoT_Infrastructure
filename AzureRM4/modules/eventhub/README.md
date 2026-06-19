# Azure EventHub Terraform Module

## Description

This Terraform module provisions a complete **Azure EventHub** setup consisting of:

- **EventHub Namespace** — the container for one or more Event Hubs
- **Event Hub** — the event stream for device telemetry
- **Consumer Groups** — named readers of the Event Hub stream

This module is part of the **Commercial IoT Coffee project** and is designed to work as the downstream event streaming layer for the `iothub` module. IoT Hub can route device telemetry directly to the EventHub created by this module.

## Usage

### Minimal example

```hcl
module "eventhub" {
  source = "./AzureRM4/modules/eventhub"

  resource_group_name = "my-resource-group"
  location            = "North Europe"
  namespace_name      = "coffee-eventhub-ns"
  eventhub_name       = "coffee-telemetry-hub"
}
```

### IoT Coffee project pattern (with IoT Hub routing)

```hcl
module "eventhub" {
  source = "./AzureRM4/modules/eventhub"

  resource_group_name          = "coffee-iot-rg"
  location                     = "North Europe"
  namespace_name               = "coffee-eventhub-ns"
  sku                          = "Standard"
  capacity                     = 1
  public_network_access_enabled = false
  local_authentication_enabled  = false
  minimum_tls_version           = "1.2"

  eventhub_name     = "coffee-telemetry"
  partition_count   = 4
  message_retention = 7

  consumer_groups = [
    { name = "analytics-reader" },
    { name = "monitoring-reader", user_metadata = "Grafana dashboard consumer" },
    { name = "dps-reader",        user_metadata = "Device Provisioning Service reader" }
  ]
}

module "iothub" {
  source = "./AzureRM4/modules/iothub?ref=main"

  name                = "coffee-iot-hub"
  resource_group_name = "coffee-iot-rg"
  location            = "North Europe"

  endpoints = [
    {
      type              = "AzureIotHub.EventHub"
      name              = "coffee-telemetry-endpoint"
      connection_string = module.eventhub.namespace_default_primary_connection_string
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

### With Capture to Blob Storage

```hcl
module "eventhub" {
  source = "./AzureRM4/modules/eventhub"

  resource_group_name = "my-resource-group"
  namespace_name      = "coffee-eventhub-ns"
  eventhub_name       = "coffee-telemetry"
  partition_count     = 2
  message_retention   = 1

  capture_description = {
    enabled  = true
    encoding = "Avro"
    destination = {
      name                = "EventHubArchive.AzureBlockBlob"
      archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
      blob_container_name = "eventhub-archive"
      storage_account_id  = azurerm_storage_account.archive.id
    }
  }
}
```

## Inputs

### Namespace

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `resource_group_name` | The name of the resource group. | `string` | — | Yes |
| `location` | The Azure region. | `string` | `"North Europe"` | No |
| `namespace_name` | The name of the EventHub Namespace. | `string` | — | Yes |
| `sku` | Namespace tier: `Basic`, `Standard`, or `Premium`. | `string` | `"Standard"` | No |
| `capacity` | Throughput units (1–40). | `number` | `1` | No |
| `auto_inflate_enabled` | Enable Auto Inflate (Standard only). | `bool` | `false` | No |
| `maximum_throughput_units` | Max throughput when auto inflate is on (1–40). | `number` | `null` | No |
| `public_network_access_enabled` | Allow public network access. | `bool` | `true` | No |
| `local_authentication_enabled` | Enable SAS authentication. | `bool` | `true` | No |
| `minimum_tls_version` | Minimum TLS version: `1.0`, `1.1`, `1.2`. | `string` | `"1.2"` | No |
| `identity` | Managed identity for the namespace. | `object` | `null` | No |

### Event Hub

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `eventhub_name` | The name of the Event Hub. | `string` | — | Yes |
| `partition_count` | Number of partitions (1–32 for Standard, 1–1024 for Premium). | `number` | `2` | No |
| `message_retention` | Days to retain events (1–7 for Standard). Not used for Premium. | `number` | `1` | No |
| `status` | `Active`, `Disabled`, or `SendDisabled`. | `string` | `"Active"` | No |
| `capture_description` | Archive settings for Blob Storage capture. | `object` | `null` | No |

### Consumer Groups

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `consumer_groups` | List of consumer groups to create. See [consumer_groups block](#consumer_groups-block). | `list(object)` | `[]` | No |

### `consumer_groups` block

| Name | Description | Required |
|------|-------------|----------|
| `name` | Consumer group name (unique within the Event Hub) | Yes |
| `user_metadata` | Arbitrary metadata string | No |

> **Note:** Azure automatically creates the `$Default` consumer group — do not include it in `consumer_groups`.

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `namespace_id` | Resource ID of the EventHub Namespace. | No |
| `namespace_name` | Name of the EventHub Namespace. | No |
| `namespace_default_primary_connection_string` | Primary connection string (RootManageSharedAccessKey). | Yes |
| `namespace_default_secondary_connection_string` | Secondary connection string. | Yes |
| `namespace_default_primary_key` | Primary access key. | Yes |
| `namespace_identity` | Managed identity block of the namespace. | No |
| `eventhub_id` | Resource ID of the Event Hub. | No |
| `eventhub_name` | Name of the Event Hub. | No |
| `eventhub_partition_ids` | List of partition IDs for the Event Hub. | No |
| `consumer_group_ids` | Map of consumer group names to their resource IDs. | No |

## Breaking Change

This module does **not** create or manage resource groups.

**You must provide a pre-existing resource group** via `resource_group_name`. Resource groups should be created and managed outside of this module (e.g. at the subscription/landing-zone level).
