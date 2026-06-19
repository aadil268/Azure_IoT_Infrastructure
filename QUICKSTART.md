# Quick Start Guide - Raspberry Pi IoT Testing

This guide will help you deploy and test the Azure IoT infrastructure with the Raspberry Pi web simulator in under 10 minutes.

## Prerequisites Check

```bash
# Check Azure CLI
az --version

# Check Terraform
terraform --version

# Check you're logged in to Azure
az account show

# Verify the resource group exists
az group show --name rt-test-IoT
```

## Step 1: Deploy Infrastructure (5 minutes)

```bash
# Navigate to project directory
cd /Users/aadil/Projects/IoT_Testing

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy (type 'yes' when prompted)
terraform apply

# Save outputs for later use
terraform output -json > terraform-outputs.json
```

## Step 2: Create a Test Device (1 minute)

```bash
# Get IoT Hub name from outputs
IOTHUB_NAME=$(terraform output -raw iothub_name)

# Create a device identity
az iot hub device-identity create \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator \
  --output table

# Get device connection string
DEVICE_CONN_STRING=$(az iot hub device-identity connection-string show \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator \
  --output tsv)

# Display connection string (save this!)
echo "Device Connection String:"
echo $DEVICE_CONN_STRING
```

## Step 3: Open Raspberry Pi Simulator (1 minute)

1. **Open the simulator**: https://azure-samples.github.io/raspberry-pi-web-simulator/

2. **Find line 15** in the code editor (should look like):
   ```javascript
   const connectionString = '[Your IoT hub device connection string]';
   ```

3. **Replace** with your device connection string:
   ```javascript
   const connectionString = 'HostName=raspberrypi-iothub.azure-devices.net;DeviceId=raspberrypi-simulator;SharedAccessKey=YOUR_KEY_HERE';
   ```

4. **Click "Run"** button or type `npm start` in console

5. **Watch the magic happen**:
   - LED starts blinking (left panel)
   - Console shows temperature/humidity readings
   - Messages being sent to IoT Hub

## Step 4: Monitor Messages (2 minutes)

### Option A: Monitor from CLI (Recommended)

```bash
# Monitor all messages in real-time
az iot hub monitor-events \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator

# Monitor with more details
az iot hub monitor-events \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator \
  --properties all \
  --output json
```

### Option B: Monitor from Azure Portal

1. Go to Azure Portal
2. Navigate to your IoT Hub: `raspberrypi-iothub`
3. Click **Metrics** (left menu)
4. Add metric: **Device to cloud messages**
5. Watch the graph update in real-time

### Option C: Monitor from Event Hub

```bash
# Get Event Hub details
EH_NAMESPACE=$(terraform output -raw eventhub_namespace_name)
EH_NAME=$(terraform output -raw eventhub_name)

# List consumer groups
az eventhubs eventhub consumer-group list \
  --namespace-name $EH_NAMESPACE \
  --eventhub-name $EH_NAME \
  --resource-group rt-test-IoT \
  --output table
```

## Step 5: Test Cloud-to-Device Messaging (1 minute)

```bash
# Send a message TO the device
az iot device c2d-message send \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator \
  --data "Hello from Azure!"

# Check the simulator console - you should see the message appear!
```

## Common Test Scenarios

### Test 1: Basic Telemetry

The default simulator sends:
```json
{
  "messageId": 1,
  "deviceId": "raspberrypi-simulator",
  "temperature": 22.5,
  "humidity": 65.0
}
```

**Verification**:
```bash
az iot hub monitor-events --hub-name $IOTHUB_NAME --device-id raspberrypi-simulator
```

### Test 2: Direct Method Invocation

```bash
# Invoke a method on the device (example method - may need to update simulator code)
az iot hub invoke-device-method \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator \
  --method-name "start" \
  --method-payload '{"duration": 5000}'
```

### Test 3: Device Twin Update

```bash
# Update desired properties
az iot hub device-twin update \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator \
  --set properties.desired='{"telemetryInterval": 5000}'

# View device twin
az iot hub device-twin show \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator
```

### Test 4: Check Message Routing

```bash
# Verify messages are being routed to Event Hub
az monitor metrics list \
  --resource $(terraform output -raw eventhub_namespace_name | xargs -I {} az eventhubs namespace show -n {} -g rt-test-IoT --query id -o tsv) \
  --metric IncomingMessages \
  --start-time $(date -u -v-10M +"%Y-%m-%dT%H:%M:%SZ") \
  --interval PT1M \
  --output table
```

## Troubleshooting

### Problem: "Can't connect to IoT Hub"

```bash
# Check IoT Hub is accessible
az iot hub show --name $IOTHUB_NAME --query properties.state

# Verify device exists
az iot hub device-identity show \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator
```

### Problem: "Connection string is invalid"

```bash
# Regenerate connection string
az iot hub device-identity connection-string show \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator
```

### Problem: "No messages appearing"

```bash
# Check device is sending messages (look at metrics)
az iot hub show-stats --name $IOTHUB_NAME

# Check if device is connected
az iot hub device-identity show \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator \
  --query connectionState
```

### Problem: "Event Hub not receiving messages"

```bash
# Verify routing is configured
az iot hub route list --hub-name $IOTHUB_NAME --output table

# Check endpoint health
az iot hub routing-endpoint list --hub-name $IOTHUB_NAME --output table
```

## Useful Commands

### View all outputs
```bash
terraform output
```

### Get IoT Hub connection string (for apps, not devices)
```bash
terraform output -raw iothub_connection_string
```

### Get Event Hub connection string
```bash
terraform output -raw eventhub_connection_string
```

### List all devices
```bash
az iot hub device-identity list --hub-name $IOTHUB_NAME --output table
```

### Delete a device
```bash
az iot hub device-identity delete \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator
```

### View device messages count
```bash
az iot hub show-stats --name $IOTHUB_NAME
```

## Clean Up

When you're done testing:

```bash
# Destroy all resources
terraform destroy

# Or just delete the test device
az iot hub device-identity delete \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator
```

## Next Steps

1. **Customize the simulator code**: Modify temperature/humidity ranges
2. **Add more devices**: Create multiple device identities
3. **Process Event Hub data**: Build a consumer application
4. **Use DPS**: Implement device provisioning workflow
5. **Add device twins**: Store device metadata and configuration

## Cost Monitoring

```bash
# Check current month costs for resource group
az consumption usage list \
  --start-date $(date -u -v-1m +"%Y-%m-%d") \
  --end-date $(date -u +"%Y-%m-%d") \
  --query "[?contains(instanceId, 'rt-test-IoT')]" \
  --output table
```

## Support Resources

- **Simulator**: https://azure-samples.github.io/raspberry-pi-web-simulator/
- **IoT Hub Docs**: https://learn.microsoft.com/en-us/azure/iot-hub/
- **Tutorial**: https://learn.microsoft.com/en-us/azure/iot-hub/raspberry-pi-get-started
- **Pricing**: https://azure.microsoft.com/en-us/pricing/details/iot-hub/

## Architecture Overview

```
Raspberry Pi Simulator (Browser)
         |
         | MQTT/AMQP
         v
   Azure IoT Hub (raspberrypi-iothub)
         |
         | Message Routing
         v
   Azure Event Hub (raspberrypi-telemetry)
         |
         v
   Consumer Applications
   
   
   Device Provisioning Service (raspberrypi-dps)
         |
         | Linked to IoT Hub
         v
   Automatic Device Registration
```

## Success Criteria

After following this guide, you should have:

- ✅ IoT Hub deployed and operational
- ✅ Event Hub receiving telemetry
- ✅ DPS linked to IoT Hub
- ✅ Simulator connected and sending data
- ✅ Ability to monitor messages
- ✅ Cloud-to-device messaging working

**Happy IoT Testing!** 🎉
