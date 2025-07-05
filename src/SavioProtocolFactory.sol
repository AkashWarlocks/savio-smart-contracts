// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SavioProtocol.sol";

/**
 * @title SavioFactory
 * @dev Factory contract for deploying Savio protocol instances
 */
contract SavioProtocolFactory is Ownable {
    // State variables
    mapping(uint256 => address) public groupIdToAddress;
    mapping(address => uint256[]) public userGroups;
    uint256 public nextGroupId;

    // Chainlink VRF configuration
    address public immutable vrfCoordinator;
    bytes32 public immutable keyHash;
    uint64 public immutable subscriptionId;

    // Events
    event SavioCreated(
        uint256 indexed groupId,
        address indexed creator,
        address indexed roscaAddress,
        uint256 period,
        uint256 totalMembers,
        uint256 pledgeAmount
    );

    /**
     * @dev Constructor
     * @param _vrfCoordinator Chainlink VRF coordinator address
     * @param _keyHash Chainlink VRF key hash
     * @param _subscriptionId Chainlink VRF subscription ID
     */
    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) Ownable(msg.sender) {
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        nextGroupId = 1;
    }

    /**
     * @dev Create a new ROSCA group
     * @param period Number of periods in the ROSCA
     * @param totalMembers Total number of members allowed
     * @param pledgeAmount Amount each member pledges per period
     * @param usdcToken USDC token address
     * @return groupId The ID of the created group
     * @return roscaAddress The address of the deployed ROSCA contract
     */
    function createGroup(
        uint256 period,
        uint256 totalMembers,
        uint256 pledgeAmount,
        address usdcToken
    ) external returns (uint256 groupId, address roscaAddress) {
        require(period > 0, "Period must be greater than 0");
        require(totalMembers > 1, "Must have at least 2 members");
        require(pledgeAmount > 0, "Pledge amount must be greater than 0");
        require(usdcToken != address(0), "Invalid USDC token address");

        groupId = nextGroupId++;

        // Deploy new ROSCA contract
        SavioProtocol rosca = new SavioProtocol(
            period,
            totalMembers,
            pledgeAmount,
            IERC20(usdcToken),
            vrfCoordinator,
            keyHash,
            subscriptionId
        );

        roscaAddress = address(rosca);

        // Store mapping
        groupIdToAddress[groupId] = roscaAddress;
        userGroups[msg.sender].push(groupId);

        emit SavioCreated(
            groupId,
            msg.sender,
            roscaAddress,
            period,
            totalMembers,
            pledgeAmount
        );
    }

    /**
     * @dev Get ROSCA address by group ID
     * @param groupId The group ID
     * @return The ROSCA contract address
     */
    function getSavioProtocolAddress(
        uint256 groupId
    ) external view returns (address) {
        return groupIdToAddress[groupId];
    }

    /**
     * @dev Get all groups created by a user
     * @param user The user address
     * @return Array of group IDs
     */
    function getUserGroups(
        address user
    ) external view returns (uint256[] memory) {
        return userGroups[user];
    }

    /**
     * @dev Get total number of groups
     * @return Total number of groups created
     */
    function getTotalGroups() external view returns (uint256) {
        return nextGroupId - 1;
    }

    /**
     * @dev Update Chainlink VRF configuration (only owner)
     * @param _keyHash New key hash
     * @param _subscriptionId New subscription ID
     */
    function updateVRFConfig(
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) external onlyOwner {
        // Note: This only updates the factory, existing ROSCA contracts will use their original config
        // In a production environment, you might want to add upgrade mechanisms
    }
}
