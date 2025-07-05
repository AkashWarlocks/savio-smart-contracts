// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/SimpleLzMessenger.sol";

contract SendLzMessage is Script {
    function run() external {
        address messengerAddress = vm.envAddress("MESSENGER_ADDRESS");
        console.log("Using messenger at:", messengerAddress);

        vm.startBroadcast();

        SimpleLzMessenger messenger = SimpleLzMessenger(messengerAddress);

        // Simple test message
        string memory message = "Hello from LayerZero!";
        bytes memory data = abi.encode(message);

        console.log("Sending message:", message);
        console.log("To Base Sepolia (EID: 84532)");

        // Send with some ETH for gas
        messenger.sendBytes{value: 0.001 ether}(
            84532, // Base Sepolia EID
            data
        );

        vm.stopBroadcast();

        console.log("Message sent!");
    }
}
