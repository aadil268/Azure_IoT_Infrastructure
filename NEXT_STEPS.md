# 🎉 Deployment Successful!

Your Azure IoT testing infrastructure is now fully deployed and ready to use with the Raspberry Pi Web Simulator.

## ✅ Deployed Resources

| Resource | Name | Status |
|----------|------|--------|
| **IoT Hub** | `raspberrypi-iot-de5e1c` | ✅ Active |
| **Event Hub Namespace** | `raspberrypi-ehns` | ✅ Active |
| **Event Hub** | `raspberrypi-telemetry` | ✅ Active |
| **Event Hub Auth Rule** | `iothub-sender` | ✅ Active |
| **Consumer Group** | `telemetry-processor` | ✅ Active |
| **Consumer Group** | `archive-processor` | ✅ Active |
| **DPS** | `raspberrypi-dps` | ✅ Active |

**Total Deployment Time**: ~4-5 minutes

---

## 🚀 Quick Start - Test with Raspberry Pi Simulator

### Step 1: Create Device Identity

```bash
az iot hub device-identity create \
  --hub-name raspberrypi-iot-de5e1c \
  --device-id raspberrypi-simulator

# You should see output confirming device creation
```

### Step 2: Get Device Connection String

```bash
az iot hub device-identity connection-string show \
  --hub-name raspberrypi-iot-de5e1c \
  --device-id raspberrypi-simulator
```

**Copy the connection string** - you'll need it for the simulator!

Example format:
```
HostName=raspberrypi-iot-de5e1c.azure-devices.net;DeviceId=raspberrypi-simulator;SharedAccessKey=...
```

### Step 3: Configure Raspberry Pi Web Simulator

1. **Open the simulator**:
   ```
   https://azure-samples.github.io/raspberry-pi-web-simulator/
   ```

2. **Find line 15** in the code editor (looks like this):
   ```javascript
   const connectionString = '[Your IoT hub device connection string]';
   ```

3. **Replace** with your actual device connection string:
   ```javascript
   const connectionString = 'HostName=raspberrypi-iot-de5e1c.azure-devices.net;DeviceId=raspberrypi-simulator;SharedAccessKey=YOUR_KEY_HERE';
   ```

4. **Click "Run"** button (or type `npm start` in the console)

5. **Watch the magic!**
   - LED blinks in the visual display (left panel)
   - Console shows temperature and humidity readings
   - Messages sent every 2 seconds to IoT Hub

### Step 4: Monitor Messages

**Option A: Monitor from Azure CLI** (Recommended)

```bash
az iot hub monitor-events \
  --hub-name raspberrypi-iot-de5e1c \
  --device-id raspberrypi-simulator
```

You should see output like:
```json
{
    "event": {
        "origin": "raspberrypi-simulator",
        "module": "",
        "interface": "",
        "component": "",
        "payload": {
            "messageId": 1,
            "deviceId": "raspberrypi-simulator",
            "temperature": 22.5,
            "humidity": 65.0
        }
    }
}
```

**Option B: Azure Portal**

1. Go to Azure Portal: https://portal.azure.com
2. Navigate to your IoT Hub: `raspberrypi-iot-de5e1c`
3. Click **Metrics** (left menu)
4. Add metric: "Device to cloud messages"
5. Watch the graph update in real-time

**Option C: Event Hub Stream**

Your messages are also being routed to Event Hub for processing:
- **Namespace**: `raspberrypi-ehns`
- **Event Hub**: `raspberrypi-telemetry`
- **Consumer Groups**: `telemetry-processor`, `archive-processor`

---

## 🧪 Testing Scenarios

### Test 1: Send Cloud-to-Device Message

```bash
az iot device c2d-message send \
  --hub-name raspberrypi-iot-de5e1c \
  --device-id raspberrypi-simulator \
  --data "Blink LED faster!"
```

Check the simulator console - you should see the message received!

### Test 2: Update Device Twin

```bash
# Update desired properties
az iot hub device-twin update \
  --hub-name raspberrypi-iot-de5e1c \
  --device-id raspberrypi-simulator \
  --set properties.desired.telemetryInterval=5000

# View device twin
az iot hub device-twin show \
  --hub-name raspberrypi-iot-de5e1c \
  --device-id raspberrypi-simulator
```

### Test 3: Invoke Direct Method

```bash
az iot hub invoke-device-method \
  --hub-name raspberrypi-iot-de5e1c \
  --device-id raspberrypi-simulator \
  --method-name "start" \
  --method-payload '{"duration": 10000}'
```

### Test 4: Check IoT Hub Statistics

```bash
az iot hub show-stats \
  --name raspberrypi-iot-de5e1c
```

---

## 📊 Resource Details

### IoT Hub

- **Name**: `raspberrypi-iot-de5e1c`
- **Hostname**: `raspberrypi-iot-de5e1c.azure-devices.net`
- **SKU**: S1 (400,000 messages/day)
- **Location**: North Europe
- **Features**:
  - Local authentication: ✅ Enabled
  - Public network access: ✅ Enabled
  - TLS 1.2 minimum: ✅ Enforced
  - Message routing to Event Hub: ✅ Configured

### Event Hub

- **Namespace**: `raspberrypi-ehns`
- **Event Hub**: `raspberrypi-telemetry`
- **SKU**: Standard
- **Partitions**: 4
- **Retention**: 1 day
- **Consumer Groups**:
  - `telemetry-processor` - For real-time processing
  - `archive-processor` - For long-term storage
- **Authorization Rule**: `iothub-sender` (Send + Listen)

### Device Provisioning Service

- **Name**: `raspberrypi-dps`
- **ID Scope**: `0ne0121A542`
- **Endpoint**: `global.azure-devices-provisioning.net`
- **Service Endpoint**: `raspberrypi-dps.azure-devices-provisioning.net`
- **Allocation Policy**: Hashed
- **Linked to**: `raspberrypi-iot-de5e1c`

---

## 🔧 Useful Commands

### View All Terraform Outputs

```bash
cd /Users/aadil/Projects/IoT_Testing
terraform output
```

### Get Sensitive Values

```bash
# IoT Hub connection string
terraform output -raw iothub_connection_string

# Event Hub connection string
terraform output -raw eventhub_connection_string

# IoT Hub primary key
terraform output -raw iothub_primary_key
```

### List All Devices

```bash
az iot hub device-identity list \
  --hub-name raspberrypi-iot-de5e1c \
  --output table
```

### Delete a Device

```bash
az iot hub device-identity delete \
  --hub-name raspberrypi-iot-de5e1c \
  --device-id raspberrypi-simulator
```

### Check Resource Health

```bash
# IoT Hub
az iot hub show \
  --name raspberrypi-iot-de5e1c \
  --query "{Name:name, State:properties.state, Hostname:properties.hostName}"

# Event Hub
az eventhubs eventhub show \
  --namespace-name raspberrypi-ehns \
  --name raspberrypi-telemetry \
  --resource-group rt-test-IoT

# DPS
az iot dps show \
  --name raspberrypi-dps \
  --resource-group rt-test-IoT
```

---

## 💡 Tips & Best Practices

### For Testing

1. **Start Simple**: Use the basic simulator code first before customizing
2. **Monitor Actively**: Keep the monitor-events command running while testing
3. **Check Metrics**: Use Azure Portal metrics to visualize message flow
4. **Test Incrementally**: Try one feature at a time (messaging, then twins, then methods)

### For Development

1. **Device Naming**: Use descriptive device IDs (`sensor-001`, `gateway-west`, etc.)
2. **Message Format**: Keep JSON messages consistent and well-structured
3. **Error Handling**: Monitor for connection issues and implement retry logic
4. **Telemetry Interval**: Adjust based on your testing needs (default: 2 seconds)

### For Production

1. **Security**:
   - Rotate device keys regularly
   - Use DPS for automated provisioning
   - Implement certificate-based authentication
   - Restrict network access

2. **Cost Optimization**:
   - Use F1 tier for development ($0/month)
   - Monitor message quotas
   - Clean up unused devices
   - Review Event Hub throughput needs

3. **Monitoring**:
   - Set up Azure Monitor alerts
   - Enable diagnostic logs
   - Track device connection state
   - Monitor message routing health

---

## 🛑 Troubleshooting

### Issue: "Can't connect to IoT Hub"

**Solution**:
```bash
# Check IoT Hub status
az iot hub show --name raspberrypi-iot-de5e1c --query properties.state

# Verify device exists
az iot hub device-identity show \
  --hub-name raspberrypi-iot-de5e1c \
  --device-id raspberrypi-simulator
```

### Issue: "Connection string not working"

**Check**:
- Using **device** connection string (not IoT Hub connection string)
- Connection string format is correct (HostName=...;DeviceId=...;SharedAccessKey=...)
- No extra spaces or line breaks

### Issue: "Messages not appearing"

**Verify**:
```bash
# Check if device is sending
az iot hub monitor-events \
  --hub-name raspberrypi-iot-de5e1c \
  --device-id raspberrypi-simulator

# Check IoT Hub stats
az iot hub show-stats --name raspberrypi-iot-de5e1c

# Verify routing
az iot hub route list --hub-name raspberrypi-iot-de5e1c
```

### Issue: "Event Hub not receiving messages"

**Check**:
```bash
# Verify endpoint
az iot hub routing-endpoint list \
  --hub-name raspberrypi-iot-de5e1c

# Check Event Hub metrics
az monitor metrics list \
  --resource /subscriptions/f712c020-9ac1-42ba-956b-dead6296ee0b/resourceGroups/rt-test-IoT/providers/Microsoft.EventHub/namespaces/raspberrypi-ehns \
  --metric IncomingMessages
```

---

## 🗑️ Clean Up

When you're done testing:

### Option 1: Keep Infrastructure, Remove Devices

```bash
az iot hub device-identity delete \
  --hub-name raspberrypi-iot-de5e1c \
  --device-id raspberrypi-simulator
```

### Option 2: Destroy All Resources

```bash
cd /Users/aadil/Projects/IoT_Testing
terraform destroy
```

Type `yes` when prompted.

---

## 📚 Additional Resources

- **Simulator**: https://azure-samples.github.io/raspberry-pi-web-simulator/
- **Tutorial**: https://learn.microsoft.com/en-us/azure/iot-hub/raspberry-pi-get-started
- **IoT Hub Docs**: https://learn.microsoft.com/en-us/azure/iot-hub/
- **Event Hub Docs**: https://learn.microsoft.com/en-us/azure/event-hubs/
- **DPS Docs**: https://learn.microsoft.com/en-us/azure/iot-dps/

---

## 💰 Cost Summary

| Service | SKU | Estimated Monthly Cost |
|---------|-----|------------------------|
| IoT Hub | S1 (1 unit) | ~$25/month |
| Event Hub | Standard (1 TU) | ~$22/month |
| DPS | S1 | ~$0.10/1000 operations |
| **Total** | | **~$50/month** |

**To Reduce Costs**:
- Change to IoT Hub F1 (free tier) - edit `terraform.tfvars`:
  ```hcl
  iothub_sku_name = "F1"
  ```
- Then run: `terraform apply`

---

## ✅ Success Checklist

After following this guide, you should have:

- [x] IoT Hub deployed and operational
- [x] Event Hub receiving telemetry
- [x] DPS linked to IoT Hub
- [ ] Device identity created
- [ ] Simulator connected and sending data
- [ ] Ability to monitor messages
- [ ] Cloud-to-device messaging working

---

**Need Help?** Check the documentation in:
- `README.md` - Architecture overview
- `QUICKSTART.md` - Quick start guide
- `DEPLOYMENT.md` - Troubleshooting guide

**Happy IoT Testing!** 🚀
