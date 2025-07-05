#!/bin/bash

# Create Group Script for Savio Protocol
# Usage: ./create-group.sh <factory_address> <period> <total_members> <pledge_amount> <usdc_token_address>

# Check if all arguments are provided
if [ $# -ne 5 ]; then
    echo "Usage: $0 <factory_address> <period> <total_members> <pledge_amount> <usdc_token_address>"
    echo ""
    echo "Example:"
    echo "  $0 0x1234... 12 10 1000000000 0x1234..."
    echo "  (period: 12, members: 10, pledge: 1000 USDC with 6 decimals)"
    exit 1
fi

FACTORY_ADDRESS=$1
PERIOD=$2
TOTAL_MEMBERS=$3
PLEDGE_AMOUNT=$4
USDC_TOKEN=$5

echo "=== Creating Savio Group ==="
echo "Factory Address: $FACTORY_ADDRESS"
echo "Period: $PERIOD"
echo "Total Members: $TOTAL_MEMBERS"
echo "Pledge Amount: $PLEDGE_AMOUNT (in smallest units)"
echo "USDC Token: $USDC_TOKEN"
echo ""

# Function signature for createGroup
# createGroup(uint256 period, uint256 totalMembers, uint256 pledgeAmount, address usdcToken)
FUNCTION_SIGNATURE="createGroup(uint256,uint256,uint256,address)"

# Encode the function call
ENCODED_DATA=$(cast calldata $FUNCTION_SIGNATURE $PERIOD $TOTAL_MEMBERS $PLEDGE_AMOUNT $USDC_TOKEN)

echo "Encoded data: $ENCODED_DATA"
echo ""

# Send the transaction
echo "Sending transaction..."
cast send \
    --account dev \
    --rpc-url $RPC_URL_AMOY \
    $FACTORY_ADDRESS \
    $ENCODED_DATA

echo ""
echo "Transaction sent! Check your wallet for the transaction hash."
echo ""
echo "To get the group ID and address, you can:"
echo "1. Check the transaction receipt for the SavioCreated event"
echo "2. Or call getTotalGroups() to get the latest group ID"
echo "3. Then call getSavioProtocolAddress(groupId) to get the contract address" 