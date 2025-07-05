// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {SavioProtocolFactory} from "../src/SavioProtocolFactory.sol";
import {SavioProtocol} from "../src/SavioProtocol.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {MockVRFCoordinator} from "../src/mocks/MockVRFCoordinator.sol";

contract BasicPositiveTest is Test {
    SavioProtocolFactory public factory;
    SavioProtocol public protocol;
    MockUSDC public mockUSDC;
    MockVRFCoordinator public mockVRFCoordinator;

    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

    uint256 public constant PERIOD = 3;
    uint256 public constant TOTAL_MEMBERS = 3;
    uint256 public constant PLEDGE_AMOUNT = 100 * 10 ** 6; // 100 USDC
    uint256 public constant COLLATERAL = PERIOD * PLEDGE_AMOUNT; // 300 USDC

    bytes32 public constant KEY_HASH =
        bytes32(
            0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
        );
    uint64 public subscriptionId;

    function setUp() public {
        // Deploy mock contracts
        mockUSDC = new MockUSDC();
        mockVRFCoordinator = new MockVRFCoordinator();

        // Create VRF subscription
        subscriptionId = mockVRFCoordinator.createSubscription();

        // Deploy factory
        factory = new SavioProtocolFactory(
            address(mockVRFCoordinator),
            KEY_HASH,
            subscriptionId
        );

        // Deploy protocol through factory
        (uint256 groupId, address protocolAddress) = factory.createGroup(
            PERIOD,
            TOTAL_MEMBERS,
            PLEDGE_AMOUNT,
            address(mockUSDC)
        );

        protocol = SavioProtocol(protocolAddress);

        // Mint USDC to test accounts
        mockUSDC.mint(alice, 10000 * 10 ** 6);
        mockUSDC.mint(bob, 10000 * 10 ** 6);
        mockUSDC.mint(charlie, 10000 * 10 ** 6);

        // Approve USDC spending
        vm.prank(alice);
        mockUSDC.approve(address(protocol), type(uint256).max);
        vm.prank(bob);
        mockUSDC.approve(address(protocol), type(uint256).max);
        vm.prank(charlie);
        mockUSDC.approve(address(protocol), type(uint256).max);
    }

    function test_BasicPositiveFlow() public {
        console.log("=== Starting Basic Positive Flow Test ===");

        // Step 1: Verify initial state
        assertEq(protocol.period(), PERIOD, "Period should be correct");
        assertEq(
            protocol.totalMembers(),
            TOTAL_MEMBERS,
            "Total members should be correct"
        );
        assertEq(
            protocol.pledgeAmount(),
            PLEDGE_AMOUNT,
            "Pledge amount should be correct"
        );
        assertTrue(protocol.isActive(), "Protocol should be active");
        assertEq(protocol.memberCount(), 0, "Should start with 0 members");

        console.log("Initial state verified");

        // Step 2: Alice joins
        vm.prank(alice);
        protocol.join(COLLATERAL);

        assertTrue(protocol.isMember(alice), "Alice should be a member");
        assertEq(protocol.memberCount(), 1, "Member count should be 1");
        assertEq(protocol.memberIndex(alice), 0, "Alice should have index 0");
        assertEq(
            mockUSDC.balanceOf(address(protocol)),
            COLLATERAL,
            "Protocol should have Alice's collateral"
        );

        console.log("Alice joined successfully");

        // Step 3: Bob joins
        vm.prank(bob);
        protocol.join(COLLATERAL);

        assertTrue(protocol.isMember(bob), "Bob should be a member");
        assertEq(protocol.memberCount(), 2, "Member count should be 2");
        assertEq(protocol.memberIndex(bob), 1, "Bob should have index 1");
        assertEq(
            mockUSDC.balanceOf(address(protocol)),
            COLLATERAL * 2,
            "Protocol should have both collaterals"
        );

        console.log("Bob joined successfully");

        // Step 4: Charlie joins (completes the group)
        vm.prank(charlie);
        protocol.join(COLLATERAL);

        assertTrue(protocol.isMember(charlie), "Charlie should be a member");
        assertEq(protocol.memberCount(), 3, "Member count should be 3");
        assertEq(
            protocol.memberIndex(charlie),
            2,
            "Charlie should have index 2"
        );
        assertEq(
            mockUSDC.balanceOf(address(protocol)),
            COLLATERAL * 3,
            "Protocol should have all collaterals"
        );

        console.log("Charlie joined successfully - Group is now full!");

        // Step 5: Verify all members are tracked correctly
        address[] memory members = protocol.getAllMembers();
        assertEq(members.length, 3, "Should have 3 members");
        assertEq(members[0], alice, "First member should be Alice");
        assertEq(members[1], bob, "Second member should be Bob");
        assertEq(members[2], charlie, "Third member should be Charlie");

        console.log("All members tracked correctly");

        // Step 6: Start first round - Alice contributes
        vm.prank(alice);
        protocol.contribute(PLEDGE_AMOUNT); // Just pledge amount, no bid

        assertTrue(
            protocol.hasContributed(1, alice),
            "Alice should have contributed to round 1"
        );
        assertEq(
            protocol.getContributionCount(),
            1,
            "Contribution count should be 1"
        );
        assertEq(
            protocol.roundTotalContribution(1),
            PLEDGE_AMOUNT,
            "Round 1 total should be pledge amount"
        );

        console.log("Alice contributed to round 1");

        // Step 7: Bob contributes with a bid (pledge + bid)
        vm.prank(bob);
        protocol.contribute(PLEDGE_AMOUNT + 10 * 10 ** 6); // Pledge + 10 USDC bid

        assertTrue(
            protocol.hasContributed(1, bob),
            "Bob should have contributed to round 1"
        );
        assertEq(
            protocol.getContributionCount(),
            2,
            "Contribution count should be 2"
        );
        assertEq(
            protocol.roundTotalContribution(1),
            PLEDGE_AMOUNT * 2 + 10 * 10 ** 6,
            "Round 1 total should include bid"
        );
        assertEq(
            protocol.highestBid(),
            10 * 10 ** 6,
            "Highest bid should be 10 USDC"
        );
        assertEq(protocol.highestBidder(), bob, "Bob should be highest bidder");

        console.log("Bob contributed with bid");

        // Step 8: Charlie contributes (completes the round)
        vm.prank(charlie);
        protocol.contribute(PLEDGE_AMOUNT); // Just pledge amount, no bid

        // assertTrue(
        //     protocol.hasContributed(1, charlie),
        //     "Charlie should have contributed to round 1"
        // );
        // assertEq(
        //     protocol.getContributionCount(),
        //     3,
        //     "Contribution count should be 3"
        // );
        // assertEq(
        //     protocol.roundTotalContribution(1),
        //     PLEDGE_AMOUNT * 3,
        //     "Round 1 total should be 3x pledge amount"
        // );

        console.log("Charlie contributed - Round 1 complete!");

        // Step 9: Verify round completion
        assertEq(protocol.roundWinner(1), bob, "Bob should win round 1");
        assertTrue(protocol.hasWon(bob), "Bob should be marked as winner");
        assertEq(protocol.currentRound(), 2, "Should move to round 2");

        console.log("Round 1 completed - Bob won!");

        // Step 10: Check bid distribution
        // Alice and Charlie should have received their bid shares automatically
        // 10 USDC bid - 20% protocol fee = 8 USDC to distribute
        // 8 USDC / 2 eligible losers = 4 USDC each
        uint256 expectedBidShare = (10 * 10 ** 6 * 80) / 100 / 2; // 4 USDC each

        // Calculate expected balances:
        // Initial: 10000 * 10**6
        // - Collateral: COLLATERAL (300 * 10**6)
        // - Pledge: PLEDGE_AMOUNT (100 * 10**6)
        // + Bid share: expectedBidShare (4 * 10**6)
        uint256 expectedAliceBalance = 10000 *
            10 ** 6 -
            COLLATERAL -
            PLEDGE_AMOUNT +
            expectedBidShare;
        uint256 expectedCharlieBalance = 10000 *
            10 ** 6 -
            COLLATERAL -
            PLEDGE_AMOUNT +
            expectedBidShare;

        assertEq(
            mockUSDC.balanceOf(alice),
            expectedAliceBalance,
            "Alice should receive bid share"
        );
        assertEq(
            mockUSDC.balanceOf(charlie),
            expectedCharlieBalance,
            "Charlie should receive bid share"
        );

        console.log(
            "Bid distribution completed - Alice and Charlie received shares"
        );

        // Step 11: Bob's winnings were automatically transferred
        // Bob's expected balance after round 1:
        // Initial: 10000 * 10**6
        // - Collateral: COLLATERAL (300 * 10**6)
        // - Pledge: PLEDGE_AMOUNT (100 * 10**6)
        // - Bid: 10 * 10**6
        // + Winnings: PLEDGE_AMOUNT * 3 (300 * 10**6)
        uint256 expectedBobBalanceAfterRound1 = 10000 *
            10 ** 6 -
            COLLATERAL -
            PLEDGE_AMOUNT -
            10 *
            10 ** 6 +
            PLEDGE_AMOUNT *
            3;

        uint256 bobBalanceAfterRound1 = mockUSDC.balanceOf(bob);
        assertEq(
            bobBalanceAfterRound1,
            expectedBobBalanceAfterRound1,
            "Bob should have correct balance after automatic withdrawal"
        );

        console.log("Bob received winnings automatically");

        // Step 12: Start Round 2 - Alice contributes with bid
        vm.prank(alice);
        protocol.contribute(PLEDGE_AMOUNT + 15 * 10 ** 6); // Pledge + 15 USDC bid

        assertTrue(
            protocol.hasContributed(2, alice),
            "Alice should have contributed to round 2"
        );
        assertEq(
            protocol.getContributionCount(),
            1,
            "Contribution count should reset to 1 for round 2"
        );
        assertEq(
            protocol.roundTotalContribution(2),
            PLEDGE_AMOUNT + 15 * 10 ** 6,
            "Round 2 total should include Alice's bid"
        );
        assertEq(
            protocol.highestBid(),
            15 * 10 ** 6,
            "Highest bid should be 15 USDC"
        );
        assertEq(
            protocol.highestBidder(),
            alice,
            "Alice should be highest bidder"
        );

        console.log("Alice contributed to round 2 with bid");

        // Step 13: Bob contributes (no bid since he already won)
        vm.prank(bob);
        protocol.contribute(PLEDGE_AMOUNT); // Just pledge amount, no bid

        assertTrue(
            protocol.hasContributed(2, bob),
            "Bob should have contributed to round 2"
        );
        assertEq(
            protocol.getContributionCount(),
            2,
            "Contribution count should be 2"
        );
        assertEq(
            protocol.roundTotalContribution(2),
            PLEDGE_AMOUNT * 2 + 15 * 10 ** 6,
            "Round 2 total should include bid"
        );

        console.log("Bob contributed to round 2");

        // Step 14: Charlie contributes (completes round 2)
        vm.prank(charlie);
        protocol.contribute(PLEDGE_AMOUNT); // Just pledge amount, no bid

        console.log("Charlie contributed - Round 2 complete!");

        // Step 15: Verify round 2 completion
        assertEq(protocol.roundWinner(2), alice, "Alice should win round 2");
        assertTrue(protocol.hasWon(alice), "Alice should be marked as winner");
        assertEq(protocol.currentRound(), 3, "Should move to round 3");

        console.log("Round 2 completed - Alice won!");

        // Step 16: Check round 2 bid distribution
        // Only Charlie should receive bid shares since Bob already won round 1
        // 15 USDC bid - 20% protocol fee = 12 USDC to distribute
        // 12 USDC / 1 eligible loser = 12 USDC to Charlie
        uint256 expectedBidShareRound2 = (15 * 10 ** 6 * 80) / 100; // 12 USDC to Charlie

        // Bob's expected balance after round 2:
        // Previous: 9,890,000,000 (after round 1 withdrawal)
        // - Pledge: PLEDGE_AMOUNT (100 * 10**6)
        // No bid share since Bob already won round 1
        uint256 expectedBobBalanceRound2 = 9890000000 - PLEDGE_AMOUNT;
        uint256 expectedCharlieBalanceRound2 = expectedCharlieBalance -
            PLEDGE_AMOUNT +
            expectedBidShareRound2;

        assertEq(
            mockUSDC.balanceOf(bob),
            expectedBobBalanceRound2,
            "Bob should not receive bid share since he already won round 1"
        );
        assertEq(
            mockUSDC.balanceOf(charlie),
            expectedCharlieBalanceRound2,
            "Charlie should receive bid share from round 2"
        );

        console.log("Round 2 bid distribution completed");

        // Step 17: Alice's round 2 winnings were automatically transferred
        // Alice's expected balance after round 2:
        // Previous: expectedAliceBalance (after round 1 bid share)
        // - Pledge: PLEDGE_AMOUNT (100 * 10**6)
        // - Bid: 15 * 10**6
        // + Winnings: PLEDGE_AMOUNT * 3 (300 * 10**6)
        uint256 expectedAliceBalanceAfterRound2 = expectedAliceBalance -
            PLEDGE_AMOUNT -
            15 *
            10 ** 6 +
            PLEDGE_AMOUNT *
            3;

        uint256 aliceBalanceAfterRound2 = mockUSDC.balanceOf(alice);
        assertEq(
            aliceBalanceAfterRound2,
            expectedAliceBalanceAfterRound2,
            "Alice should have correct balance after automatic withdrawal"
        );

        console.log("Alice received round 2 winnings automatically");

        // Step 18: Start Round 3 - Charlie contributes (no bid needed in last round)
        vm.prank(charlie);
        protocol.contribute(PLEDGE_AMOUNT); // Just pledge amount, no bid

        assertTrue(
            protocol.hasContributed(3, charlie),
            "Charlie should have contributed to round 3"
        );
        assertEq(
            protocol.getContributionCount(),
            1,
            "Contribution count should reset to 1 for round 3"
        );
        assertEq(
            protocol.roundTotalContribution(3),
            PLEDGE_AMOUNT,
            "Round 3 total should be just pledge amount"
        );

        console.log("Charlie contributed to round 3 (no bid needed)");

        // Step 19: Bob contributes (no bid since he already won)
        vm.prank(bob);
        protocol.contribute(PLEDGE_AMOUNT); // Just pledge amount, no bid

        assertTrue(
            protocol.hasContributed(3, bob),
            "Bob should have contributed to round 3"
        );
        assertEq(
            protocol.getContributionCount(),
            2,
            "Contribution count should be 2"
        );

        console.log("Bob contributed to round 3");

        // Step 20: Alice contributes (no bid since she already won)
        vm.prank(alice);
        protocol.contribute(PLEDGE_AMOUNT); // Just pledge amount, no bid

        console.log("Alice contributed - Round 3 complete!");

        // Step 21: Verify round 3 completion
        assertEq(
            protocol.roundWinner(3),
            charlie,
            "Charlie should win round 3"
        );
        assertTrue(
            protocol.hasWon(charlie),
            "Charlie should be marked as winner"
        );
        assertEq(protocol.currentRound(), 4, "Should complete after round 3");

        console.log("Round 3 completed - Charlie won!");

        // Step 22: Check round 3 (no bid distribution since no bid was placed)
        // After round 3 completes, collateral is automatically returned
        // Bob's expected balance after round 3 + collateral return:
        // Previous: 9,790,000,000 (after round 2 contribution)
        // - Pledge: PLEDGE_AMOUNT (100 * 10**6)
        // + Collateral: 300,000,000 (automatic return)
        uint256 expectedBobBalanceRound3 = 9790000000 -
            PLEDGE_AMOUNT +
            300000000;
        // Alice's expected balance after round 3 + collateral return:
        // Previous: expectedAliceBalanceAfterRound2 (after round 2 automatic withdrawal)
        // - Pledge: PLEDGE_AMOUNT (100 * 10**6)
        // + Collateral: 300,000,000 (automatic return)
        uint256 expectedAliceBalanceRound3 = expectedAliceBalanceAfterRound2 -
            PLEDGE_AMOUNT +
            300000000;

        assertEq(
            mockUSDC.balanceOf(bob),
            expectedBobBalanceRound3,
            "Bob should have correct balance after round 3 + collateral return"
        );
        assertEq(
            mockUSDC.balanceOf(alice),
            expectedAliceBalanceRound3,
            "Alice should have correct balance after round 3 + collateral return"
        );

        console.log(
            "Bob balance after round 3:",
            mockUSDC.balanceOf(bob) / 10 ** 6,
            "USDC"
        );
        console.log(
            "Alice balance after round 3:",
            mockUSDC.balanceOf(alice) / 10 ** 6,
            "USDC"
        );

        console.log("Round 3 completed (no bid distribution)");

        // Step 23: Verify group is now complete
        assertFalse(
            protocol.isActive(),
            "Group should be inactive after round 3"
        );
        console.log("Group is now complete and inactive");

        // Step 24: Charlie's round 3 winnings were automatically transferred
        // Charlie's expected balance after round 3:
        // Previous: 9,516,000,000 (after round 2 bid share)
        // - Pledge: 100,000,000 (100 USDC)
        // + Winnings: 300,000,000 (300 USDC)
        // + Collateral: 300,000,000 (300 USDC) - automatically returned
        // = 10,016,000,000 (10,016 USDC)
        uint256 expectedCharlieBalanceAfterRound3 = 10016000000;

        uint256 charlieBalanceAfterRound3 = mockUSDC.balanceOf(charlie);
        assertEq(
            charlieBalanceAfterRound3,
            expectedCharlieBalanceAfterRound3,
            "Charlie should have correct balance after automatic withdrawal"
        );

        console.log("Charlie received round 3 winnings automatically");
        console.log(
            "Charlie balance after round 3:",
            charlieBalanceAfterRound3 / 10 ** 6,
            "USDC"
        );

        // Step 25: Collateral was automatically returned when group completed
        console.log("Collateral automatically returned to all members");

        // Step 26: Check total protocol earnings
        // Round 1: 10 USDC bid * 20% = 2 USDC
        // Round 2: 15 USDC bid * 20% = 3 USDC
        // Round 3: No bid (last round)
        // Total: 2 + 3 = 5 USDC
        uint256 totalProtocolEarnings = 2 * 10 ** 6 + 3 * 10 ** 6; // 5 USDC

        // After returnCollateral(), the protocol should have only bid earnings (5 USDC)
        // Each member gets back their original collateral (300 USDC)
        assertEq(
            mockUSDC.balanceOf(address(protocol)),
            totalProtocolEarnings,
            "Protocol should have only bid earnings after returning collateral"
        );

        console.log("=== All Rounds Completed Successfully! ===");
        console.log(
            "Protocol balance:",
            mockUSDC.balanceOf(address(protocol)) / 10 ** 6,
            "USDC"
        );
        console.log(
            "Total Protocol Earnings:",
            totalProtocolEarnings / 10 ** 6,
            "USDC"
        );
        console.log("Round 1 Winner: Bob (10 USDC bid)");
        console.log("Round 2 Winner: Alice (15 USDC bid)");
        console.log("Round 3 Winner: Charlie (no bid - last round)");

        // Final balance summary for all users
        console.log("\n=== FINAL BALANCE SUMMARY ===");

        // Bob's summary
        uint256 bobFinalBalance = mockUSDC.balanceOf(bob) / 10 ** 6;
        console.log("BOB:");
        console.log("  Final Balance:", bobFinalBalance, "USDC");
        console.log("  Initial Balance: 10,000 USDC");
        console.log("  Collateral Paid: 300 USDC");
        console.log("  Total Pledges: 300 USDC (3 rounds x 100 USDC)");
        console.log("  Bid Amount: 10 USDC (Round 1)");
        console.log("  Winnings: 300 USDC (Round 1 winner)");
        console.log("  Bid Shares Received: 0 USDC (already won)");
        console.log("  Collateral Returned: 300 USDC");
        if (bobFinalBalance >= 10000) {
            console.log("  Net Position: +", bobFinalBalance - 10000, "USDC");
        } else {
            console.log("  Net Position: -", 10000 - bobFinalBalance, "USDC");
        }

        // Alice's summary
        uint256 aliceFinalBalance = mockUSDC.balanceOf(alice) / 10 ** 6;
        console.log("\nALICE:");
        console.log("  Final Balance:", aliceFinalBalance, "USDC");
        console.log("  Initial Balance: 10,000 USDC");
        console.log("  Collateral Paid: 300 USDC");
        console.log("  Total Pledges: 300 USDC (3 rounds X 100 USDC)");
        console.log("  Bid Amount: 15 USDC (Round 2)");
        console.log("  Winnings: 300 USDC (Round 2 winner)");
        console.log("  Bid Shares Received: 4 USDC (Round 1)");
        console.log("  Collateral Returned: 300 USDC");
        if (aliceFinalBalance >= 10000) {
            console.log("  Net Position: +", aliceFinalBalance - 10000, "USDC");
        } else {
            console.log("  Net Position: -", 10000 - aliceFinalBalance, "USDC");
        }

        // Charlie's summary
        uint256 charlieFinalBalance = mockUSDC.balanceOf(charlie) / 10 ** 6;
        console.log("\nCHARLIE:");
        console.log("  Final Balance:", charlieFinalBalance, "USDC");
        console.log("  Initial Balance: 10,000 USDC");
        console.log("  Collateral Paid: 300 USDC");
        console.log("  Total Pledges: 300 USDC (3 rounds X 100 USDC)");
        console.log("  Bid Amount: 0 USDC (no bids)");
        console.log("  Winnings: 300 USDC (Round 3 winner)");
        console.log(
            "  Bid Shares Received: 16 USDC (4 + 12 from rounds 1 & 2)"
        );
        console.log("  Collateral Returned: 300 USDC");
        if (charlieFinalBalance >= 10000) {
            console.log(
                "  Net Position: +",
                charlieFinalBalance - 10000,
                "USDC"
            );
        } else {
            console.log(
                "  Net Position: -",
                10000 - charlieFinalBalance,
                "USDC"
            );
        }

        console.log(
            "\n=== Basic Positive Flow Test Completed Successfully! ==="
        );
        console.log("Factory Address:", address(factory));
        console.log("Protocol Address:", address(protocol));
        console.log("Group ID: 1");
    }
}
