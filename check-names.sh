#!/bin/bash

# Script to check if IoT Hub and Event Hub names are available

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get prefix from tfvars or use default
PREFIX=${1:-$(grep "project_prefix" terraform.tfvars | cut -d'"' -f2)}

if [ -z "$PREFIX" ]; then
    echo -e "${RED}Error: Could not determine project prefix${NC}"
    echo "Usage: ./check-names.sh <prefix>"
    echo "Example: ./check-names.sh aadil-pi-2026"
    exit 1
fi

echo -e "${BLUE}Checking name availability for prefix: ${YELLOW}${PREFIX}${NC}"
echo ""

# IoT Hub name
IOTHUB_NAME="${PREFIX}-iothub"
echo -e "${BLUE}Checking IoT Hub name:${NC} ${IOTHUB_NAME}"

# Check IoT Hub availability using Azure CLI
IOTHUB_AVAILABLE=$(az iot hub show --name "$IOTHUB_NAME" 2>&1 | grep -q "ResourceNotFound" && echo "true" || echo "false")

if [ "$IOTHUB_AVAILABLE" = "true" ]; then
    echo -e "${GREEN}✓ IoT Hub name is available${NC}"
else
    echo -e "${RED}✗ IoT Hub name is NOT available (already exists or taken)${NC}"
    echo -e "${YELLOW}  Try a different prefix, e.g., ${PREFIX}-$(date +%s | tail -c 5)${NC}"
fi

echo ""

# Event Hub namespace name
EHNS_NAME="${PREFIX}-ehns"
echo -e "${BLUE}Checking Event Hub Namespace:${NC} ${EHNS_NAME}"

EHNS_AVAILABLE=$(az eventhubs namespace exists --name "$EHNS_NAME" --query nameAvailable -o tsv 2>/dev/null || echo "unknown")

if [ "$EHNS_AVAILABLE" = "true" ]; then
    echo -e "${GREEN}✓ Event Hub Namespace name is available${NC}"
elif [ "$EHNS_AVAILABLE" = "false" ]; then
    echo -e "${RED}✗ Event Hub Namespace name is NOT available${NC}"
    echo -e "${YELLOW}  Try a different prefix${NC}"
else
    echo -e "${YELLOW}⚠ Could not check Event Hub Namespace availability${NC}"
fi

echo ""

# DPS name
DPS_NAME="${PREFIX}-dps"
echo -e "${BLUE}Checking DPS name:${NC} ${DPS_NAME}"
echo -e "${YELLOW}⚠ DPS name availability check not available via CLI${NC}"
echo -e "  DPS names must be unique but typically have fewer conflicts"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

if [ "$IOTHUB_AVAILABLE" = "true" ] && [ "$EHNS_AVAILABLE" = "true" ]; then
    echo -e "${GREEN}✓ All names appear to be available!${NC}"
    echo -e "${GREEN}  You can proceed with deployment using prefix: ${YELLOW}${PREFIX}${NC}"
    echo ""
    echo -e "  Update terraform.tfvars:"
    echo -e "  ${YELLOW}project_prefix = \"${PREFIX}\"${NC}"
else
    echo -e "${RED}✗ Some names are not available${NC}"
    echo ""
    echo -e "${YELLOW}Suggestions:${NC}"
    echo -e "  1. Use: ${YELLOW}${PREFIX}-$(date +%s | tail -c 5)${NC} (adds timestamp)"
    echo -e "  2. Use: ${YELLOW}${PREFIX}-dev${NC} or ${YELLOW}${PREFIX}-test${NC}"
    echo -e "  3. Use: ${YELLOW}your-org-$(date +%m%d)${NC}"
    echo ""
    echo -e "  Then update terraform.tfvars with your chosen prefix"
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
