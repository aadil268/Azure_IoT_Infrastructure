# Data source for existing resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Event Hub Namespace Module - creates the namespace
module "eventhub_namespace" {
  source = "./AzureRM4/modules/eventhub-namespace"

  namespace_name      = "${var.project_prefix}-ehns"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  sku                 = var.eventhub_sku
  capacity            = var.eventhub_capacity
}

# Event Hub Module - creates the event hub entity
module "eventhub" {
  source = "./AzureRM4/modules/eventhub"

  eventhub_name     = "${var.project_prefix}-telemetry"
  namespace_id      = module.eventhub_namespace.id
  partition_count   = 4
  message_retention = 1
}

# Event Hub Consumer Group - telemetry processor
module "eventhub_consumer_group_telemetry" {
  source = "./AzureRM4/modules/eventhub-consumer-group"

  resource_group_name = data.azurerm_resource_group.main.name
  namespace_name      = module.eventhub_namespace.name
  eventhub_name       = module.eventhub.name
  consumer_group_name = "telemetry-processor"
  user_metadata       = "Process device telemetry data"
}

# Event Hub Consumer Group - archive processor
module "eventhub_consumer_group_archive" {
  source = "./AzureRM4/modules/eventhub-consumer-group"

  resource_group_name = data.azurerm_resource_group.main.name
  namespace_name      = module.eventhub_namespace.name
  eventhub_name       = module.eventhub.name
  consumer_group_name = "archive-processor"
  user_metadata       = "Archive telemetry data for long-term storage"
}

# Event Hub Authorization Rule - for IoT Hub routing
resource "azurerm_eventhub_authorization_rule" "iothub_sender" {
  name                = "iothub-sender"
  namespace_name      = module.eventhub_namespace.name
  eventhub_name       = module.eventhub.name
  resource_group_name = data.azurerm_resource_group.main.name

  listen = true
  send   = true
  manage = false
}

# IoT Hub Module - main hub for device connectivity
module "iothub" {
  source = "./AzureRM4/modules/iothub"

  name                = var.iothub_name_override != null ? var.iothub_name_override : "${var.project_prefix}-iothub"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  sku_name            = var.iothub_sku_name
  sku_capacity        = var.iothub_sku_capacity

  # Enable local authentication for Raspberry Pi simulator
  local_authentication_enabled  = true
  public_network_access_enabled = true
  min_tls_version               = "1.2"

  # Configure Event Hub endpoint for routing telemetry
  endpoints = [
    {
      type              = "AzureIotHub.EventHub"
      name              = "telemetry-endpoint"
      connection_string = azurerm_eventhub_authorization_rule.iothub_sender.primary_connection_string
    }
  ]

  # Route device messages to Event Hub
  routes = [
    {
      name           = "telemetry-route"
      source         = "DeviceMessages"
      condition      = "true"
      endpoint_names = ["telemetry-endpoint"]
      enabled        = true
    }
  ]

  # Cloud-to-device messaging configuration
  cloud_to_device = {
    max_delivery_count = 10
    default_ttl        = "PT1H"
    feedback = {
      time_to_live       = "PT1H"
      max_delivery_count = 10
      lock_duration      = "PT60S"
    }
  }
}

# IoT Hub DPS Module - Device Provisioning Service
module "iothub_dps" {
  source = "./AzureRM4/modules/iothub-dps"

  name                = "${var.project_prefix}-dps"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  allocation_policy   = var.dps_allocation_policy
  sku_name            = "S1"
  sku_capacity        = 1

  # Link to the IoT Hub
  linked_hubs = [
    {
      connection_string       = module.iothub.iothubowner_connection_string
      location                = var.location
      apply_allocation_policy = true
      allocation_weight       = 1
    }
  ]
}
