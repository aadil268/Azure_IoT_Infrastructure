output "id" {
  description = "The ID of the Event Hub Consumer Group."
  value       = azurerm_eventhub_consumer_group.this.id
}

output "name" {
  description = "The name of the Event Hub Consumer Group."
  value       = azurerm_eventhub_consumer_group.this.name
}
