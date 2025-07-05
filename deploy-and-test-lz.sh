#!/bin/bash

# LayerZero Cross-Chain Testing Script
# Deploy on Polygon Amoy and Base Sepolia, then test messaging

set -e

echo "=== LayerZero Cross-Chain Testing Setup ==="
echo "This script will:"
echo "1. Deploy contracts on Polygon Amoy"
echo "2. Deploy contracts on Base Sepolia"
echo "3. Test cross-chain messaging from Amoy to Base Sepolia"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if private key is provided
if [ -z "$PRIVATE_KEY" ]; then
    print_warning "PRIVATE_KEY environment variable not set"
    print_status "Using --accounts dev for deployment"
    ACCOUNT_FLAG="--accounts dev"
else
    print_status "Using provided private key"
    ACCOUNT_FLAG="--private-key $PRIVATE_KEY"
fi

# Step 1: Deploy on Polygon Amoy
print_status "Step 1: Deploying on Polygon Amoy..."
print_status "Make sure you're connected to Polygon Amoy network"

# Set RPC URL for Amoy
RPC_URL_AMOY=${RPC_URL_AMOY:-"https://rpc-amoy.polygon.technology"}
print_status "Using Amoy RPC: $RPC_URL_AMOY"

# Deploy on Amoy
print_status "Deploying SavioLzManager on Amoy..."
forge script script/DeployAmoy.s.sol:DeployAmoy \
    --rpc-url $RPC_URL_AMOY \
    $ACCOUNT_FLAG \
    --broadcast \
    --verify

# Extract the LZ Manager address from the deployment output
# You'll need to manually copy this from the output
print_warning "Please copy the LZ_MANAGER_ADDRESS from the deployment output above"
print_status "Then set it as an environment variable:"
print_status "export LZ_MANAGER_ADDRESS=<address_from_output>"

echo ""
read -p "Press Enter after you've set the LZ_MANAGER_ADDRESS environment variable..."

# Step 2: Deploy on Base Sepolia
print_status "Step 2: Deploying on Base Sepolia..."
print_status "Make sure you're connected to Base Sepolia network"

# Set RPC URL for Base Sepolia
RPC_URL_BASE_SEPOLIA=${RPC_URL_BASE_SEPOLIA:-"https://sepolia.base.org"}
print_status "Using Base Sepolia RPC: $RPC_URL_BASE_SEPOLIA"

# Deploy on Base Sepolia
print_status "Deploying SavioLzManager on Base Sepolia..."
forge script script/DeployBaseSepolia.s.sol:DeployBaseSepolia \
    --rpc-url $RPC_URL_BASE_SEPOLIA \
    $ACCOUNT_FLAG \
    --broadcast \
    --verify

# Extract the Base LZ Manager address
print_warning "Please copy the BASE_LZ_MANAGER_ADDRESS from the deployment output above"
print_status "Then set it as an environment variable:"
print_status "export BASE_LZ_MANAGER_ADDRESS=<address_from_output>"

echo ""
read -p "Press Enter after you've set the BASE_LZ_MANAGER_ADDRESS environment variable..."

# Step 3: Test cross-chain messaging
print_status "Step 3: Testing cross-chain messaging from Amoy to Base Sepolia..."

# Check if addresses are set
if [ -z "$LZ_MANAGER_ADDRESS" ]; then
    print_error "LZ_MANAGER_ADDRESS not set"
    exit 1
fi

if [ -z "$BASE_LZ_MANAGER_ADDRESS" ]; then
    print_error "BASE_LZ_MANAGER_ADDRESS not set"
    exit 1
fi

print_status "Sending test message from Amoy to Base Sepolia..."
forge script script/TestCrossChainMessage.s.sol:TestCrossChainMessage \
    --rpc-url $RPC_URL_AMOY \
    $ACCOUNT_FLAG \
    --broadcast

print_success "Message sent! Waiting 30 seconds for cross-chain delivery..."
sleep 30

# Step 4: Check received message on Base Sepolia
print_status "Step 4: Checking received message on Base Sepolia..."
forge script script/CheckReceivedMessage.s.sol:CheckReceivedMessage \
    --rpc-url $RPC_URL_BASE_SEPOLIA \
    $ACCOUNT_FLAG

print_success "Cross-chain testing complete!"
echo ""
print_status "Summary:"
print_status "- Amoy LZ Manager: $LZ_MANAGER_ADDRESS"
print_status "- Base Sepolia LZ Manager: $BASE_LZ_MANAGER_ADDRESS"
print_status "- Message sent from Amoy (EID: 80002) to Base Sepolia (EID: 84532)" 