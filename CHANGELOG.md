# Changelog

## [1.0.1] - 2026-06-18

### Fixed
- **Connection String Access**: Fixed issue where `shared_access_policy[0].connection_string` attribute didn't exist
  - Added helper outputs in IoT Hub module to construct connection strings properly
  - Added `iothubowner_connection_string` output (full access policy)
  - Added `service_connection_string` output (service policy)
  - Updated `main.tf` to use new `iothubowner_connection_string` output for DPS linking
  - Updated `outputs.tf` to use new connection string output

### Technical Details
The `azurerm_iothub` resource's `shared_access_policy` attribute returns a list of objects with:
- `key_name`
- `primary_key`
- `secondary_key`
- `permissions`

But **not** `connection_string` directly. Connection strings must be constructed using the format:
```
HostName={hostname};SharedAccessKeyName={key_name};SharedAccessKey={primary_key}
```

### Files Changed
- `AzureRM4/modules/iothub/outputs.tf` - Added connection string helper outputs
- `main.tf` - Updated DPS linked_hubs to use new connection string output
- `outputs.tf` - Updated iothub_connection_string to use new output

### Validation Status
✅ `terraform validate` - Success
✅ `terraform plan` - Success (shows ~12 resources to create)

---

## [1.0.0] - 2026-06-18

### Added
- Initial project setup with Terraform configuration for Azure IoT testing
- IoT Hub module integration (`raspberrypi-iothub`)
- Event Hub module integration (`raspberrypi-ehns`, `raspberrypi-telemetry`)
- IoT Hub DPS module integration (`raspberrypi-dps`)
- Message routing from IoT Hub to Event Hub
- Cloud-to-device messaging configuration
- Consumer groups for telemetry processing

### Documentation
- `README.md` - Architecture overview and features
- `QUICKSTART.md` - 10-minute quick start guide
- `DEPLOYMENT.md` - Detailed deployment and troubleshooting
- `PROJECT_STRUCTURE.md` - File organization and customization
- `INDEX.md` - Navigation hub and quick reference

### Automation
- `setup.sh` - Automated deployment script with prerequisites checking

### Configuration
- `main.tf` - Infrastructure configuration using modules
- `providers.tf` - Terraform and Azure provider setup
- `variables.tf` - Input variable definitions
- `outputs.tf` - Output value definitions
- `terraform.tfvars` - Customizable values
- `.gitignore` - Git ignore patterns

### Features
- Raspberry Pi Web Simulator integration support
- Pre-configured message routing to Event Hub
- Two consumer groups (telemetry-processor, archive-processor)
- DPS linked to IoT Hub for device provisioning
- Secure connection string handling
- Comprehensive documentation
- Automated setup script

### Target Resources
- Resource Group: `rt-test-IoT` (pre-existing)
- Region: West Europe (configurable)
- IoT Hub SKU: S1 (configurable to F1 for free tier)
- Event Hub SKU: Standard (configurable)
