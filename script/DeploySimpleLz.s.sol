// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/SimpleLzMessenger.sol";

contract DeploySimpleLz is Script {
    function run() external {
        uint256 chainId = block.chainid;
        console.log("Deploying SimpleLzMessenger on chain:", chainId);
        console.log("Deployer:", msg.sender);

        // Get endpoint based on chain
        address endpoint;
        if (chainId == 80002) {
            // Polygon Amoy
            endpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
            console.log("Using Amoy endpoint:", endpoint);
        } else if (chainId == 84532) {
            // Base Sepolia
            endpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
            console.log("Using Base Sepolia endpoint:", endpoint);
        } else {
            revert("Unsupported chain");
        }

        vm.startBroadcast();

        SimpleLzMessenger messenger = new SimpleLzMessenger(
            endpoint,
            msg.sender
        );

        vm.stopBroadcast();

        console.log("SimpleLzMessenger deployed at:", address(messenger));
        console.log("Save this address for testing!");
    }
}
