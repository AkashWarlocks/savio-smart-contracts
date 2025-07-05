// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/SavioSmartAccount.sol";
import "../src/SavioSmartAccountFactory.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "./HelperConfig.s.sol";

/**
 * @title DeploySavioSmartAccount
 * @dev Deployment script for SavioSmartAccount and Factory
 */
contract DeploySavioSmartAccount is Script {
    function run() external {
        console.log("Deploying from address:", msg.sender);
        //  console.log("Deployer balance:", deployer.balance);
        HelperConfig helperConfig = new HelperConfig();

        address entryPoint = helperConfig.getEntryPoint();

        vm.startBroadcast();

        // Deploy EntryPoint (if not already deployed)
        // Note: In production, you would use thex official EntryPoint address
        // For testing, we'll deploy a mock EntryPoint
        console.log("Deploying EntryPoint...");
        // IEntryPoint entryPoint = new EntryPoint(); // Uncomment if you have EntryPoint.sol

        // For now, we'll use a placeholder address
        // In production, use the official EntryPoint address for your target network

        console.log("Using EntryPoint at:", entryPoint);

        // Deploy Factory
        console.log("Deploying SavioSmartAccountFactory...");
        SavioSmartAccountFactory factory = new SavioSmartAccountFactory(
            IEntryPoint(entryPoint)
        );
        console.log("Factory deployed at:", address(factory));

        // Deploy a sample account
        console.log("Creating a sample account...");
        uint256 salt = 12345;
        address owner = msg.sender;

        SavioSmartAccount account = factory.createAccount(owner, salt);
        console.log("Sample account deployed at:", address(account));
        console.log("Account owner:", owner);
        console.log("Account salt:", salt);

        vm.stopBroadcast();

        console.log("Deployment completed successfully!");
        console.log("Factory:", address(factory));
        console.log("Sample Account:", address(account));
    }
}
