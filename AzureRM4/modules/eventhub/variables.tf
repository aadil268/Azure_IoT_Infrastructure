variable "resource_group_name" {
  description = "The name of the resource group in which to create the EventHub resources."
  type        = string
}

variable "location" {
  description = "The Azure region where the EventHub Namespace will be created."
  type        = string
  default     = "North Europe"
}

# ─── Namespace ───────────────────────────────────────────────────────────────

variable "namespace_name" {
  description = "The name of the EventHub Namespace."
  type        = string
}

variable "sku" {
  description = "The SKU tier for the EventHub Namespace. Possible values are 'Basic', 'Standard', and 'Premium'. Note: changing to 'Premium' forces a new resource."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be 'Basic', 'Standard', or 'Premium'."
  }
}

variable "capacity" {
  description = "The Capacity / Throughput Units for a Standard SKU namespace. Valid values are 1 to 40. Defaults to 1."
  type        = number
  default     = 1

  validation {
    condition     = var.capacity >= 1 && var.capacity <= 40
    error_message = "capacity must be between 1 and 40."
  }
}

variable "auto_inflate_enabled" {
  description = "Is Auto Inflate enabled for the EventHub Namespace? Only valid for Standard tier. Defaults to false."
  type        = bool
  default     = false
}

variable "maximum_throughput_units" {
  description = "The maximum number of throughput units when Auto Inflate is enabled. Valid values are 1 to 40. Only used when auto_inflate_enabled is true."
  type        = number
  default     = null

  validation {
    condition     = var.maximum_throughput_units == null || (var.maximum_throughput_units >= 1 && var.maximum_throughput_units <= 40)
    error_message = "maximum_throughput_units must be between 1 and 40."
  }
}

variable "public_network_access_enabled" {
  description = "Is public network access enabled for the EventHub Namespace? Defaults to true."
  type        = bool
  default     = true
}

variable "local_authentication_enabled" {
  description = "Is SAS authentication enabled for the EventHub Namespace? Defaults to true."
  type        = bool
  default     = true
}

variable "minimum_tls_version" {
  description = "The minimum supported TLS version for this EventHub Namespace. Valid values are '1.0', '1.1', '1.2'. Defaults to '1.2'."
  type        = string
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "minimum_tls_version must be '1.0', '1.1', or '1.2'."
  }
}

variable "identity" {
  description = <<-EOT
    An optional managed identity block for the EventHub Namespace:
    - type          (Required) The type: 'SystemAssigned', 'UserAssigned', or 'SystemAssigned, UserAssigned'.
    - identity_ids  (Optional) A list of User Assigned Managed Identity IDs.
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

# ─── Event Hub ────────────────────────────────────────────────────────────────

variable "eventhub_name" {
  description = "The name of the Event Hub."
  type        = string
}

variable "partition_count" {
  description = "The number of partitions for the Event Hub. For Basic and Standard tiers: 1 to 32. For Premium tier: 1 to 1024."
  type        = number
  default     = 2

  validation {
    condition     = var.partition_count >= 1 && var.partition_count <= 1024
    error_message = "partition_count must be between 1 and 1024."
  }
}

variable "message_retention" {
  description = "The number of days to retain events. For Basic: 1. For Standard: 1 to 7. Not applicable for Premium (use retention_description instead). Defaults to 1."
  type        = number
  default     = 1

  validation {
    condition     = var.message_retention >= 1 && var.message_retention <= 90
    error_message = "message_retention must be between 1 and 90 days."
  }
}

variable "status" {
  description = "The status of the Event Hub. Possible values are 'Active', 'Disabled', 'SendDisabled'. Defaults to 'Active'."
  type        = string
  default     = "Active"

  validation {
    condition     = contains(["Active", "Disabled", "SendDisabled"], var.status)
    error_message = "status must be 'Active', 'Disabled', or 'SendDisabled'."
  }
}

variable "capture_description" {
  description = <<-EOT
    Optional capture description to archive Event Hub data to Azure Blob Storage. Supports:
    - enabled             (Required) Whether capture is enabled.
    - encoding            (Required) Encoding format: 'Avro' or 'AvroDeflate'.
    - interval_in_seconds (Optional) Capture interval in seconds (60 to 900). Defaults to 300.
    - size_limit_in_bytes (Optional) Capture size limit in bytes (10485760 to 524288000). Defaults to 314572800.
    - skip_empty_archives (Optional) Skip writing empty archive files. Defaults to false.
    - destination         (Required) Destination block:
        - name                (Required) The name of the capture destination (must be 'EventHubArchive.AzureBlockBlob').
        - archive_name_format (Required) Blob naming format (e.g. '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}').
        - blob_container_name (Required) Name of the storage container.
        - storage_account_id  (Required) Resource ID of the storage account.
  EOT
  type = object({
    enabled             = bool
    encoding            = string
    interval_in_seconds = optional(number, 300)
    size_limit_in_bytes = optional(number, 314572800)
    skip_empty_archives = optional(bool, false)
    destination = object({
      name                = string
      archive_name_format = string
      blob_container_name = string
      storage_account_id  = string
    })
  })
  default = null
}

# ─── Consumer Groups ──────────────────────────────────────────────────────────

variable "consumer_groups" {
  description = <<-EOT
    A list of consumer groups to create within the Event Hub. Each object supports:
    - name          (Required) The name of the consumer group. Must be unique within the Event Hub.
    - user_metadata (Optional) Arbitrary user metadata string.

    Note: The default '$Default' consumer group is created automatically by Azure and does not need to be listed here.
  EOT
  type = list(object({
    name          = string
    user_metadata = optional(string)
  }))
  default = []
}
