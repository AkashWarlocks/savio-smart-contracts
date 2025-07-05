// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import {SavioLzManager} from "../src/SavioLzManager.sol";
import {SavioSmartAccountFactory} from "../src/SavioSmartAccountFactory.sol";

contract DeployOApp is Script {
    function run() external {
        // Replace these env vars with your own values
        address endpoint = vm.envAddress("ENDPOINT_ADDRESS");
        address smartAccountFactory = vm.envAddress("SMART_ACCOUNT_FACTORY");
        address owner = vm.envAddress("OWNER_ADDRESS");

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        SavioLzManager oapp = new SavioLzManager(endpoint, owner);
        vm.stopBroadcast();

        console.log("MyOApp deployed to:", address(oapp));
    }
}
