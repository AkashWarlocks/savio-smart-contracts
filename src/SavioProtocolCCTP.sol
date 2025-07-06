// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@evm-cctp-contracts/contracts/interfaces/IMessageTransmitter.sol";
import "@evm-cctp-contracts/contracts/interfaces/ITokenMinter.sol";

/**
 * @title SavioProtocolCCTP
 * @dev Cross-chain saving protocol using Circle's CCTP for cross-chain interactions
 */
contract SavioProtocolCCTP is ReentrancyGuard, Ownable, Pausable {
    using Counters for Counters.Counter;

    // CCTP interfaces
    ITokenMinter public tokenMinter;
    IMessageTransmitter public messageTransmitter;

    // USDC token
    IERC20 public usdcToken;

    // Chain configuration
    uint32 public immutable sourceDomain;
    mapping(uint32 => bool) public supportedDomains;

    // Saving state
    struct Member {
        address userAddress;
        uint32 sourceChainId;
        bool isActive;
        uint256 contributionAmount;
        uint256 lastContribution;
        bool hasWithdrawn;
    }

    struct Saving {
        uint256 groupId;
        address creator;
        uint256 period;
        uint256 totalMembers;
        uint256 pledgeAmount;
        uint256 currentRound;
        uint256 totalContributed;
        uint256 startTime;
        bool isActive;
        mapping(address => Member) members;
        address[] memberAddresses;
        uint256[] roundWinners;
        mapping(uint256 => address) roundWinnerAddresses;
        mapping(uint256 => uint256) roundContributions;
    }

    // State variables
    Counters.Counter private _groupIdCounter;
    mapping(uint256 => Saving) public savings;
    mapping(address => uint256[]) public userGroups;
    mapping(bytes32 => bool) public processedMessages;

    // Events
    event SavingCreated(
        uint256 indexed groupId,
        address indexed creator,
        uint256 period,
        uint256 totalMembers,
        uint256 pledgeAmount
    );

    event MemberJoined(
        uint256 indexed groupId,
        address indexed member,
        uint32 sourceChainId
    );

    event ContributionMade(
        uint256 indexed groupId,
        address indexed member,
        uint256 amount,
        uint32 sourceChainId
    );

    event RoundCompleted(
        uint256 indexed groupId,
        uint256 round,
        address indexed winner,
        uint256 amount
    );

    event CrossChainWithdrawal(
        uint256 indexed groupId,
        address indexed member,
        uint256 amount,
        uint32 targetDomain
    );

    event CrossChainContribution(
        uint256 indexed groupId,
        address indexed member,
        uint256 amount,
        uint32 sourceDomain
    );

    // Errors
    error SavingNotFound();
    error MemberAlreadyExists();
    error MemberNotFound();
    error InvalidContributionAmount();
    error RoundNotComplete();
    error InsufficientBalance();
    error UnsupportedDomain();
    error MessageAlreadyProcessed();
    error InvalidMessage();

    /**
     * @dev Constructor
     * @param _usdcToken USDC token address
     * @param _tokenMinter CCTP TokenMinter address
     * @param _messageTransmitter CCTP MessageTransmitter address
     * @param _sourceDomain Source domain for this chain
     */
    constructor(
        address _usdcToken,
        address _tokenMinter,
        address _messageTransmitter,
        uint32 _sourceDomain
    ) {
        usdcToken = IERC20(_usdcToken);
        tokenMinter = ITokenMinter(_tokenMinter);
        messageTransmitter = IMessageTransmitter(_messageTransmitter);
        sourceDomain = _sourceDomain;

        // Add this domain as supported
        supportedDomains[_sourceDomain] = true;
    }

    /**
     * @dev Create a new saving group
     * @param period Number of periods
     * @param totalMembers Total number of members
     * @param pledgeAmount Amount each member needs to contribute per period
     */
    function createGroup(
        uint256 period,
        uint256 totalMembers,
        uint256 pledgeAmount
    ) external whenNotPaused returns (uint256 groupId) {
        require(period > 0, "Period must be greater than 0");
        require(totalMembers > 1, "Must have at least 2 members");
        require(pledgeAmount > 0, "Pledge amount must be greater than 0");

        groupId = _groupIdCounter.current();
        _groupIdCounter.increment();

        Saving storage saving = savings[groupId];
        saving.groupId = groupId;
        saving.creator = msg.sender;
        saving.period = period;
        saving.totalMembers = totalMembers;
        saving.pledgeAmount = pledgeAmount;
        saving.currentRound = 0;
        saving.totalContributed = 0;
        saving.startTime = block.timestamp;
        saving.isActive = true;

        // Add creator as first member
        _addMember(groupId, msg.sender, sourceDomain);

        userGroups[msg.sender].push(groupId);

        emit SavingCreated(
            groupId,
            msg.sender,
            period,
            totalMembers,
            pledgeAmount
        );
    }

    /**
     * @dev Join a saving group (local chain)
     * @param groupId The group ID to join
     */
    function joinGroup(uint256 groupId) external whenNotPaused {
        Saving storage saving = savings[groupId];
        if (saving.creator == address(0)) revert SavingNotFound();

        _addMember(groupId, msg.sender, sourceDomain);
    }

    /**
     * @dev Join a saving group from cross-chain with USDC collateral
     * @param groupId The group ID to join
     * @param memberAddress The member's address on the source chain
     * @param sourceDomain The source domain
     * @param collateralAmount Amount of USDC collateral required
     */
    function joinGroupCrossChain(
        uint256 groupId,
        address memberAddress,
        uint32 sourceDomain,
        uint256 collateralAmount
    ) external whenNotPaused {
        if (!supportedDomains[sourceDomain]) revert UnsupportedDomain();

        Saving storage saving = savings[groupId];
        if (saving.creator == address(0)) revert SavingNotFound();

        // Calculate required collateral (period * pledgeAmount)
        uint256 requiredCollateral = saving.period * saving.pledgeAmount;
        require(
            collateralAmount >= requiredCollateral,
            "Insufficient collateral"
        );

        // Transfer USDC collateral from the cross-chain member
        require(
            usdcToken.transferFrom(
                msg.sender,
                address(this),
                requiredCollateral
            ),
            "Collateral transfer failed"
        );

        // Add member to the group
        _addMember(groupId, memberAddress, sourceDomain);

        // Store collateral information
        Member storage member = saving.members[memberAddress];
        member.contributionAmount = requiredCollateral;

        emit MemberJoined(groupId, memberAddress, sourceDomain);
        emit CrossChainContribution(
            groupId,
            memberAddress,
            requiredCollateral,
            sourceDomain
        );
    }

    /**
     * @dev Make contribution (local chain)
     * @param groupId The group ID
     * @param amount Amount to contribute
     */
    function contribute(
        uint256 groupId,
        uint256 amount
    ) external whenNotPaused nonReentrant {
        Saving storage saving = savings[groupId];
        if (saving.creator == address(0)) revert SavingNotFound();

        Member storage member = saving.members[msg.sender];
        if (member.userAddress == address(0)) revert MemberNotFound();

        if (amount != saving.pledgeAmount) revert InvalidContributionAmount();

        // Transfer USDC from user
        require(
            usdcToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        _processContribution(groupId, msg.sender, amount, sourceDomain);
    }

    /**
     * @dev Process cross-chain contribution
     * @param groupId The group ID
     * @param memberAddress The member's address
     * @param amount Amount contributed
     * @param sourceDomain The source domain
     */
    function processCrossChainContribution(
        uint256 groupId,
        address memberAddress,
        uint256 amount,
        uint32 sourceDomain
    ) external whenNotPaused {
        if (!supportedDomains[sourceDomain]) revert UnsupportedDomain();

        Saving storage saving = savings[groupId];
        if (saving.creator == address(0)) revert SavingNotFound();

        Member storage member = saving.members[memberAddress];
        if (member.userAddress == address(0)) revert MemberNotFound();

        _processContribution(groupId, memberAddress, amount, sourceDomain);
    }

    /**
     * @dev Withdraw funds (local chain)
     * @param groupId The group ID
     */
    function withdraw(uint256 groupId) external whenNotPaused nonReentrant {
        Saving storage saving = savings[groupId];
        if (saving.creator == address(0)) revert SavingNotFound();

        Member storage member = saving.members[msg.sender];
        if (member.userAddress == address(0)) revert MemberNotFound();

        uint256 withdrawableAmount = _calculateWithdrawableAmount(
            groupId,
            msg.sender
        );
        if (withdrawableAmount == 0) revert InsufficientBalance();
    }
}
