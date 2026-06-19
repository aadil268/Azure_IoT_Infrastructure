# Resource Group Configuration
resource_group_name = "rt-test-IoT"
location            = "North Europe"

# Project Configuration
# Use a unique prefix to avoid naming conflicts (IoT Hub names must be globally unique)
# Examples: "aadil-pi-2026", "abb-iot-test", "mycompany-iot-dev", etc.
# Revert to original prefix since Event Hub is already deployed
project_prefix = "raspberrypi"

# Override IoT Hub name since "raspberrypi-iothub" is taken globally
iothub_name_override = "raspberrypi-iot-de5e1c"

# IoT Hub Configuration
# Use F1 for free tier (1 free hub per subscription, limited messages)
# Use S1 for standard tier (400k messages/day per unit)
iothub_sku_name     = "S1"
iothub_sku_capacity = 1

# Event Hub Configuration
eventhub_sku      = "Standard"
eventhub_capacity = 1

# Device Provisioning Service Configuration
# Hashed: Evenly distributes devices
# GeoLatency: Routes based on lowest latency
# Static: Uses explicit assignment
dps_allocation_policy = "Hashed"
