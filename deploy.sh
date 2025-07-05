#!/bin/bash

# Set your environment variables here
export PRIVATE_KEY="your_private_key_here"
export ENTRY_POINT_ADDRESS="0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"
export RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY"

# Run the deploy script
forge script script/DeploySavioSmartAccount.s.sol --broadcast 