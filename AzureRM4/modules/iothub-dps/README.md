# Azure IoT Hub Device Provisioning Service (DPS) Terraform Module

## Description

This Terraform module provisions an **Azure IoT Hub Device Provisioning Service (DPS)**, which enables zero-touch, just-in-time device provisioning to the right IoT hub without requiring human intervention.

The module supports:
- Configurable allocation policies (`Hashed`, `GeoLatency`, `Static`)
- Linking one or more IoT Hubs to the DPS instance
- IP filter rules for network access control
- Public network access toggling
- Data residency configuration

## Usage

### Minimal example (DPS only)

```hcl
module "iothub_dps" {
  source = "./AzureRM4/modules/iothub-dps?ref=main"

  name                = "my-iot-dps"
  resource_group_name = "my-resource-group"
  location            = "North Europe"
}
```

### With linked IoT Hub

```hcl
module "iothub_dps" {
  source = "./AzureRM4/modules/iothub-dps?ref=main"

  name                = "my-iot-dps"
  resource_group_name = "my-resource-group"
  location            = "North Europe"
  allocation_policy   = "Hashed"

  sku_name     = "S1"
  sku_capacity = 1

  linked_hubs = [
    {
      connection_string       = azurerm_iothub.example.primary_connection_string
      location                = "North Europe"
      apply_allocation_policy = true
      allocation_weight       = 1
    }
  ]
}
```

### With IP filter rules

```hcl
module "iothub_dps" {
  source = "./AzureRM4/modules/iothub-dps?ref=main"

  name                = "my-iot-dps"
  resource_group_name = "my-resource-group"
  location            = "North Europe"

  public_network_access_enabled = true

  ip_filter_rules = [
    {
      name    = "allow-corporate"
      ip_mask = "10.0.0.0/8"
      action  = "Accept"
      target  = "all"
    },
    {
      name    = "reject-unknown"
      ip_mask = "0.0.0.0/0"
      action  = "Reject"
      target  = "all"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | The name of the IoT Hub DPS. | `string` | — | Yes |
| `resource_group_name` | The name of the resource group. | `string` | — | Yes |
| `location` | The Azure region. | `string` | `"North Europe"` | No |
| `allocation_policy` | Allocation policy: `Hashed`, `GeoLatency`, or `Static`. | `string` | `"Hashed"` | No |
| `public_network_access_enabled` | Allow requests from public networks. | `bool` | `true` | No |
| `data_residency_enabled` | Enable data residency and disaster recovery. Forces new resource if changed. | `bool` | `false` | No |
| `sku_name` | SKU name. Currently only `S1` is supported. | `string` | `"S1"` | No |
| `sku_capacity` | Number of provisioned DPS units. | `number` | `1` | No |
| `linked_hubs` | List of IoT Hubs to link. See [linked_hub block](#linked_hub-block). | `list(object)` | `[]` | No |
| `ip_filter_rules` | List of IP filter rules. See [ip_filter_rule block](#ip_filter_rule-block). | `list(object)` | `[]` | No |

### `linked_hub` block

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `connection_string` | Connection string to the IoT Hub. | `string` | — | Yes |
| `location` | Azure region of the IoT Hub. | `string` | — | Yes |
| `apply_allocation_policy` | Whether to apply allocation policies to this hub. | `bool` | `true` | No |
| `allocation_weight` | The allocation weight for this hub. | `number` | `1` | No |

> **Note:** `linked_hubs` is marked `sensitive = true` because it contains IoT Hub connection strings.

### `ip_filter_rule` block

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | The name of the filter rule. | `string` | — | Yes |
| `ip_mask` | IP address range in CIDR notation. | `string` | — | Yes |
| `action` | `Accept` or `Reject`. | `string` | — | Yes |
| `target` | `all`, `deviceApi`, or `serviceApi`. | `string` | `"all"` | No |

## Outputs

| Name | Description |
|------|-------------|
| `id` | The resource ID of the IoT Hub DPS. |
| `name` | The name of the IoT Hub DPS. |
| `service_operations_host_name` | The service operations host name. |
| `device_provisioning_host_name` | The device provisioning host name. |
| `id_scope` | The ID scope used by devices during registration. |
| `allocation_policy` | The effective allocation policy. |

## Breaking Change

This module does **not** create or manage resource groups.

**You must provide a pre-existing resource group** via `resource_group_name`. Resource groups should be created and managed outside of this module (e.g. at the subscription/landing-zone level).