# IoT Hub Testing with Raspberry Pi Web Simulator

This Terraform project sets up an Azure IoT testing environment with IoT Hub, Device Provisioning Service (DPS), and Event Hub for use with the Raspberry Pi Azure IoT Web Simulator.

## Architecture

```
┌─────────────────────────────────┐
│  Raspberry Pi Web Simulator     │
│  (Browser-based)                │
│  - Simulated BME280 sensor      │
│  - LED indicator                │
└────────────┬────────────────────┘
             │ Device Messages
             ▼
┌─────────────────────────────────┐
│  Azure IoT Hub                  │
│  - Device authentication        │
│  - Message routing              │
│  - Cloud-to-device messaging    │
└────────────┬────────────────────┘
             │ Telemetry Route
             ▼
┌─────────────────────────────────┐
│  Azure Event Hub                │
│  - Telemetry processing         │
│  - Consumer groups              │
│  - Message retention            │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  IoT Hub DPS                    │
│  - Device provisioning          │
│  - Linked to IoT Hub            │
└─────────────────────────────────┘
```

## Resources Created

### IoT Hub (`raspberrypi-iothub`)
- **Purpose**: Central hub for device connectivity and message routing
- **SKU**: S1 (Standard) - 400,000 messages per day
- **Features**:
  - Local authentication enabled for simulator
  - Public network access for testing
  - TLS 1.2 minimum
  - Cloud-to-device messaging configured
  - Message routing to Event Hub

### Event Hub (`raspberrypi-ehns` / `raspberrypi-telemetry`)
- **Purpose**: Stream telemetry data from IoT Hub
- **SKU**: Standard
- **Configuration**:
  - 4 partitions for parallel processing
  - 1 day message retention
  - Consumer groups:
    - `telemetry-processor`: Real-time processing
    - `archive-processor`: Long-term storage

### IoT Hub DPS (`raspberrypi-dps`)
- **Purpose**: Automated device provisioning
- **Allocation Policy**: Hashed (even distribution)
- **Configuration**:
  - Linked to IoT Hub
  - S1 SKU
  - Ready for zero-touch provisioning

## Prerequisites

1. **Azure CLI** installed and authenticated
   ```bash
   az login
   ```

2. **Terraform** installed (>= 1.0)
   ```bash
   terraform version
   ```

3. **Existing Resource Group**: `rt-test-IoT`
   ```bash
   az group show --name rt-test-IoT
   ```

## Quick Links

### 🎯 For Presentations & Meetings
- 📊 **[DEMO.md](DEMO.md)** - Complete 30-minute meeting pitch with live demo script
- 📄 **[EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md)** - One-page overview for decision makers
- 📋 **[DEMO_QUICK_REFERENCE.md](DEMO_QUICK_REFERENCE.md)** - Quick reference card for presenters
- 🎤 **[PRESENTATION_SLIDES_OUTLINE.md](PRESENTATION_SLIDES_OUTLINE.md)** - Slide deck outline

### 🚀 For Implementation
- ⚡ **[QUICKSTART.md](QUICKSTART.md)** - Get started in 10 minutes
- 🔧 **[DEPLOYMENT.md](DEPLOYMENT.md)** - Detailed deployment guide
- 📦 **[AzureRM4/modules/README.md](AzureRM4/modules/README.md)** - Module usage & examples
- 📋 **[INDEX.md](INDEX.md)** - Complete navigation hub

## Deployment Steps

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review the Plan

```bash
terraform plan
```

### 3. Apply Configuration

```bash
terraform apply
```

Review the changes and type `yes` to confirm.

### 4. View Outputs

```bash
terraform output
```

To see sensitive values:
```bash
terraform output -json | jq
```

## Using the Raspberry Pi Web Simulator

### Step 1: Create a Device Identity

After deployment, create a device in your IoT Hub:

```bash
# Create device
az iot hub device-identity create \
  --hub-name raspberrypi-iothub \
  --device-id raspberrypi-simulator

# Get device connection string
az iot hub device-identity connection-string show \
  --hub-name raspberrypi-iothub \
  --device-id raspberrypi-simulator
```

Save the connection string - you'll need it for the simulator.

### Step 2: Open the Simulator

Visit the Raspberry Pi Web Simulator:
- **Production**: https://azure-samples.github.io/raspberry-pi-web-simulator/
- **Documentation**: https://learn.microsoft.com/en-us/azure/iot-hub/raspberry-pi-get-started

### Step 3: Configure the Simulator

1. In the simulator's code editor, find line 15
2. Replace the placeholder connection string with your device connection string:

```javascript
const connectionString = 'HostName=raspberrypi-iothub.azure-devices.net;DeviceId=raspberrypi-simulator;SharedAccessKey=YOUR_KEY_HERE';
```

### Step 4: Run the Simulator

1. Click the **Run** button (or type `npm start` in the console)
2. Watch the LED blink and console output
3. The simulator sends temperature and humidity data every 2 seconds

### Step 5: Monitor Messages

**Option 1: Monitor directly from IoT Hub**
```bash
az iot hub monitor-events \
  --hub-name raspberrypi-iothub \
  --device-id raspberrypi-simulator
```

**Option 2: Read from Event Hub**
```bash
# Using Azure CLI (requires Event Hubs extension)
az eventhubs eventhub consumer-group create \
  --namespace-name raspberrypi-ehns \
  --eventhub-name raspberrypi-telemetry \
  --name my-consumer \
  --resource-group rt-test-IoT
```

**Option 3: Use Azure Portal**
- Navigate to IoT Hub → Overview → Usage
- Check "Device to cloud messages" metric

## Testing Scenarios

### 1. Basic Telemetry

The default simulator code sends temperature and humidity:
```javascript
{
  "messageId": 1,
  "deviceId": "raspberrypi-simulator",
  "temperature": 22.5,
  "humidity": 65.0
}
```

### 2. Cloud-to-Device Messages

Send a message to the device:
```bash
az iot device c2d-message send \
  --hub-name raspberrypi-iothub \
  --device-id raspberrypi-simulator \
  --data "Blink LED"
```

Watch the simulator console for incoming messages.

### 3. Device Twin Updates

Update device twin properties:
```bash
# Update desired properties
az iot hub device-twin update \
  --hub-name raspberrypi-iothub \
  --device-id raspberrypi-simulator \
  --set properties.desired.telemetryInterval=5000

# View device twin
az iot hub device-twin show \
  --hub-name raspberrypi-iothub \
  --device-id raspberrypi-simulator
```

### 4. Direct Methods

Invoke a direct method:
```bash
az iot hub invoke-device-method \
  --hub-name raspberrypi-iothub \
  --device-id raspberrypi-simulator \
  --method-name "setTelemetryInterval" \
  --method-payload '{"interval": 10000}'
```

## Module Structure

```
.
├── main.tf                          # Main configuration
├── variables.tf                     # Input variables
├── outputs.tf                       # Output values
├── providers.tf                     # Provider configuration
├── terraform.tfvars                 # Variable values
├── README.md                        # This file
└── AzureRM4/
    └── modules/
        ├── iothub/                  # IoT Hub module
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── backend.tf
        ├── iothub-dps/              # DPS module
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── backend.tf
        └── eventhub/                # Event Hub module
            ├── main.tf
            ├── variables.tf
            ├── outputs.tf
            └── backend.tf
```

## Cost Estimation

| Service | SKU | Estimated Monthly Cost |
|---------|-----|------------------------|
| IoT Hub | S1 (1 unit) | ~$25/month |
| Event Hub | Standard (1 TU) | ~$22/month |
| DPS | S1 (1 unit) | ~$0.10/1000 operations |
| **Total** | | **~$50/month** |

> **Note**: Use IoT Hub F1 (Free tier) for testing. Change `iothub_sku_name = "F1"` in `terraform.tfvars`.

## Troubleshooting

### Issue: "Resource group not found"
**Solution**: Ensure the resource group exists:
```bash
az group show --name rt-test-IoT
```

### Issue: "Connection string invalid"
**Solution**: Ensure you're using the **device** connection string, not the IoT Hub connection string.

### Issue: "Cannot connect to IoT Hub"
**Solution**: Check firewall settings and ensure public network access is enabled.

### Issue: "Messages not appearing in Event Hub"
**Solution**: 
1. Verify routing is configured correctly
2. Check Event Hub connection string in IoT Hub endpoints
3. Ensure Event Hub is not paused

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` to confirm deletion.

## References

- [Raspberry Pi Web Simulator](https://azure-samples.github.io/raspberry-pi-web-simulator/)
- [Azure IoT Hub Documentation](https://learn.microsoft.com/en-us/azure/iot-hub/)
- [Raspberry Pi IoT Hub Tutorial](https://learn.microsoft.com/en-us/azure/iot-hub/raspberry-pi-get-started)
- [IoT Hub Device Provisioning Service](https://learn.microsoft.com/en-us/azure/iot-dps/)
- [Azure Event Hubs](https://learn.microsoft.com/en-us/azure/event-hubs/)

## Documentation

- 📊 **[DEMO.md](DEMO.md)** - Complete meeting pitch with demos, module usage, and value propositions
- 🚀 **[QUICKSTART.md](QUICKSTART.md)** - Get started in 10 minutes
- 🔧 **[DEPLOYMENT.md](DEPLOYMENT.md)** - Detailed deployment guide
- 📁 **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Project organization
- 📋 **[INDEX.md](INDEX.md)** - Navigation hub

## Support

For issues with:
- **Terraform modules**: Check module documentation in `AzureRM4/modules/`
- **Azure IoT Hub**: Visit [Azure IoT Hub Q&A](https://learn.microsoft.com/en-us/answers/tags/158/azure-iot-hub/)
- **Raspberry Pi Simulator**: GitHub repository is archived but source available at [raspberry-pi-web-simulator](https://github.com/Azure-Samples/raspberry-pi-web-simulator)
