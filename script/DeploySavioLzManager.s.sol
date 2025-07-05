// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/SavioLzManager.sol";
import "../src/SavioSmartAccountFactory.sol";
import "./HelperConfig.s.sol";

/**
 * @title DeploySavioLzManager Script
 * @dev Deployment script for SavioLzManager and Factory on Sepolia and Base
 */
contract DeploySavioLzManager is Script {
    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getActiveNetworkConfig();

        uint256 chainId = block.chainid;
        console.log("Deploying from address:", msg.sender);
        console.log("Chain ID:", chainId);
        console.log("Network:", networkConfig.name);

        vm.startBroadcast();

        // First deploy the factory
        SavioSmartAccountFactory factory = new SavioSmartAccountFactory(
            IEntryPoint(networkConfig.entryPoint)
        );

        console.log("SavioSmartAccountFactory deployed at:", address(factory));

        // Deploy the LayerZero Manager with factory address
        SavioLzManager lzManager = new SavioLzManager(
            networkConfig.layerZeroEndpoint, // LayerZero EndpointV2 address
            msg.sender // Owner
        );

        console.log("SavioLzManager deployed at:", address(lzManager));

        vm.stopBroadcast();

        // Save deployment addresses
        string memory deploymentInfo = string.concat(
            "Network: ",
            networkConfig.name,
            "\n",
            "Chain ID: ",
            vm.toString(chainId),
            "\n",
            "Factory: ",
            vm.toString(address(factory)),
            "\n",
            "LZ Manager: ",
            vm.toString(address(lzManager)),
            "\n",
            "EntryPoint: ",
            vm.toString(networkConfig.entryPoint),
            "\n",
            "LayerZero Endpoint: ",
            vm.toString(networkConfig.layerZeroEndpoint)
        );

        console.log("Deployment Summary:");
        console.log(deploymentInfo);
    }
}
