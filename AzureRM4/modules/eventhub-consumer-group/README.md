# Azure EventHub Consumer Group Terraform Module

## Description

This Terraform module provisions an **Azure EventHub Consumer Group** — a named reader of an Event Hub stream.

This module follows the **single-resource module pattern** where each module creates exactly one Azure resource. This simplifies Terraform state management and allows for flexible composition at the project level using `for_each` loops.

Consumer groups enable multiple independent consumers to read from the same Event Hub stream, each maintaining their own position (offset) in the stream.

## Usage

### Single consumer group

```hcl
module "analytics_consumer_group" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub-consumer-group?ref=main"

  resource_group_name   = "my-resource-group"
  namespace_name        = "coffee-eventhub-ns"
  eventhub_name         = "coffee-telemetry"
  consumer_group_name   = "analytics-reader"
}
```

### Multiple consumer groups using for_each

```hcl
locals {
  consumer_groups = {
    analytics = {
      name          = "analytics-reader"
      user_metadata = "Real-time analytics processing"
    }
    monitoring = {
      name          = "monitoring-reader"
      user_metadata = "Grafana dashboard consumer"
    }
    archival = {
      name          = "archival-reader"
      user_metadata = "Long-term storage processor"
    }
  }
}

module "consumer_groups" {
  source   = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub-consumer-group?ref=main"
  for_each = local.consumer_groups

  resource_group_name = "my-resource-group"
  namespace_name      = module.eventhub_namespace.name
  eventhub_name       = module.eventhub.name
  consumer_group_name = each.value.name
  user_metadata       = each.value.user_metadata
}
```

### With Event Hub module

```hcl
module "eventhub_namespace" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub-namespace?ref=main"

  resource_group_name = "coffee-iot-rg"
  namespace_name      = "coffee-eventhub-ns"
}

module "eventhub" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub?ref=main"

  namespace_id  = module.eventhub_namespace.id
  eventhub_name = "coffee-telemetry"
}

module "dps_consumer_group" {
  source = "git::https://dev.azure.com/AADIL/ABBASI-Terraform-Module-Library/_git/cat-tf-modules//AzureRM4/modules/eventhub-consumer-group?ref=main"

  resource_group_name = "coffee-iot-rg"
  namespace_name      = module.eventhub_namespace.name
  eventhub_name       = module.eventhub.name
  consumer_group_name = "dps-reader"
  user_metadata       = "Device Provisioning Service reader"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `resource_group_name` | The name of the resource group. | `string` | — | Yes |
| `namespace_name` | The name of the EventHub Namespace. | `string` | — | Yes |
| `eventhub_name` | The name of the Event Hub. | `string` | — | Yes |
| `consumer_group_name` | The name of the consumer group (unique within the Event Hub). | `string` | — | Yes |
| `user_metadata` | Arbitrary user metadata string. | `string` | `null` | No |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource ID of the Event Hub Consumer Group. |
| `name` | Name of the Event Hub Consumer Group. |

## Notes

- This module does **not** create or manage resource groups, namespaces, or Event Hubs. These must already exist.
- Azure automatically creates the `$Default` consumer group — you don't need to create it with this module.
- Consumer group names must be unique within an Event Hub.
- Use `for_each` at the project level to create multiple consumer groups efficiently.
