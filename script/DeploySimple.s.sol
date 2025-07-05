// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/SavioSmartAccountFactory.sol";
import "../src/SavioLzManager.sol";
import "./HelperConfig.s.sol";

contract DeploySimple is Script {
    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getActiveNetworkConfig();

        console.log("=== Simple Deployment ===");
        console.log("Network:", networkConfig.name);
        console.log("EntryPoint:", networkConfig.entryPoint);
        console.log("LayerZero Endpoint:", networkConfig.layerZeroEndpoint);

        vm.startBroadcast();

        // Deploy Factory
        console.log("Deploying Factory...");
        SavioSmartAccountFactory factory = new SavioSmartAccountFactory(
            IEntryPoint(networkConfig.entryPoint)
        );
        console.log("Factory deployed at:", address(factory));

        // Deploy LZ Manager
        console.log("Deploying LayerZero Manager...");
        SavioLzManager manager = new SavioLzManager(
            networkConfig.layerZeroEndpoint,
            msg.sender
        );
        console.log("Manager deployed at:", address(manager));

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("Factory:", address(factory));
        console.log("Manager:", address(manager));
        console.log("Update these addresses in SimpleCrossChainFlow.s.sol");
    }
}
