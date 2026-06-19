variable "name" {
  description = "The name of the IoT Hub."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the IoT Hub."
  type        = string
}

variable "location" {
  description = "The Azure region where the IoT Hub will be created."
  type        = string
  default     = "North Europe"
}

variable "sku_name" {
  description = "The name of the IoT Hub SKU. Possible values are 'B1', 'B2', 'B3', 'F1', 'S1', 'S2', 'S3'."
  type        = string
  default     = "S1"

  validation {
    condition     = contains(["B1", "B2", "B3", "F1", "S1", "S2", "S3"], var.sku_name)
    error_message = "sku_name must be one of: B1, B2, B3, F1, S1, S2, S3."
  }
}

variable "sku_capacity" {
  description = "The number of provisioned IoT Hub units."
  type        = number
  default     = 1

  validation {
    condition     = var.sku_capacity >= 1
    error_message = "sku_capacity must be at least 1."
  }
}

variable "local_authentication_enabled" {
  description = "If false, SAS tokens with Iot hub scoped SAS keys cannot be used for authentication. Defaults to true."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Is the IoT Hub accessible from a public network? Defaults to true."
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Specifies the minimum TLS version to support for this IoT Hub. Possible values are '1.0', '1.1', '1.2'. Defaults to '1.2'."
  type        = string
  default     = "1.2"

  validation {
    condition     = contains(["1.2"], var.min_tls_version)
    error_message = "min_tls_version must be '1.2'. The older versions are no longer supported."
  }
}

variable "identity" {
  description = <<-EOT
    An optional managed identity block:
    - type          (Required) The type: 'SystemAssigned', 'UserAssigned', or 'SystemAssigned, UserAssigned'.
    - identity_ids  (Optional) A list of User Assigned Managed Identity IDs. Required when type includes 'UserAssigned'.
  EOT
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default = null

  validation {
    condition     = var.identity == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], try(var.identity.type, ""))
    error_message = "identity.type must be 'SystemAssigned', 'UserAssigned', or 'SystemAssigned, UserAssigned'."
  }
}

variable "endpoints" {
  description = <<-EOT
    A list of custom endpoint definitions. Each object supports:
    - type                       (Required) Endpoint type: 'AzureIotHub.StorageContainer', 'AzureIotHub.ServiceBusQueue', 'AzureIotHub.ServiceBusTopic', 'AzureIotHub.EventHub'.
    - name                       (Required) The name of the endpoint.
    - connection_string          (Optional) Connection string (required for keyBased authentication).
    - authentication_type        (Optional) 'keyBased' or 'identityBased'. Defaults to 'keyBased'.
    - identity_id                (Optional) User Assigned Managed Identity ID for identityBased authentication.
    - endpoint_uri               (Optional) The URI of the endpoint resource (required for identityBased authentication with ServiceBusQueue, ServiceBusTopic, or EventHub).
    - entity_path                (Optional) The entity path of the endpoint (required for identityBased authentication with ServiceBusQueue, ServiceBusTopic, or EventHub).
    - resource_group_name        (Optional) Resource group of the target resource.
    - container_name             (Optional) Storage container name (required for StorageContainer type).
    - encoding                   (Optional) Encoding for storage: 'Avro', 'AvroDeflate', or 'JSON'.
    - file_name_format           (Optional) File name format for storage (e.g. '{iothub}/{partition}_{YYYY}_{MM}_{DD}_{HH}_{mm}').
    - batch_frequency_in_seconds (Optional) Interval at which blobs are written, between 60 and 720 seconds. Defaults to 300.
    - max_chunk_size_in_bytes    (Optional) Maximum chunk size in bytes, between 10485760 and 524288000. Defaults to 314572800.

    NOTE: Endpoints defined here cannot be combined with azurerm_iothub_endpoint_* resources on the same IoT Hub.
  EOT
  type = list(object({
    type                       = string
    name                       = string
    connection_string          = optional(string)
    authentication_type        = optional(string, "keyBased")
    identity_id                = optional(string)
    endpoint_uri               = optional(string)
    entity_path                = optional(string)
    resource_group_name        = optional(string)
    container_name             = optional(string)
    encoding                   = optional(string)
    file_name_format           = optional(string)
    batch_frequency_in_seconds = optional(number)
    max_chunk_size_in_bytes    = optional(number)
  }))
  default   = []
  sensitive = true
}

variable "routes" {
  description = <<-EOT
    A list of message routing rules. Each object supports:
    - name           (Required) The name of the route.
    - source         (Required) The source: 'DeviceMessages', 'DeviceConnectionStateEvents', 'DeviceLifecycleEvents', 'DeviceJobLifecycleEvents', 'DigitalTwinChangeEvents', 'TwinChangeEvents', 'Invalid'.
    - endpoint_names (Required) List of endpoint names to route matched messages to. Currently limited to one.
    - condition      (Optional) Routing condition expression. Defaults to 'true'.
    - enabled        (Optional) Whether the route is enabled. Defaults to true.

    NOTE: Routes defined here cannot be combined with azurerm_iothub_route resources on the same IoT Hub.
  EOT
  type = list(object({
    name           = string
    source         = string
    endpoint_names = list(string)
    condition      = optional(string, "true")
    enabled        = optional(bool, true)
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.routes : contains(
        ["DeviceMessages", "DeviceConnectionStateEvents", "DeviceLifecycleEvents",
        "DeviceJobLifecycleEvents", "DigitalTwinChangeEvents", "TwinChangeEvents", "Invalid"],
        r.source
      )
    ])
    error_message = "Each route source must be a valid IoT Hub message source type."
  }
}

variable "enrichments" {
  description = <<-EOT
    A list of message enrichments applied before delivery. Each object supports:
    - key            (Required) The enrichment key.
    - value          (Required) The enrichment value (e.g. '$twin.tags.Tenant').
    - endpoint_names (Required) List of endpoint names to apply the enrichment to.

    NOTE: Enrichments defined here cannot be combined with azurerm_iothub_enrichment resources on the same IoT Hub.
  EOT
  type = list(object({
    key            = string
    value          = string
    endpoint_names = list(string)
  }))
  default = []
}

variable "fallback_route" {
  description = <<-EOT
    Optional fallback route configuration for messages that do not match any route. Supports:
    - source         (Optional) The message source. Defaults to 'DeviceMessages'.
    - condition      (Optional) Routing condition. Defaults to 'true'.
    - endpoint_names (Required) List of endpoint names for unmatched messages.
    - enabled        (Optional) Whether the fallback route is enabled. Defaults to true.

    NOTE: This block cannot be combined with the azurerm_iothub_fallback_route resource on the same IoT Hub.
  EOT
  type = object({
    source         = optional(string, "DeviceMessages")
    condition      = optional(string, "true")
    endpoint_names = list(string)
    enabled        = optional(bool, true)
  })
  default = null
}

variable "cloud_to_device" {
  description = <<-EOT
    Optional cloud-to-device messaging configuration. Supports:
    - max_delivery_count (Optional) The maximum number of delivery attempts. Between 1 and 100. Defaults to 10.
    - default_ttl        (Optional) The default TTL for cloud-to-device messages in ISO 8601 format. Defaults to 'PT1H'.
    - feedback           (Optional) Feedback queue configuration:
        - time_to_live       (Optional) TTL for feedback messages. Defaults to 'PT1H'.
        - max_delivery_count (Optional) Max delivery attempts for feedback. Defaults to 10.
        - lock_duration      (Optional) Lock duration for feedback. Defaults to 'PT60S'.
  EOT
  type = object({
    max_delivery_count = optional(number, 10)
    default_ttl        = optional(string, "PT1H")
    feedback = optional(object({
      time_to_live       = optional(string, "PT1H")
      max_delivery_count = optional(number, 10)
      lock_duration      = optional(string, "PT60S")
    }))
  })
  default = null
}
