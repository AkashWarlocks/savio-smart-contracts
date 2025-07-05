#!/bin/bash

echo "=== Simple LayerZero Test ==="
echo ""

# Set RPC URLs
RPC_URL_AMOY=${RPC_URL_AMOY:-"https://polygon-amoy.g.alchemy.com/v2/kI50LwtkApaBKw_C6Q8GVZbiPbrjfq91"}
RPC_URL_BASE_SEPOLIA=${RPC_URL_BASE_SEPOLIA:-"https://base-sepolia.g.alchemy.com/v2/kI50LwtkApaBKw_C6Q8GVZbiPbrjfq91"}

echo "Step 1: Deploy on Amoy"
echo "Deploying SimpleLzMessenger on Polygon Amoy..."
forge script script/DeploySimpleLz.s.sol:DeploySimpleLz \
    --rpc-url $RPC_URL_AMOY \
    --accounts dev \
    --broadcast -vvvv

echo ""
echo "Copy the deployed address above and set:"
echo "export AMOY_MESSENGER_ADDRESS=<address>"
echo ""
read -p "Press Enter after setting AMOY_MESSENGER_ADDRESS..."

echo ""
echo "Step 2: Deploy on Base Sepolia"
echo "Deploying SimpleLzMessenger on Base Sepolia..."
forge script script/DeploySimpleLz.s.sol:DeploySimpleLz \
    --rpc-url $RPC_URL_BASE_SEPOLIA \
    --accounts dev \
    --broadcast -vvvv

echo ""
echo "Copy the deployed address above and set:"
echo "export BASE_MESSENGER_ADDRESS=<address>"
echo ""
read -p "Press Enter after setting BASE_MESSENGER_ADDRESS..."

echo ""
echo "Step 3: Send message from Amoy to Base Sepolia"
export MESSENGER_ADDRESS=$AMOY_MESSENGER_ADDRESS
forge script script/SendLzMessage.s.sol:SendLzMessage \
    --rpc-url $RPC_URL_AMOY \
    --accounts dev \
    --broadcast -vvvv

echo ""
echo "Step 4: Wait 30 seconds for cross-chain delivery..."
sleep 30

echo ""
echo "Step 5: Check received message on Base Sepolia"
export MESSENGER_ADDRESS=$BASE_MESSENGER_ADDRESS
forge script script/CheckLzMessage.s.sol:CheckLzMessage \
    --rpc-url $RPC_URL_BASE_SEPOLIA \
    --accounts dev -vvvv

echo ""
echo "Test complete!" 