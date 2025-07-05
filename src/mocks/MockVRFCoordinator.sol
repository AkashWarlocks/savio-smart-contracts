// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

/**
 * @title MockVRFCoordinator
 * @dev Simple wrapper around Chainlink's VRFCoordinatorV2Mock for easier access
 */
contract MockVRFCoordinator is VRFCoordinatorV2Mock {
    constructor()
        VRFCoordinatorV2Mock(100000000000000000, 1000000000000000000)
    {
        // Initialize with 0.1 LINK base fee and 1 LINK gas price
    }
}
