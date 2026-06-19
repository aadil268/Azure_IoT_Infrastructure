variable "name" {
  description = "The name of the IoT Hub Device Provisioning Service."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the IoT Hub DPS."
  type        = string
}

variable "location" {
  description = "The Azure region where the IoT Hub DPS will be created."
  type        = string
  default     = "North Europe"
}

variable "allocation_policy" {
  description = "The allocation policy of the IoT Hub Device Provisioning Service. Possible values are 'Hashed', 'GeoLatency', or 'Static'. Defaults to 'Hashed'."
  type        = string
  default     = "Hashed"

  validation {
    condition     = contains(["Hashed", "GeoLatency", "Static"], var.allocation_policy)
    error_message = "allocation_policy must be one of 'Hashed', 'GeoLatency', or 'Static'."
  }
}

variable "public_network_access_enabled" {
  description = "Whether requests from the public network are allowed. Defaults to true."
  type        = bool
  default     = true
}

variable "data_residency_enabled" {
  description = "Specifies if the IoT DPS instance has data residency and disaster recovery enabled. Defaults to false. Changing this forces a new resource to be created."
  type        = bool
  default     = false
}

variable "sku_name" {
  description = "The name of the SKU used for the IoT Hub DPS. Currently the only supported value is 'S1'."
  type        = string
  default     = "S1"

  validation {
    condition     = var.sku_name == "S1"
    error_message = "sku_name must be 'S1' as it is the only currently supported SKU."
  }
}

variable "sku_capacity" {
  description = "The number of provisioned IoT Device Provisioning Service units."
  type        = number
  default     = 1

  validation {
    condition     = var.sku_capacity >= 1
    error_message = "sku_capacity must be at least 1."
  }
}

variable "linked_hubs" {
  description = <<-EOT
    A list of IoT Hubs to link to this Device Provisioning Service. Each object supports:
    - connection_string          (Required) The connection string to connect to the IoT Hub.
    - location                   (Required) The Azure region of the IoT Hub.
    - apply_allocation_policy    (Optional) Whether to apply allocation policies to the IoT Hub. Defaults to true.
    - allocation_weight          (Optional) The weight applied to the IoT Hub for allocation. Defaults to 1.
  EOT
  type = list(object({
    connection_string       = string
    location                = string
    apply_allocation_policy = optional(bool, true)
    allocation_weight       = optional(number, 1)
  }))
  default   = []
  sensitive = true
}

variable "ip_filter_rules" {
  description = <<-EOT
    A list of IP filter rules to apply to the IoT Hub DPS. Each object supports:
    - name     (Required) The name of the filter rule.
    - ip_mask  (Required) The IP address range in CIDR notation.
    - action   (Required) The action to take. Possible values are 'Accept' or 'Reject'.
    - target   (Optional) The target for requests captured by this rule. Possible values are 'all', 'deviceApi', or 'serviceApi'. Defaults to 'all'.
  EOT
  type = list(object({
    name    = string
    ip_mask = string
    action  = string
    target  = optional(string, "all")
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.ip_filter_rules : contains(["Accept", "Reject"], rule.action)
    ])
    error_message = "Each ip_filter_rule action must be 'Accept' or 'Reject'."
  }

  validation {
    condition = alltrue([
      for rule in var.ip_filter_rules : contains(["all", "deviceApi", "serviceApi"], rule.target)
    ])
    error_message = "Each ip_filter_rule target must be 'all', 'deviceApi', or 'serviceApi'."
  }
}
