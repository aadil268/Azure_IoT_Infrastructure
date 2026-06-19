#!/bin/bash

# IoT Testing Infrastructure Setup Script
# This script automates the deployment and initial configuration

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    log_success "Azure CLI found: $(az --version | head -n 1)"
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Install from: https://www.terraform.io/downloads"
        exit 1
    fi
    log_success "Terraform found: $(terraform --version | head -n 1)"
    
    # Check Azure login
    if ! az account show &> /dev/null; then
        log_error "Not logged in to Azure. Run: az login"
        exit 1
    fi
    log_success "Azure CLI authenticated"
    
    # Display subscription
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    log_info "Using subscription: ${YELLOW}${SUBSCRIPTION_NAME}${NC} (${SUBSCRIPTION_ID})"
    
    # Check resource group
    if ! az group show --name rt-test-IoT &> /dev/null; then
        log_error "Resource group 'rt-test-IoT' not found"
        exit 1
    fi
    log_success "Resource group 'rt-test-IoT' found"
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform..."
    
    if terraform init; then
        log_success "Terraform initialized successfully"
    else
        log_error "Terraform initialization failed"
        exit 1
    fi
}

# Validate Terraform configuration
validate_terraform() {
    log_info "Validating Terraform configuration..."
    
    if terraform validate; then
        log_success "Terraform configuration is valid"
    else
        log_error "Terraform configuration validation failed"
        exit 1
    fi
}

# Plan deployment
plan_deployment() {
    log_info "Creating deployment plan..."
    
    if terraform plan -out=tfplan; then
        log_success "Deployment plan created successfully"
        echo ""
        log_warning "Review the plan above carefully before proceeding"
        echo ""
    else
        log_error "Failed to create deployment plan"
        exit 1
    fi
}

# Apply deployment
apply_deployment() {
    log_info "Deploying infrastructure..."
    echo ""
    
    if terraform apply tfplan; then
        log_success "Infrastructure deployed successfully"
        rm -f tfplan
    else
        log_error "Deployment failed"
        exit 1
    fi
}

# Create device identity
create_device() {
    local iothub_name=$1
    local device_id="raspberrypi-simulator"
    
    log_info "Creating device identity: ${device_id}"
    
    # Check if device already exists
    if az iot hub device-identity show --hub-name "$iothub_name" --device-id "$device_id" &> /dev/null; then
        log_warning "Device '${device_id}' already exists"
        read -p "Do you want to delete and recreate it? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            az iot hub device-identity delete --hub-name "$iothub_name" --device-id "$device_id"
            log_info "Existing device deleted"
        else
            log_info "Keeping existing device"
            return 0
        fi
    fi
    
    # Create device
    if az iot hub device-identity create \
        --hub-name "$iothub_name" \
        --device-id "$device_id" \
        --output none; then
        log_success "Device created: ${device_id}"
    else
        log_error "Failed to create device"
        return 1
    fi
}

# Get device connection string
get_device_connection_string() {
    local iothub_name=$1
    local device_id="raspberrypi-simulator"
    
    log_info "Retrieving device connection string..."
    
    local conn_string=$(az iot hub device-identity connection-string show \
        --hub-name "$iothub_name" \
        --device-id "$device_id" \
        --output tsv)
    
    if [ -n "$conn_string" ]; then
        echo "$conn_string" > .device-connection-string
        chmod 600 .device-connection-string
        log_success "Device connection string saved to: .device-connection-string"
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}Device Connection String:${NC}"
        echo ""
        echo -e "${YELLOW}${conn_string}${NC}"
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        log_info "Copy this connection string to the Raspberry Pi simulator (line 15)"
    else
        log_error "Failed to retrieve connection string"
        return 1
    fi
}

# Display deployment summary
display_summary() {
    echo ""
    log_info "═══════════════════════════════════════════════════════════"
    log_success "Deployment Complete!"
    log_info "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Get outputs
    IOTHUB_NAME=$(terraform output -raw iothub_name 2>/dev/null)
    IOTHUB_HOSTNAME=$(terraform output -raw iothub_hostname 2>/dev/null)
    EH_NAMESPACE=$(terraform output -raw eventhub_namespace_name 2>/dev/null)
    EH_NAME=$(terraform output -raw eventhub_name 2>/dev/null)
    DPS_NAME=$(terraform output -raw dps_name 2>/dev/null)
    DPS_ID_SCOPE=$(terraform output -raw dps_id_scope 2>/dev/null)
    
    echo -e "${BLUE}Resources Created:${NC}"
    echo -e "  ${GREEN}•${NC} IoT Hub: ${YELLOW}${IOTHUB_NAME}${NC}"
    echo -e "  ${GREEN}•${NC} Hostname: ${YELLOW}${IOTHUB_HOSTNAME}${NC}"
    echo -e "  ${GREEN}•${NC} Event Hub Namespace: ${YELLOW}${EH_NAMESPACE}${NC}"
    echo -e "  ${GREEN}•${NC} Event Hub: ${YELLOW}${EH_NAME}${NC}"
    echo -e "  ${GREEN}•${NC} Device Provisioning Service: ${YELLOW}${DPS_NAME}${NC}"
    echo -e "  ${GREEN}•${NC} DPS ID Scope: ${YELLOW}${DPS_ID_SCOPE}${NC}"
    echo ""
    
    echo -e "${BLUE}Next Steps:${NC}"
    echo -e "  1. Open simulator: ${YELLOW}https://azure-samples.github.io/raspberry-pi-web-simulator/${NC}"
    echo -e "  2. Replace connection string on line 15 with the one shown above"
    echo -e "  3. Click 'Run' button"
    echo -e "  4. Monitor messages:"
    echo -e "     ${YELLOW}az iot hub monitor-events --hub-name ${IOTHUB_NAME} --device-id raspberrypi-simulator${NC}"
    echo ""
    
    log_info "For more details, see:"
    echo -e "  ${YELLOW}• README.md${NC} - Architecture and overview"
    echo -e "  ${YELLOW}• QUICKSTART.md${NC} - Quick testing guide"
    echo -e "  ${YELLOW}• DEPLOYMENT.md${NC} - Detailed deployment docs"
    echo ""
}

# Main execution
main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Azure IoT Testing Infrastructure Setup                  ║${NC}"
    echo -e "${BLUE}║   Raspberry Pi Web Simulator Configuration                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Ask for confirmation
    read -p "Do you want to proceed with deployment? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]?$ ]]; then
        log_warning "Deployment cancelled"
        exit 0
    fi
    echo ""
    
    # Initialize Terraform
    init_terraform
    echo ""
    
    # Validate configuration
    validate_terraform
    echo ""
    
    # Create plan
    plan_deployment
    
    # Ask for confirmation to apply
    read -p "Do you want to apply this plan? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]?$ ]]; then
        log_warning "Deployment cancelled"
        rm -f tfplan
        exit 0
    fi
    echo ""
    
    # Apply deployment
    apply_deployment
    echo ""
    
    # Get IoT Hub name
    IOTHUB_NAME=$(terraform output -raw iothub_name 2>/dev/null)
    
    if [ -z "$IOTHUB_NAME" ]; then
        log_error "Could not retrieve IoT Hub name from outputs"
        exit 1
    fi
    
    # Create device
    create_device "$IOTHUB_NAME"
    echo ""
    
    # Get connection string
    get_device_connection_string "$IOTHUB_NAME"
    
    # Display summary
    display_summary
    
    log_success "Setup complete! Happy IoT testing! 🎉"
    echo ""
}

# Run main function
main "$@"
