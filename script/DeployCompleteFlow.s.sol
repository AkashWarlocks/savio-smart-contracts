// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/SavioLzManager.sol";
import "../src/SavioSmartAccountFactory.sol";
import "./HelperConfig.s.sol";

/**
 * @title DeployCompleteFlow Script
 * @dev Complete deployment script for cross-chain smart account system
 */
contract DeployCompleteFlow is Script {
    // Chain IDs
    uint32 public constant SEPOLIA_EID = 11155111;
    uint32 public constant BASE_SEPOLIA_EID = 84532;

    // Deployment addresses (will be populated during deployment)
    address public sepoliaFactory;
    address public sepoliaLzManager;
    address public baseFactory;
    address public baseLzManager;

    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getActiveNetworkConfig();

        uint256 chainId = block.chainid;
        console.log("=== Complete Cross-Chain Smart Account Deployment ===");
        console.log("Deploying from address:", msg.sender);
        console.log("Chain ID:", chainId);
        console.log("Network:", networkConfig.name);

        vm.startBroadcast();

        // Deploy Factory
        console.log("\n--- Deploying Factory ---");
        SavioSmartAccountFactory factory = new SavioSmartAccountFactory(
            IEntryPoint(networkConfig.entryPoint)
        );
        console.log("Factory deployed at:", address(factory));

        // Deploy LZ Manager
        console.log("\n--- Deploying LayerZero Manager ---");
        SavioLzManager lzManager = new SavioLzManager(
            networkConfig.layerZeroEndpoint,
            msg.sender
        );
        console.log("LZ Manager deployed at:", address(lzManager));

        vm.stopBroadcast();

        // Store addresses based on network
        if (chainId == SEPOLIA_EID) {
            sepoliaFactory = address(factory);
            sepoliaLzManager = address(lzManager);
        } else if (chainId == BASE_SEPOLIA_EID) {
            baseFactory = address(factory);
            baseLzManager = address(lzManager);
        }

        // Display deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("Network:", networkConfig.name);
        console.log("Chain ID:", chainId);
        console.log("Factory:", address(factory));
        console.log("LZ Manager:", address(lzManager));
        console.log("EntryPoint:", networkConfig.entryPoint);
        console.log("LayerZero Endpoint:", networkConfig.layerZeroEndpoint);

        // Save deployment info to file
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
            vm.toString(networkConfig.layerZeroEndpoint),
            "\n"
        );

        // Write to deployment file
        string memory filename = string.concat(
            "deployment_",
            networkConfig.name,
            ".txt"
        );
        vm.writeFile(filename, deploymentInfo);
        console.log("Deployment info saved to:", filename);
    }

    /**
     * @dev Configure cross-chain communication between Sepolia and Base Sepolia
     * This should be called after deploying on both chains
     */
    function configureCrossChain() external {
        // These addresses should be updated with actual deployed addresses
        address sepoliaManager = 0x0000000000000000000000000000000000000000; // Replace
        address baseManager = 0x0000000000000000000000000000000000000000; // Replace

        require(sepoliaManager != address(0), "Sepolia manager not set");
        require(baseManager != address(0), "Base manager not set");

        vm.startBroadcast();

        SavioLzManager sepoliaLz = SavioLzManager(sepoliaManager);
        SavioLzManager baseLz = SavioLzManager(baseManager);

        console.log("Configuring cross-chain communication...");

        // Set peers for cross-chain communication
        sepoliaLz.setPeer(
            BASE_SEPOLIA_EID,
            bytes32(uint256(uint160(baseManager)))
        );
        baseLz.setPeer(SEPOLIA_EID, bytes32(uint256(uint160(sepoliaManager))));

        console.log("Cross-chain configuration complete!");

        vm.stopBroadcast();
    }

    /**
     * @dev Deploy and configure everything in one go (for testing)
     */
    function deployAndConfigure() external {
        // This function would deploy on both chains and configure cross-chain communication
        // In practice, you'd need to run this on each chain separately
        console.log(
            "This function is for demonstration. Run 'run()' on each chain separately."
        );
    }
}
