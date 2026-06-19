variable "namespace_id" {
  description = "The ID of the EventHub Namespace in which to create the Event Hub."
  type        = string
}

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
  description = "The number of days to retain events. For Basic: 1. For Standard: 1 to 7. Set to null for Premium tier namespaces. Defaults to 1."
  type        = number
  default     = 1

  validation {
    condition     = var.message_retention == null || (var.message_retention >= 1 && var.message_retention <= 7)
    error_message = "message_retention must be between 1 and 7 days, or null for Premium tier."
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
        - name                        (Required) The name of the capture destination (must be 'EventHubArchive.AzureBlockBlob').
        - archive_name_format         (Required) Blob naming format (e.g. '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}').
        - blob_container_name         (Required) Name of the storage container.
        - storage_account_id          (Required) Resource ID of the storage account.
        - storage_authentication_type (Optional) The type of authentication for storage. Possible values are 'SAS' and 'ManagedIdentity'. Defaults to 'SAS'.
        - storage_authentication_id   (Optional) The resource ID of a User Assigned Managed Identity to authenticate with storage. Required when storage_authentication_type is 'ManagedIdentity'.
  EOT
  type = object({
    enabled             = bool
    encoding            = string
    interval_in_seconds = optional(number, 300)
    size_limit_in_bytes = optional(number, 314572800)
    skip_empty_archives = optional(bool, false)
    destination = object({
      name                        = string
      archive_name_format         = string
      blob_container_name         = string
      storage_account_id          = string
      storage_authentication_type = optional(string, "SAS")
      storage_authentication_id   = optional(string)
    })
  })
  default = null
}
