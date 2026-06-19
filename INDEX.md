# Azure IoT Testing Infrastructure - Complete Index

## 📋 Quick Navigation

| Document | Purpose | Read Time | Priority |
|----------|---------|-----------|----------|
| [README.md](README.md) | Architecture & overview | 5 min | ⭐⭐⭐ |
| [QUICKSTART.md](QUICKSTART.md) | Get started in 10 minutes | 10 min | ⭐⭐⭐⭐⭐ |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Detailed deployment guide | 15 min | ⭐⭐⭐⭐ |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | File organization | 8 min | ⭐⭐⭐ |
| [INDEX.md](INDEX.md) | This file - complete index | 3 min | ⭐⭐ |

## 🚀 Getting Started Paths

### Path 1: Quick Testing (Recommended for First-Time Users)

```bash
# 1. Run automated setup
./setup.sh

# 2. Follow on-screen instructions to get device connection string

# 3. Open simulator and start testing
open https://azure-samples.github.io/raspberry-pi-web-simulator/
```

**Estimated Time**: 10 minutes

**Best For**: First deployment, quick testing, learning IoT Hub

**Documentation**: [QUICKSTART.md](QUICKSTART.md)

---

### Path 2: Manual Deployment (Recommended for DevOps)

```bash
# 1. Review configuration
cat terraform.tfvars

# 2. Initialize and deploy
terraform init
terraform plan
terraform apply

# 3. Create device and test
az iot hub device-identity create --hub-name raspberrypi-iothub --device-id test-device
```

**Estimated Time**: 15 minutes

**Best For**: Production deployment, custom configuration, CI/CD

**Documentation**: [DEPLOYMENT.md](DEPLOYMENT.md)

---

### Path 3: Understanding the Architecture

```bash
# 1. Read architecture overview
cat README.md

# 2. Understand project structure
cat PROJECT_STRUCTURE.md

# 3. Explore modules
ls -R AzureRM4/modules/
```

**Estimated Time**: 20 minutes

**Best For**: Developers, architects, learning Terraform

**Documentation**: [README.md](README.md) + [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)

---

## 📁 File Reference

### Configuration Files

| File | Purpose | Edit Frequency |
|------|---------|----------------|
| `terraform.tfvars` | **Resource configuration** - names, SKUs, settings | **Often** |
| `main.tf` | Infrastructure definition using modules | Sometimes |
| `variables.tf` | Variable definitions and defaults | Rarely |
| `outputs.tf` | Output values after deployment | Rarely |
| `providers.tf` | Terraform and provider versions | Rarely |

### Documentation Files

| File | Content | Audience |
|------|---------|----------|
| `README.md` | Architecture, features, references | Everyone |
| `QUICKSTART.md` | 10-minute quick start guide | First-time users |
| `DEPLOYMENT.md` | Detailed deployment & troubleshooting | DevOps engineers |
| `PROJECT_STRUCTURE.md` | Project organization & customization | Developers |
| `INDEX.md` | This file - navigation hub | Everyone |

### Automation

| File | Purpose | When to Use |
|------|---------|-------------|
| `setup.sh` | Automated deployment and device creation | First deployment |

### Modules

| Module | Location | Purpose |
|--------|----------|---------|
| IoT Hub | `AzureRM4/modules/iothub/` | Device connectivity and messaging |
| IoT Hub DPS | `AzureRM4/modules/iothub-dps/` | Device provisioning |
| Event Hub | `AzureRM4/modules/eventhub/` | Telemetry streaming |

---

## 🎯 Common Tasks

### Deploy Infrastructure

```bash
# Quick way (automated)
./setup.sh

# Manual way (more control)
terraform init
terraform apply
```

📖 Detailed guide: [DEPLOYMENT.md](DEPLOYMENT.md)

---

### Test with Raspberry Pi Simulator

```bash
# 1. Get device connection string
az iot hub device-identity connection-string show \
  --hub-name raspberrypi-iothub \
  --device-id raspberrypi-simulator

# 2. Open simulator
open https://azure-samples.github.io/raspberry-pi-web-simulator/

# 3. Replace connection string on line 15

# 4. Monitor messages
az iot hub monitor-events \
  --hub-name raspberrypi-iothub \
  --device-id raspberrypi-simulator
```

📖 Detailed guide: [QUICKSTART.md](QUICKSTART.md)

---

### Modify Configuration

```bash
# Edit resource names, SKUs, etc.
vi terraform.tfvars

# Preview changes
terraform plan

# Apply changes
terraform apply
```

📖 Detailed guide: [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md#customization-points)

---

### Monitor and Troubleshoot

```bash
# View deployed resources
terraform output

# Check IoT Hub status
az iot hub show --name raspberrypi-iothub

# Monitor device messages
az iot hub monitor-events --hub-name raspberrypi-iothub

# View Event Hub metrics
az monitor metrics list --resource $(terraform output -raw eventhub_namespace_name)
```

📖 Detailed guide: [DEPLOYMENT.md](DEPLOYMENT.md#troubleshooting)

---

### Clean Up Resources

```bash
# Destroy all resources
terraform destroy

# Or delete specific module
terraform destroy -target=module.iothub
```

📖 Detailed guide: [DEPLOYMENT.md](DEPLOYMENT.md#rollback-procedure)

---

## 🏗️ Architecture Components

### IoT Hub (`raspberrypi-iothub`)

**Purpose**: Central hub for device connectivity

**Features**:
- Device authentication
- Message routing to Event Hub
- Cloud-to-device messaging
- Device twin support

**Configuration**: `main.tf` lines 22-76

**Module**: `AzureRM4/modules/iothub/`

---

### Event Hub (`raspberrypi-ehns` / `raspberrypi-telemetry`)

**Purpose**: Stream and process telemetry data

**Features**:
- 4 partitions for parallel processing
- 1-day message retention
- 2 consumer groups (telemetry-processor, archive-processor)

**Configuration**: `main.tf` lines 8-20

**Module**: `AzureRM4/modules/eventhub/`

---

### Device Provisioning Service (`raspberrypi-dps`)

**Purpose**: Automated device provisioning

**Features**:
- Linked to IoT Hub
- Hashed allocation policy
- Zero-touch provisioning

**Configuration**: `main.tf` lines 78-99

**Module**: `AzureRM4/modules/iothub-dps/`

---

## 🔧 Customization Examples

### Change to Free Tier (F1)

```hcl
# In terraform.tfvars
iothub_sku_name = "F1"  # Free tier (8,000 messages/day)
```

Then:
```bash
terraform apply
```

---

### Add Custom Consumer Group

```hcl
# In main.tf, under module "eventhub"
consumer_groups = [
  {
    name          = "my-custom-processor"
    user_metadata = "Custom processing logic"
  },
  # ... existing groups
]
```

---

### Change Resource Names

```hcl
# In terraform.tfvars
project_prefix = "my-iot-project"
```

Results in:
- `my-iot-project-iothub`
- `my-iot-project-ehns`
- `my-iot-project-dps`

---

### Add Additional Route

```hcl
# In main.tf, under module "iothub"
routes = [
  {
    name           = "device-lifecycle"
    source         = "DeviceLifecycleEvents"
    condition      = "true"
    endpoint_names = ["telemetry-endpoint"]
    enabled        = true
  },
  # ... existing routes
]
```

---

## 📊 Deployed Resources Summary

After deployment, you'll have:

| Resource Type | Name | Purpose |
|--------------|------|---------|
| Resource Group | `rt-test-IoT` | Container (pre-existing) |
| IoT Hub | `raspberrypi-iothub` | Device connectivity |
| Event Hub Namespace | `raspberrypi-ehns` | Event streaming namespace |
| Event Hub | `raspberrypi-telemetry` | Telemetry event hub |
| Consumer Group | `telemetry-processor` | Process telemetry |
| Consumer Group | `archive-processor` | Archive telemetry |
| IoT Hub DPS | `raspberrypi-dps` | Device provisioning |

**Total Resources**: ~7 Azure resources

**Estimated Monthly Cost**: $50 (S1 tier) or $22 (with F1 IoT Hub)

---

## 🔒 Security Considerations

### Sensitive Files (Never Commit)

- ❌ `terraform.tfstate` - Contains secrets
- ❌ `.device-connection-string` - Device credentials
- ❌ `terraform-outputs.json` - May contain secrets

### Safe to Commit

- ✅ `*.tf` - Configuration files
- ✅ `terraform.tfvars` - If no secrets
- ✅ `*.md` - Documentation
- ✅ `.terraform.lock.hcl` - Provider versions

### Best Practices

1. Use Azure Key Vault for connection strings
2. Rotate device keys regularly
3. Enable diagnostic logging
4. Restrict network access in production
5. Use managed identities when possible

📖 Detailed guide: [DEPLOYMENT.md](DEPLOYMENT.md#security-best-practices)

---

## 📚 External Resources

### Official Documentation

- [Azure IoT Hub](https://learn.microsoft.com/en-us/azure/iot-hub/)
- [Raspberry Pi Simulator](https://azure-samples.github.io/raspberry-pi-web-simulator/)
- [Raspberry Pi Tutorial](https://learn.microsoft.com/en-us/azure/iot-hub/raspberry-pi-get-started)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

### Source Code

- [Simulator Source](https://github.com/Azure-Samples/raspberry-pi-web-simulator) (Archived)
- [Azure IoT SDKs](https://github.com/Azure/azure-iot-sdks)

### Pricing

- [IoT Hub Pricing](https://azure.microsoft.com/en-us/pricing/details/iot-hub/)
- [Event Hub Pricing](https://azure.microsoft.com/en-us/pricing/details/event-hubs/)
- [DPS Pricing](https://azure.microsoft.com/en-us/pricing/details/iot-hub/)

---

## 🆘 Getting Help

### Issue Resolution Order

1. **Check Documentation**
   - [QUICKSTART.md](QUICKSTART.md) - Common scenarios
   - [DEPLOYMENT.md](DEPLOYMENT.md) - Troubleshooting section

2. **Run Diagnostics**
   ```bash
   terraform validate
   az iot hub show --name raspberrypi-iothub
   ```

3. **Review Logs**
   ```bash
   terraform plan -debug
   az monitor activity-log list --resource-group rt-test-IoT
   ```

4. **Community Support**
   - Azure IoT Q&A: https://learn.microsoft.com/en-us/answers/tags/158/azure-iot-hub/
   - Terraform Forums: https://discuss.hashicorp.com/

---

## ✅ Success Checklist

After following this project, you should have:

- [x] Terraform configuration initialized
- [x] IoT Hub deployed and accessible
- [x] Event Hub receiving telemetry
- [x] DPS linked to IoT Hub
- [x] Device identity created
- [x] Simulator connected and sending data
- [x] Ability to monitor messages
- [x] Cloud-to-device messaging working

---

## 🎓 Learning Path

### Beginner (0-2 hours)

1. Read [README.md](README.md)
2. Follow [QUICKSTART.md](QUICKSTART.md)
3. Test simulator with device connection
4. Monitor messages with Azure CLI

### Intermediate (2-5 hours)

1. Read [DEPLOYMENT.md](DEPLOYMENT.md)
2. Customize `terraform.tfvars`
3. Add custom routes and enrichments
4. Explore device twins and direct methods

### Advanced (5+ hours)

1. Read [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)
2. Modify modules for custom requirements
3. Build Event Hub consumer application
4. Implement DPS provisioning workflow
5. Add monitoring and alerting

---

## 📞 Quick Reference Commands

```bash
# Deploy
./setup.sh                     # Automated
terraform apply                # Manual

# Test
az iot hub monitor-events --hub-name raspberrypi-iothub --device-id raspberrypi-simulator

# Manage
terraform output               # View outputs
terraform plan                 # Preview changes
terraform apply                # Apply changes
terraform destroy              # Clean up

# Debug
terraform validate             # Check syntax
az iot hub show --name raspberrypi-iothub  # Check status
```

---

## 🗺️ Document Map

```
INDEX.md (You are here)
    ├── README.md              → Architecture overview
    ├── QUICKSTART.md          → Quick start guide
    │   └── setup.sh           → Automation script
    ├── DEPLOYMENT.md          → Deployment guide
    └── PROJECT_STRUCTURE.md   → File organization
        ├── main.tf            → Infrastructure config
        ├── variables.tf       → Variable definitions
        ├── outputs.tf         → Output definitions
        └── terraform.tfvars   → Variable values
```

---

**Last Updated**: June 18, 2026

**Version**: 1.0.0

**Maintained By**: Your Team

**License**: MIT (if applicable)

---

## 🎉 Ready to Start?

Choose your path:

1. **Quick Start**: Jump to [QUICKSTART.md](QUICKSTART.md)
2. **Learn Architecture**: Read [README.md](README.md)
3. **Deep Dive**: Study [DEPLOYMENT.md](DEPLOYMENT.md)

**Happy IoT Testing!** 🚀
