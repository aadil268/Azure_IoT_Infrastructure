output "id" {
  description = "The ID of the IoT Hub."
  value       = azurerm_iothub.this.id
}

output "name" {
  description = "The name of the IoT Hub."
  value       = azurerm_iothub.this.name
}

output "hostname" {
  description = "The hostname of the IoT Hub."
  value       = azurerm_iothub.this.hostname
}

output "event_hub_events_endpoint" {
  description = "The EventHub-compatible endpoint for reading device telemetry messages."
  value       = azurerm_iothub.this.event_hub_events_endpoint
}

output "event_hub_events_path" {
  description = "The EventHub-compatible path for reading device telemetry messages."
  value       = azurerm_iothub.this.event_hub_events_path
}

output "event_hub_operations_endpoint" {
  description = "The EventHub-compatible endpoint for reading device operations (lifecycle, twin changes)."
  value       = azurerm_iothub.this.event_hub_operations_endpoint
}

output "event_hub_operations_path" {
  description = "The EventHub-compatible path for reading device operations."
  value       = azurerm_iothub.this.event_hub_operations_path
}

output "identity" {
  description = "The managed identity block of the IoT Hub, containing principal_id and tenant_id for SystemAssigned identity."
  value       = azurerm_iothub.this.identity
}

output "shared_access_policy" {
  description = "The list of shared access policies including primary and secondary connection strings and keys."
  value       = azurerm_iothub.this.shared_access_policy
  sensitive   = true
}

output "iothubowner_connection_string" {
  description = "Connection string for the iothubowner policy (full access)"
  value = format(
    "HostName=%s;SharedAccessKeyName=%s;SharedAccessKey=%s",
    azurerm_iothub.this.hostname,
    try(azurerm_iothub.this.shared_access_policy[0].key_name, "iothubowner"),
    try(azurerm_iothub.this.shared_access_policy[0].primary_key, "")
  )
  sensitive = true
}

output "service_connection_string" {
  description = "Connection string for the service policy"
  value = format(
    "HostName=%s;SharedAccessKeyName=%s;SharedAccessKey=%s",
    azurerm_iothub.this.hostname,
    try([for p in azurerm_iothub.this.shared_access_policy : p if p.key_name == "service"][0].key_name, "service"),
    try([for p in azurerm_iothub.this.shared_access_policy : p if p.key_name == "service"][0].primary_key, "")
  )
  sensitive = true
}
