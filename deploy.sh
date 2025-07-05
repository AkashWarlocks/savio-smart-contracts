#!/bin/bash

# Deploy Cross-Chain Smart Account System
echo "🚀 Deploying Cross-Chain Smart Account System"

# Check if private key is set
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY environment variable not set"
    echo "Please set your private key: export PRIVATE_KEY=your_private_key_here"
    exit 1
fi

# Check if RPC URLs are set
if [ -z "$SEPOLIA_RPC_URL" ]; then
    echo "❌ Error: SEPOLIA_RPC_URL environment variable not set"
    exit 1
fi

if [ -z "$BASE_SEPOLIA_RPC_URL" ]; then
    echo "❌ Error: BASE_SEPOLIA_RPC_URL environment variable not set"
    exit 1
fi

echo "📋 Deploying on Sepolia..."
forge script script/Deploy.s.sol:Deploy \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --verify

echo ""
echo "📋 Deploying on Base Sepolia..."
forge script script/Deploy.s.sol:Deploy \
    --rpc-url $BASE_SEPOLIA_RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --verify

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📝 Next steps:"
echo "1. Note the deployed addresses from the output above"
echo "2. Update the addresses in your configuration scripts"
echo "3. Configure cross-chain communication between the LZ Managers"
echo "4. Test the cross-chain smart account deployment" 