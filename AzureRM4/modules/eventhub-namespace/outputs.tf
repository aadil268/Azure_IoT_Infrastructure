output "id" {
  description = "The ID of the EventHub Namespace."
  value       = azurerm_eventhub_namespace.this.id
}

output "name" {
  description = "The name of the EventHub Namespace."
  value       = azurerm_eventhub_namespace.this.name
}

output "default_primary_connection_string" {
  description = "The primary connection string for the EventHub Namespace authorization rule RootManageSharedAccessKey."
  value       = azurerm_eventhub_namespace.this.default_primary_connection_string
  sensitive   = true
}

output "default_secondary_connection_string" {
  description = "The secondary connection string for the EventHub Namespace authorization rule RootManageSharedAccessKey."
  value       = azurerm_eventhub_namespace.this.default_secondary_connection_string
  sensitive   = true
}

output "default_primary_key" {
  description = "The primary access key for the EventHub Namespace."
  value       = azurerm_eventhub_namespace.this.default_primary_key
  sensitive   = true
}

output "default_secondary_key" {
  description = "The secondary access key for the EventHub Namespace."
  value       = azurerm_eventhub_namespace.this.default_secondary_key
  sensitive   = true
}

output "identity" {
  description = "The managed identity block of the EventHub Namespace."
  value       = azurerm_eventhub_namespace.this.identity
}
