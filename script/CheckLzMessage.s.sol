// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/SimpleLzMessenger.sol";

contract CheckLzMessage is Script {
    function run() external {
        address messengerAddress = vm.envAddress("MESSENGER_ADDRESS");
        console.log("Using messenger at:", messengerAddress);

        SimpleLzMessenger messenger = SimpleLzMessenger(messengerAddress);

        bytes memory receivedBytes = messenger.getLastReceivedBytes();

        console.log("=== Received Message ===");

        if (receivedBytes.length > 0) {
            console.log("Received bytes:", vm.toString(receivedBytes));
            console.log("Bytes length:", receivedBytes.length);
        } else {
            console.log("No message received yet");
        }
    }
}
