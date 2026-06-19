output "id" {
  description = "The ID of the Event Hub."
  value       = azurerm_eventhub.this.id
}

output "name" {
  description = "The name of the Event Hub."
  value       = azurerm_eventhub.this.name
}

output "partition_ids" {
  description = "The list of partition IDs of the Event Hub."
  value       = azurerm_eventhub.this.partition_ids
}