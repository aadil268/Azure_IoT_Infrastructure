# ─── Namespace Outputs ───────────────────────────────────────────────────────

output "namespace_id" {
  description = "The ID of the EventHub Namespace."
  value       = azurerm_eventhub_namespace.this.id
}

output "namespace_name" {
  description = "The name of the EventHub Namespace."
  value       = azurerm_eventhub_namespace.this.name
}

output "namespace_default_primary_connection_string" {
  description = "The primary connection string for the EventHub Namespace authorization rule RootManageSharedAccessKey."
  value       = azurerm_eventhub_namespace.this.default_primary_connection_string
  sensitive   = true
}

output "namespace_default_secondary_connection_string" {
  description = "The secondary connection string for the EventHub Namespace authorization rule RootManageSharedAccessKey."
  value       = azurerm_eventhub_namespace.this.default_secondary_connection_string
  sensitive   = true
}

output "namespace_default_primary_key" {
  description = "The primary access key for the EventHub Namespace."
  value       = azurerm_eventhub_namespace.this.default_primary_key
  sensitive   = true
}

output "namespace_identity" {
  description = "The managed identity block of the EventHub Namespace."
  value       = azurerm_eventhub_namespace.this.identity
}

# ─── Event Hub Outputs ────────────────────────────────────────────────────────

output "eventhub_id" {
  description = "The ID of the Event Hub."
  value       = azurerm_eventhub.this.id
}

output "eventhub_name" {
  description = "The name of the Event Hub."
  value       = azurerm_eventhub.this.name
}

output "eventhub_partition_ids" {
  description = "The list of partition IDs of the Event Hub."
  value       = azurerm_eventhub.this.partition_ids
}

# ─── Consumer Group Outputs ───────────────────────────────────────────────────

output "consumer_group_ids" {
  description = "A map of consumer group names to their resource IDs."
  value       = { for k, cg in azurerm_eventhub_consumer_group.this : k => cg.id }
}

# ─── Authorization Rule Outputs ───────────────────────────────────────────────

output "iothub_sender_primary_connection_string" {
  description = "Primary connection string for the iothub-sender authorization rule (for IoT Hub routing)"
  value       = azurerm_eventhub_authorization_rule.iothub_sender.primary_connection_string
  sensitive   = true
}

output "iothub_sender_secondary_connection_string" {
  description = "Secondary connection string for the iothub-sender authorization rule"
  value       = azurerm_eventhub_authorization_rule.iothub_sender.secondary_connection_string
  sensitive   = true
}
