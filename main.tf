# Data source for existing resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Event Hub Module - for receiving IoT telemetry
module "eventhub" {
  source = "./AzureRM4/modules/eventhub"

  namespace_name      = "${var.project_prefix}-ehns"
  eventhub_name       = "${var.project_prefix}-telemetry"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  sku                 = var.eventhub_sku
  capacity            = var.eventhub_capacity
  partition_count     = 4
  message_retention   = 1

  # Create consumer groups for different processing scenarios
  consumer_groups = [
    {
      name          = "telemetry-processor"
      user_metadata = "Process device telemetry data"
    },
    {
      name          = "archive-processor"
      user_metadata = "Archive telemetry data for long-term storage"
    }
  ]
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
      connection_string = module.eventhub.iothub_sender_primary_connection_string
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
