# Deployment Guide - Azure IoT Testing Infrastructure

This document provides detailed deployment instructions for the Azure IoT Hub testing environment designed for use with the Raspberry Pi Web Simulator.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Pre-Deployment Checklist](#pre-deployment-checklist)
4. [Deployment Steps](#deployment-steps)
5. [Post-Deployment Configuration](#post-deployment-configuration)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

## Overview

This Terraform project deploys:

- **Azure IoT Hub** - Device connectivity and message routing
- **Azure Event Hub** - Telemetry data streaming
- **Azure IoT Hub DPS** - Device Provisioning Service

All resources are deployed to the existing resource group: `rt-test-IoT`

## Prerequisites

### Required Tools

| Tool | Minimum Version | Check Command |
|------|----------------|---------------|
| Azure CLI | 2.50.0+ | `az --version` |
| Terraform | 1.0.0+ | `terraform --version` |
| Git | 2.30.0+ | `git --version` |

### Azure Permissions

You need the following permissions on the `rt-test-IoT` resource group:

- `Microsoft.Devices/*` - IoT Hub and DPS operations
- `Microsoft.EventHub/*` - Event Hub operations
- `Microsoft.Resources/deployments/*` - Deployment operations

Check your permissions:
```bash
az role assignment list \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/rt-test-IoT \
  --assignee $(az account show --query user.name -o tsv) \
  --output table
```

### Resource Quotas

Verify you have sufficient quota:

```bash
# Check IoT Hub quota
az iot hub list --query "length(@)" -o tsv

# Check Event Hub quota
az eventhubs namespace list --query "length(@)" -o tsv
```

Standard limits:
- IoT Hub: 50 per subscription (F1: 1 free tier per subscription)
- Event Hub: 100 namespaces per subscription

## Pre-Deployment Checklist

Before running `terraform apply`, ensure:

- [ ] Azure CLI is authenticated: `az account show`
- [ ] Correct subscription is selected: `az account set --subscription <subscription-id>`
- [ ] Resource group exists: `az group show --name rt-test-IoT`
- [ ] No naming conflicts (check if resources already exist):

```bash
# Check for existing IoT Hub
az iot hub show --name raspberrypi-iothub --query name 2>/dev/null

# Check for existing Event Hub namespace
az eventhubs namespace show --name raspberrypi-ehns --resource-group rt-test-IoT --query name 2>/dev/null

# Check for existing DPS
az iot dps show --name raspberrypi-dps --resource-group rt-test-IoT --query name 2>/dev/null
```

If any resources already exist, either:
1. Delete them first, OR
2. Change the `project_prefix` in `terraform.tfvars`

## Deployment Steps

### Step 1: Review Configuration

```bash
cd /Users/aadil/Projects/IoT_Testing

# Review variables
cat terraform.tfvars

# Review main configuration
cat main.tf
```

### Step 2: Initialize Terraform

```bash
terraform init
```

Expected output:
```
Terraform has been successfully initialized!
```

### Step 3: Plan Deployment

```bash
# Generate and review execution plan
terraform plan -out=tfplan

# Optional: Save plan to file for review
terraform show -json tfplan > tfplan.json
```

Review the plan output carefully:
- **Resources to create**: Should show 3 modules (iothub, eventhub, iothub_dps)
- **Total resources**: ~10-12 resources
- **Estimated time**: 3-5 minutes

### Step 4: Apply Configuration

```bash
# Apply the plan
terraform apply tfplan

# OR apply with auto-approval (use with caution)
terraform apply -auto-approve
```

Monitor the deployment:
```
module.eventhub.azurerm_eventhub_namespace.this: Creating...
module.eventhub.azurerm_eventhub_namespace.this: Creation complete
module.eventhub.azurerm_eventhub.this: Creating...
module.iothub.azurerm_iothub.this: Creating...
...
```

Expected deployment time: **3-5 minutes**

### Step 5: Save Outputs

```bash
# View all outputs
terraform output

# Save outputs to file
terraform output -json > deployment-outputs.json

# Extract specific values
export IOTHUB_NAME=$(terraform output -raw iothub_name)
export EH_NAMESPACE=$(terraform output -raw eventhub_namespace_name)
export EH_NAME=$(terraform output -raw eventhub_name)
export DPS_NAME=$(terraform output -raw dps_name)

# Display for verification
echo "IoT Hub: $IOTHUB_NAME"
echo "Event Hub Namespace: $EH_NAMESPACE"
echo "Event Hub: $EH_NAME"
echo "DPS: $DPS_NAME"
```

## Post-Deployment Configuration

### 1. Create Device Identity

```bash
# Create device for simulator
az iot hub device-identity create \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator \
  --edge-enabled false \
  --output table

# Get device connection string
export DEVICE_CONNECTION_STRING=$(az iot hub device-identity connection-string show \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator \
  --output tsv)

# Save connection string securely
echo $DEVICE_CONNECTION_STRING > .device-connection-string
chmod 600 .device-connection-string

# Display (copy this for simulator)
echo "Device Connection String:"
echo $DEVICE_CONNECTION_STRING
```

### 2. Verify Message Routing

```bash
# List routes
az iot hub route list \
  --hub-name $IOTHUB_NAME \
  --output table

# Check endpoint status
az iot hub routing-endpoint list \
  --hub-name $IOTHUB_NAME \
  --output table
```

Expected output:
```
Name              EndpointType  Enabled  Source          Condition
----------------  ------------  -------  --------------  ---------
telemetry-route   EventHub      True     DeviceMessages  true
```

### 3. Configure DPS (Optional)

If using Device Provisioning Service:

```bash
# Get DPS details
az iot dps show \
  --name $DPS_NAME \
  --resource-group rt-test-IoT \
  --output table

# View linked hubs
az iot dps linked-hub list \
  --dps-name $DPS_NAME \
  --resource-group rt-test-IoT \
  --output table
```

## Verification

### 1. Verify IoT Hub

```bash
# Check IoT Hub status
az iot hub show \
  --name $IOTHUB_NAME \
  --query "{Name:name, State:properties.state, Hostname:properties.hostName}" \
  --output table

# View metrics
az monitor metrics list \
  --resource $(az iot hub show --name $IOTHUB_NAME --query id -o tsv) \
  --metric "d2c.telemetry.ingress.success" \
  --start-time $(date -u -v-1H +"%Y-%m-%dT%H:%M:%SZ") \
  --output table
```

### 2. Verify Event Hub

```bash
# Check Event Hub status
az eventhubs eventhub show \
  --namespace-name $EH_NAMESPACE \
  --name $EH_NAME \
  --resource-group rt-test-IoT \
  --output table

# List consumer groups
az eventhubs eventhub consumer-group list \
  --namespace-name $EH_NAMESPACE \
  --eventhub-name $EH_NAME \
  --resource-group rt-test-IoT \
  --output table
```

Expected consumer groups:
- `$Default` (auto-created)
- `telemetry-processor`
- `archive-processor`

### 3. Verify DPS

```bash
# Check DPS status
az iot dps show \
  --name $DPS_NAME \
  --resource-group rt-test-IoT \
  --query "{Name:name, State:properties.state, IDScope:properties.idScope}" \
  --output table
```

### 4. Test Device Connection

```bash
# Monitor for device connections
az iot hub monitor-events \
  --hub-name $IOTHUB_NAME \
  --properties sys anno \
  --timeout 60
```

Now open the simulator and connect - you should see messages appear.

## Troubleshooting

### Issue: Terraform apply fails with "already exists"

**Cause**: Resources with the same name already exist

**Solution**:
```bash
# Option 1: Import existing resources
terraform import module.iothub.azurerm_iothub.this /subscriptions/.../resourceGroups/rt-test-IoT/providers/Microsoft.Devices/IotHubs/raspberrypi-iothub

# Option 2: Change project prefix in terraform.tfvars
sed -i '' 's/project_prefix = "raspberrypi"/project_prefix = "raspberrypi-v2"/' terraform.tfvars
terraform init
terraform apply
```

### Issue: "Quota exceeded"

**Cause**: Subscription limits reached

**Solution**:
```bash
# Delete unused resources
az iot hub list --query "[?not_null(properties.state)].{Name:name, RG:resourceGroup, State:properties.state}" -o table

# Delete specific hub
az iot hub delete --name <unused-hub-name> --resource-group <rg-name>

# Or request quota increase
az support tickets create --ticket-name "IoTHubQuota" ...
```

### Issue: "Authentication failed"

**Cause**: Azure CLI session expired or wrong subscription

**Solution**:
```bash
# Re-authenticate
az login

# Verify subscription
az account show

# Set correct subscription
az account set --subscription <subscription-id>

# Retry deployment
terraform apply
```

### Issue: Module initialization fails

**Cause**: Module path incorrect or modules not found

**Solution**:
```bash
# Verify module structure
ls -R AzureRM4/modules/

# Re-initialize
rm -rf .terraform
terraform init
```

### Issue: Connection string not working in simulator

**Cause**: Using wrong connection string type

**Solution**:
```bash
# CORRECT: Device connection string (per device)
az iot hub device-identity connection-string show \
  --hub-name $IOTHUB_NAME \
  --device-id raspberrypi-simulator

# WRONG: IoT Hub connection string (for management)
terraform output iothub_connection_string  # Don't use this in simulator!
```

Device connection string format:
```
HostName=raspberrypi-iothub.azure-devices.net;DeviceId=raspberrypi-simulator;SharedAccessKey=...
```

### Issue: Messages not appearing in Event Hub

**Cause**: Routing not configured correctly

**Solution**:
```bash
# Verify endpoint configuration
az iot hub routing-endpoint show \
  --hub-name $IOTHUB_NAME \
  --endpoint-name telemetry-endpoint

# Test endpoint health
az iot hub routing-endpoint list \
  --hub-name $IOTHUB_NAME \
  --output table

# Check route condition
az iot hub route show \
  --hub-name $IOTHUB_NAME \
  --route-name telemetry-route
```

## Rollback Procedure

If deployment fails or you need to rollback:

### Partial Rollback (specific module)

```bash
# Destroy only IoT Hub
terraform destroy -target=module.iothub

# Destroy only Event Hub
terraform destroy -target=module.eventhub

# Destroy only DPS
terraform destroy -target=module.iothub_dps
```

### Complete Rollback

```bash
# Destroy all resources
terraform destroy

# Confirm by typing: yes

# Cleanup Terraform state
rm -rf .terraform
rm .terraform.lock.hcl
rm terraform.tfstate*
```

## Cost Optimization

### Use Free Tier for Testing

Edit `terraform.tfvars`:
```hcl
iothub_sku_name = "F1"  # Free tier (8,000 messages/day)
eventhub_sku = "Basic"  # Lower cost tier
```

Then:
```bash
terraform apply
```

### Monitor Costs

```bash
# View cost analysis
az consumption usage list \
  --start-date $(date -u -v-30d +"%Y-%m-%d") \
  --end-date $(date -u +"%Y-%m-%d") \
  --query "[?contains(instanceId, 'rt-test-IoT')]" \
  --output table

# Set up budget alert
az consumption budget create \
  --budget-name "IoT-Testing-Budget" \
  --amount 100 \
  --category Cost \
  --time-grain Monthly \
  --start-date $(date -u +"%Y-%m-01T00:00:00Z") \
  --end-date $(date -u -v+1y +"%Y-%m-01T00:00:00Z")
```

## Security Best Practices

1. **Rotate device keys regularly**:
   ```bash
   az iot hub device-identity renew-key \
     --hub-name $IOTHUB_NAME \
     --device-id raspberrypi-simulator \
     --key-type primary
   ```

2. **Use Azure Key Vault for connection strings**:
   ```bash
   # Store device connection string in Key Vault
   az keyvault secret set \
     --vault-name <your-keyvault> \
     --name raspberrypi-connection-string \
     --value "$DEVICE_CONNECTION_STRING"
   ```

3. **Enable diagnostic logs**:
   ```bash
   az monitor diagnostic-settings create \
     --name iot-hub-diagnostics \
     --resource $(az iot hub show --name $IOTHUB_NAME --query id -o tsv) \
     --logs '[{"category": "Connections", "enabled": true}]' \
     --workspace <log-analytics-workspace-id>
   ```

4. **Restrict network access** (for production):
   ```bash
   # Disable public network access
   az iot hub update \
     --name $IOTHUB_NAME \
     --set properties.publicNetworkAccess=Disabled
   ```

## Next Steps

After successful deployment:

1. ✅ **Review** [QUICKSTART.md](QUICKSTART.md) for testing with simulator
2. ✅ **Read** [README.md](README.md) for architecture details
3. ✅ **Test** message routing and C2D messaging
4. ✅ **Explore** device twins and direct methods
5. ✅ **Build** a consumer application for Event Hub data

## Support

For issues with deployment:
- Check Terraform logs: `terraform plan -debug`
- Review Azure Activity Log in Portal
- Contact your Azure administrator for quota or permissions issues

## References

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure IoT Hub Terraform Module](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/iothub)
- [Azure CLI IoT Extension](https://learn.microsoft.com/en-us/cli/azure/iot)
