// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {SavioProtocolFactory} from "../src/SavioProtocolFactory.sol";
import {SavioProtocol} from "../src/SavioProtocol.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {MockVRFCoordinator} from "../src/mocks/MockVRFCoordinator.sol";

contract BasicDeployTest is Test {
    SavioProtocolFactory public factory;
    MockUSDC public mockUSDC;
    MockVRFCoordinator public mockVRFCoordinator;

    bytes32 public constant KEY_HASH =
        bytes32(
            0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
        );
    uint64 public constant SUBSCRIPTION_ID = 1;

    function test_DeployFactoryAndProtocol() public {
        // 1. Deploy mock contracts
        mockUSDC = new MockUSDC();
        mockVRFCoordinator = new MockVRFCoordinator();

        // 2. Create VRF subscription
        uint64 subSId = mockVRFCoordinator.createSubscription();

        // 3. Deploy factory
        factory = new SavioProtocolFactory(
            address(mockVRFCoordinator),
            KEY_HASH,
            subSId
        );

        // 4. Deploy protocol through factory
        (uint256 groupId, address roscaAddress) = factory.createGroup(
            4, // period
            4, // totalMembers
            100 * 10 ** 6, // pledgeAmount (100 USDC)
            address(mockUSDC)
        );

        // 5. Verify deployment
        assertEq(groupId, 1, "Group ID should be 1");
        assertTrue(
            roscaAddress != address(0),
            "Protocol address should not be zero"
        );
        assertEq(
            factory.groupIdToAddress(groupId),
            roscaAddress,
            "Factory should track the protocol address"
        );

        // 6. Verify protocol was deployed correctly
        SavioProtocol protocol = SavioProtocol(roscaAddress);
        assertEq(protocol.period(), 4, "Period should be 4");
        assertEq(protocol.totalMembers(), 4, "Total members should be 4");
        assertEq(
            protocol.pledgeAmount(),
            100 * 10 ** 6,
            "Pledge amount should be 100 USDC"
        );
        assertEq(
            address(protocol.usdcToken()),
            address(mockUSDC),
            "USDC token should match"
        );
        assertTrue(protocol.isActive(), "Protocol should be active");

        console.log("Factory deployed successfully");
        console.log("Protocol deployed successfully through factory");
        console.log("Group ID:", groupId);
        console.log("Protocol Address:", roscaAddress);
    }
}
