output "id" {
  description = "The ID of the IoT Hub Device Provisioning Service."
  value       = azurerm_iothub_dps.this.id
}

output "name" {
  description = "The name of the IoT Hub Device Provisioning Service."
  value       = azurerm_iothub_dps.this.name
}

output "service_operations_host_name" {
  description = "The service operations host name of the IoT Hub Device Provisioning Service."
  value       = azurerm_iothub_dps.this.service_operations_host_name
}

output "device_provisioning_host_name" {
  description = "The device provisioning host name of the IoT Hub Device Provisioning Service."
  value       = azurerm_iothub_dps.this.device_provisioning_host_name
}

output "id_scope" {
  description = "The unique identifier of the IoT Hub Device Provisioning Service, used by devices during registration."
  value       = azurerm_iothub_dps.this.id_scope
}

output "allocation_policy" {
  description = "The allocation policy of the IoT Hub Device Provisioning Service."
  value       = azurerm_iothub_dps.this.allocation_policy
}

output "linked_hub_hostnames" {
  description = "List of hostnames for the linked IoT Hubs."
  value       = [for hub in azurerm_iothub_dps.this.linked_hub : hub.hostname]
}