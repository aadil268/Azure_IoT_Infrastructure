variable "resource_group_name" {
  description = "Name of the existing resource group"
  type        = string
  default     = "rt-test-IoT"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "North Europe"
}

variable "project_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "raspberrypi"
}

variable "iothub_name_override" {
  description = "Optional override for IoT Hub name (useful if default name is taken)"
  type        = string
  default     = null
}

variable "iothub_sku_name" {
  description = "IoT Hub SKU (F1 is free tier, S1 is standard)"
  type        = string
  default     = "S1"
}

variable "iothub_sku_capacity" {
  description = "Number of IoT Hub units"
  type        = number
  default     = 1
}

variable "eventhub_sku" {
  description = "Event Hub Namespace SKU"
  type        = string
  default     = "Standard"
}

variable "eventhub_capacity" {
  description = "Event Hub Namespace capacity (throughput units)"
  type        = number
  default     = 1
}

variable "dps_allocation_policy" {
  description = "Device Provisioning Service allocation policy"
  type        = string
  default     = "Hashed"
}
