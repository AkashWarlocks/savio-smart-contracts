// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/SavioProtocolFactory.sol";
import "../src/SavioProtocol.sol";
import "./HelperConfig.s.sol";

/**
 * @title Deploy Script
 * @dev Deployment script for Savio Factory and Protocol
 */
contract DeploySavio is Script {
    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getActiveNetworkConfig();

        //uint256 deployerPrivateKey = helperConfig.getDeployerKey();
        // address deployer = helperConfig.getDeployer();
        // address entryPointAddress = helperConfig.getEntryPoint();
        // string memory rpcUrl = helperConfig.getRpcUrl();
        //        uint256 chainId = tx.chainId;
        uint256 chainId = block.chainid;
        // console.log("Chain ID:", chainId);
        console.log("Deploying from address:", msg.sender);
        // console.log("Deployer balance:", deployer.balance);
        //console.log("Using EntryPoint at:", entryPointAddress);
        //console.log("RPC URL configured:", bytes(rpcUrl).length > 0);

        vm.startBroadcast();

        // Chainlink VRF configuration for Sepolia
        address vrfCoordinator;
        bytes32 keyHash;
        uint64 subscriptionId;

        if (chainId == 11155111) {
            // Sepolia
            vrfCoordinator = 0x50Ae5Ea38514bD561F6a60Ea9c48807452bb5Ccf;
            keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
            subscriptionId = 1; // You need to create a subscription and fund it
        } else if (chainId == 1) {
            // Ethereum Mainnet
            vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
            keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
            subscriptionId = 1; // You need to create a subscription and fund it
        } else {
            // Default/Anvil - use mock values
            vrfCoordinator = address(0x123);
            keyHash = bytes32(0);
            subscriptionId = 1;
        }

        console.log("Deploying ROSCA Factory...");
        console.log("VRF Coordinator:", vrfCoordinator);
        console.log("Key Hash:", uint256(keyHash));
        console.log("Subscription ID:", subscriptionId);

        SavioProtocolFactory factory = new SavioProtocolFactory(
            vrfCoordinator,
            keyHash,
            subscriptionId
        );

        console.log("Savio Factory deployed at:", address(factory));

        // Deploy a sample ROSCA group
        console.log("Creating a sample Savio group...");

        // Sample parameters
        uint256 period = 12; // 12 periods
        uint256 totalMembers = 5; // 5 members
        uint256 pledgeAmount = 100 * 10 ** 6; // 100 USDC (6 decimals)

        // USDC address on Sepolia (you'll need to replace with actual USDC address)
        address usdcAddress = networkConfig.usdcAddress; // Sepolia USDC

        (uint256 groupId, address savioGroupAddress) = factory.createGroup(
            period,
            totalMembers,
            pledgeAmount,
            usdcAddress
        );

        console.log("Sample ROSCA group created!");
        console.log("Group ID:", groupId);
        console.log("ROSCA Address:", savioGroupAddress);
        console.log("Period:", period);
        console.log("Total Members:", totalMembers);
        console.log("Pledge Amount:", pledgeAmount);
        console.log("USDC Address:", usdcAddress);

        vm.stopBroadcast();

        console.log("Deployment completed successfully!");
        console.log("Factory:", address(factory));
        console.log("Sample Savio:", savioGroupAddress);
        console.log("Group ID:", groupId);
    }
}
