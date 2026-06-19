# Project Structure

This document describes the organization of the Azure IoT Testing Infrastructure project.

## Directory Layout

```
IoT_Testing/
├── README.md                      # Main documentation and architecture overview
├── QUICKSTART.md                  # Quick start guide for testing
├── DEPLOYMENT.md                  # Detailed deployment instructions
├── PROJECT_STRUCTURE.md           # This file - project organization
├── setup.sh                       # Automated setup script
│
├── providers.tf                   # Terraform provider configuration
├── variables.tf                   # Input variable definitions
├── main.tf                        # Main infrastructure configuration
├── outputs.tf                     # Output value definitions
├── terraform.tfvars               # Variable values (customize here)
├── .gitignore                     # Git ignore patterns
│
└── AzureRM4/                      # Terraform modules directory
    └── modules/
        ├── iothub/                # IoT Hub module
        │   ├── main.tf            # IoT Hub resources
        │   ├── variables.tf       # Module input variables
        │   ├── outputs.tf         # Module outputs
        │   └── backend.tf         # Provider requirements
        │
        ├── iothub-dps/            # Device Provisioning Service module
        │   ├── main.tf            # DPS resources
        │   ├── variables.tf       # Module input variables
        │   ├── outputs.tf         # Module outputs
        │   └── backend.tf         # Provider requirements
        │
        └── eventhub/              # Event Hub module
            ├── main.tf            # Event Hub resources
            ├── variables.tf       # Module input variables
            ├── outputs.tf         # Module outputs
            └── backend.tf         # Provider requirements
```

## File Descriptions

### Root Level Configuration Files

| File | Purpose | When to Edit |
|------|---------|--------------|
| `providers.tf` | Configures Terraform and Azure provider | Rarely - only for provider version updates |
| `variables.tf` | Defines all input variables with descriptions and defaults | Add new variables for customization |
| `main.tf` | Main infrastructure configuration using modules | Modify to change resource configuration |
| `outputs.tf` | Defines output values displayed after deployment | Add outputs for new resources |
| `terraform.tfvars` | **Variable values** - resource names, SKUs, etc. | **Edit this to customize your deployment** |
| `.gitignore` | Specifies files to exclude from version control | Add patterns for sensitive files |

### Documentation Files

| File | Target Audience | Content |
|------|----------------|---------|
| `README.md` | All users | Architecture overview, module structure, references |
| `QUICKSTART.md` | First-time users | 10-minute quick start with simulator |
| `DEPLOYMENT.md` | DevOps engineers | Detailed deployment, troubleshooting, security |
| `PROJECT_STRUCTURE.md` | Developers | This file - project organization |

### Automation Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `setup.sh` | Automated deployment and device creation | Run once: `./setup.sh` |

### Module Files

Each module (`iothub/`, `iothub-dps/`, `eventhub/`) contains:

| File | Purpose |
|------|---------|
| `main.tf` | Resource definitions for the module |
| `variables.tf` | Module input parameters |
| `outputs.tf` | Module output values |
| `backend.tf` | Provider and version constraints |

## Generated Files (Not in Git)

After running Terraform, these files are created:

```
IoT_Testing/
├── .terraform/                    # Terraform plugins and modules (gitignored)
├── .terraform.lock.hcl            # Provider version lock file (commit this)
├── terraform.tfstate              # Current infrastructure state (gitignored)
├── terraform.tfstate.backup       # Previous state backup (gitignored)
├── tfplan                         # Binary plan file (gitignored)
├── .device-connection-string      # Device credentials (gitignored)
└── terraform-outputs.json         # JSON export of outputs (gitignored)
```

## Configuration Flow

```
terraform.tfvars  →  variables.tf  →  main.tf  →  modules/  →  outputs.tf
     (values)         (definitions)    (config)    (resources)   (results)
```

### Example Flow for IoT Hub

1. **User sets value** in `terraform.tfvars`:
   ```hcl
   iothub_sku_name = "S1"
   ```

2. **Variable defined** in `variables.tf`:
   ```hcl
   variable "iothub_sku_name" {
     description = "IoT Hub SKU"
     type        = string
     default     = "S1"
   }
   ```

3. **Passed to module** in `main.tf`:
   ```hcl
   module "iothub" {
     source   = "./AzureRM4/modules/iothub"
     sku_name = var.iothub_sku_name
     ...
   }
   ```

4. **Used in module** `modules/iothub/main.tf`:
   ```hcl
   resource "azurerm_iothub" "this" {
     sku {
       name = var.sku_name
     }
   }
   ```

5. **Output returned** in `outputs.tf`:
   ```hcl
   output "iothub_name" {
     value = module.iothub.name
   }
   ```

## Customization Points

### Easy Customization (terraform.tfvars)

Change these values without modifying code:

```hcl
# Resource names
project_prefix = "raspberrypi"        # Change to customize all resource names

# Location
location = "North Europe"              # Change Azure region

# IoT Hub sizing
iothub_sku_name     = "S1"           # F1 (free) or S1/S2/S3 (standard)
iothub_sku_capacity = 1              # Number of units

# Event Hub sizing
eventhub_sku      = "Standard"       # Basic, Standard, or Premium
eventhub_capacity = 1                # Throughput units (1-40)

# DPS configuration
dps_allocation_policy = "Hashed"     # Hashed, GeoLatency, or Static
```

### Moderate Customization (main.tf)

Modify resource configuration:

- Add/remove Event Hub consumer groups
- Configure additional IoT Hub routes
- Add message enrichments
- Configure DPS IP filters
- Link additional IoT Hubs to DPS

### Advanced Customization (modules/)

**⚠️ Caution**: Modifying modules affects all uses of the module

- Add new resources to modules
- Modify resource properties
- Add new variables or outputs
- Change validation rules

## Resource Naming Convention

All resources follow this pattern:

```
{project_prefix}-{resource_type}

Examples:
- raspberrypi-iothub        (IoT Hub)
- raspberrypi-dps           (Device Provisioning Service)
- raspberrypi-ehns          (Event Hub Namespace)
- raspberrypi-telemetry     (Event Hub)
```

To change naming:

1. Edit `project_prefix` in `terraform.tfvars`
2. Or modify resource names directly in `main.tf`

## State Management

### Local State (Current Setup)

- State stored in `terraform.tfstate` (gitignored)
- **Warning**: Don't lose this file or share it (contains secrets)
- **Backup**: Keep secure backups of `.terraform.tfstate`

### Remote State (Recommended for Teams)

To use Azure Storage for state:

1. Create storage account:
   ```bash
   az storage account create --name tfstateXXXXX --resource-group rt-test-IoT
   az storage container create --name tfstate --account-name tfstateXXXXX
   ```

2. Add backend config to `providers.tf`:
   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "rt-test-IoT"
       storage_account_name = "tfstateXXXXX"
       container_name       = "tfstate"
       key                  = "iot-testing.tfstate"
     }
   }
   ```

3. Initialize:
   ```bash
   terraform init -migrate-state
   ```

## Module Dependencies

```
eventhub
    ↓
  (connection string)
    ↓
 iothub
    ↓
  (connection string)
    ↓
iothub-dps
```

Dependencies are implicit through resource references - no explicit `depends_on` needed.

## Best Practices

### Development Workflow

1. **Make changes** in feature branch
2. **Test locally** with `terraform plan`
3. **Review changes** carefully
4. **Apply** with `terraform apply`
5. **Commit** configuration files (not state!)
6. **Document** changes in commit message

### Variable Management

```hcl
# ✅ Good: In terraform.tfvars
iothub_sku_name = "S1"

# ❌ Bad: Hardcoded in main.tf
sku_name = "S1"
```

### Secret Management

```bash
# ✅ Good: Sensitive outputs
output "connection_string" {
  value     = "..."
  sensitive = true
}

# ✅ Good: Retrieve when needed
terraform output -raw connection_string

# ❌ Bad: Storing in plain text files
echo $CONNECTION_STRING > connection.txt
```

### Module Versioning

If modules are in a separate repository:

```hcl
module "iothub" {
  source  = "git::https://github.com/org/modules.git//iothub?ref=v1.2.0"
  # ...
}
```

## Troubleshooting File Issues

### Issue: "Module not found"

**Check**:
```bash
ls -R AzureRM4/modules/
```

**Fix**: Ensure module paths in `main.tf` match actual directory structure

### Issue: "No such variable"

**Check**:
```bash
grep "var\." main.tf
grep "variable" variables.tf
```

**Fix**: Ensure all variables in `main.tf` are defined in `variables.tf`

### Issue: "State file locked"

**Check**:
```bash
ls -la .terraform
```

**Fix**:
```bash
rm -rf .terraform/*.tflock
terraform init
```

## Testing Changes

### Validate Syntax

```bash
terraform fmt -check      # Check formatting
terraform validate        # Validate configuration
terraform plan           # Preview changes
```

### Test in Isolation

```bash
# Test single module
terraform plan -target=module.iothub

# Apply single module
terraform apply -target=module.iothub
```

### Dry Run

```bash
# Create plan without applying
terraform plan -out=test.tfplan

# Review plan
terraform show test.tfplan

# Discard
rm test.tfplan
```

## Related Files

- `.terraform.lock.hcl` - Lock file (commit to repo)
- `.device-connection-string` - Generated device credentials (gitignored)
- `terraform-outputs.json` - Exported outputs (gitignored)
- `tfplan` - Binary plan file (gitignored)

## Version Control

### Files to Commit

- ✅ `*.tf` - All Terraform configuration
- ✅ `*.tfvars` - Variable values (if no secrets)
- ✅ `*.md` - Documentation
- ✅ `*.sh` - Scripts
- ✅ `.gitignore` - Ignore patterns
- ✅ `.terraform.lock.hcl` - Provider versions

### Files to Ignore

- ❌ `.terraform/` - Provider binaries
- ❌ `*.tfstate*` - State files (contain secrets)
- ❌ `tfplan` - Plan files
- ❌ `.device-connection-string` - Credentials

## Getting Help

1. **Documentation**: Read `README.md`, `QUICKSTART.md`, `DEPLOYMENT.md`
2. **Terraform Docs**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
3. **Azure Docs**: https://learn.microsoft.com/en-us/azure/
4. **Module Source**: Check module `main.tf` files for implementation details

## Quick Reference

```bash
# List all files
ls -R

# Show configuration
cat main.tf

# Show variable values
cat terraform.tfvars

# Show outputs
terraform output

# Validate setup
terraform validate

# See what would change
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy
```
