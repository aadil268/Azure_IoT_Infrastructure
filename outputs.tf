# IoT Hub Outputs
output "iothub_name" {
  description = "Name of the IoT Hub"
  value       = module.iothub.name
}

output "iothub_hostname" {
  description = "IoT Hub hostname for device connections"
  value       = module.iothub.hostname
}

output "iothub_connection_string" {
  description = "IoT Hub connection string for management (iothubowner policy)"
  value       = module.iothub.iothubowner_connection_string
  sensitive   = true
}

output "iothub_primary_key" {
  description = "IoT Hub primary key"
  value       = module.iothub.shared_access_policy[0].primary_key
  sensitive   = true
}

# Event Hub Outputs
output "eventhub_namespace_name" {
  description = "Event Hub Namespace name"
  value       = module.eventhub.namespace_name
}

output "eventhub_name" {
  description = "Event Hub name for telemetry"
  value       = module.eventhub.eventhub_name
}

output "eventhub_connection_string" {
  description = "Event Hub connection string for reading telemetry"
  value       = module.eventhub.namespace_default_primary_connection_string
  sensitive   = true
}

# DPS Outputs
output "dps_name" {
  description = "Device Provisioning Service name"
  value       = module.iothub_dps.name
}

output "dps_id_scope" {
  description = "DPS ID Scope for device provisioning"
  value       = module.iothub_dps.id_scope
}

output "dps_service_operations_host_name" {
  description = "DPS service operations host name"
  value       = module.iothub_dps.service_operations_host_name
}

output "dps_device_provisioning_host_name" {
  description = "DPS device provisioning host name"
  value       = module.iothub_dps.device_provisioning_host_name
}

# Built-in Event Hub endpoints (for reading device messages directly from IoT Hub)
output "iothub_event_hub_endpoint" {
  description = "Built-in Event Hub-compatible endpoint"
  value       = module.iothub.event_hub_events_endpoint
  sensitive   = true
}

output "iothub_event_hub_path" {
  description = "Built-in Event Hub-compatible path"
  value       = module.iothub.event_hub_events_path
}

# Quick Start Instructions
output "raspberry_pi_simulator_instructions" {
  description = "Instructions for using Raspberry Pi simulator"
  value       = <<-EOT
  
  ========================================
  Raspberry Pi Azure IoT Simulator Setup
  ========================================
  
  1. Open the Raspberry Pi Web Simulator:
     https://azure-samples.github.io/raspberry-pi-web-simulator/
  
  2. Create a device in your IoT Hub:
     az iot hub device-identity create --hub-name ${module.iothub.name} --device-id raspberrypi-simulator
  
  3. Get the device connection string:
     az iot hub device-identity connection-string show --hub-name ${module.iothub.name} --device-id raspberrypi-simulator
  
  4. In the simulator, replace the connection string on line 15 with your device connection string
  
  5. Click "Run" to start sending telemetry data
  
  6. Monitor incoming messages:
     az iot hub monitor-events --hub-name ${module.iothub.name} --device-id raspberrypi-simulator
  
  Or use Event Hub to read telemetry:
     - Event Hub Namespace: ${module.eventhub.namespace_name}
     - Event Hub Name: ${module.eventhub.eventhub_name}
  
  ========================================
  EOT
}
