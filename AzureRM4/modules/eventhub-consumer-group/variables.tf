variable "resource_group_name" {
  description = "The name of the resource group in which the Event Hub Consumer Group will be created."
  type        = string
}

variable "namespace_name" {
  description = "The name of the EventHub Namespace."
  type        = string
}

variable "eventhub_name" {
  description = "The name of the Event Hub."
  type        = string
}

variable "consumer_group_name" {
  description = "The name of the Event Hub Consumer Group. Must be unique within the Event Hub."
  type        = string
}

variable "user_metadata" {
  description = "Specifies the user metadata associated with the consumer group."
  type        = string
  default     = null
}
