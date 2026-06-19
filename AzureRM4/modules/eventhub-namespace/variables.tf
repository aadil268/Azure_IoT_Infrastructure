variable "resource_group_name" {
  description = "The name of the resource group in which to create the EventHub Namespace."
  type        = string
}

variable "location" {
  description = "The Azure region where the EventHub Namespace will be created."
  type        = string
  default     = "North Europe"
}

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
  description = "The Capacity / Throughput Units for a Standard SKU namespace. Valid values are 1 to 2. Defaults to 1."
  type        = number
  default     = 1

  validation {
    condition     = var.capacity >= 1 && var.capacity <= 2
    error_message = "capacity must be between 1 and 2."
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
    - type          (Required) The type: 'SystemAssigned' or 'UserAssigned'.
    - identity_ids  (Optional) A list of User Assigned Managed Identity IDs. Required when type is 'UserAssigned'.
  EOT
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default = null

  validation {
    condition     = var.identity == null || contains(["SystemAssigned", "UserAssigned"], try(var.identity.type, ""))
    error_message = "identity.type must be 'SystemAssigned' or 'UserAssigned'."
  }
}
