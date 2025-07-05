// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

/**
 * @title SavioProtocol
 * @dev Savings protocol contract
 */
contract SavioProtocol is Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    // Chainlink VRF variables
    VRFCoordinatorV2Interface private immutable COORDINATOR;
    bytes32 private immutable KEY_HASH;
    uint64 private immutable SUBSCRIPTION_ID;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant CALLBACK_GAS_LIMIT = 100000;

    // Protocol parameters
    uint256 public immutable period;
    uint256 public immutable totalMembers;
    uint256 public immutable pledgeAmount;
    IERC20 public immutable usdcToken;

    // State variables
    uint256 public currentRound;
    uint256 public currentPeriod;
    bool public isActive;
    uint256 public totalContributed;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public randomRequestId;
    bool public waitingForRandomness;

    // Member management
    mapping(address => bool) public isMember;
    mapping(address => uint256) public memberIndex;
    mapping(address => bool) public hasWon;
    mapping(address => uint256) public memberContribution;
    address[] public members;
    uint256 public memberCount;

    // Round tracking
    mapping(uint256 => mapping(address => bool)) public hasContributed;
    mapping(uint256 => address) public roundWinner;
    mapping(uint256 => uint256) public roundTotalContribution;
    mapping(uint256 => uint256) public roundBidAmount;
    mapping(uint256 => mapping(address => bool)) public hasClaimedBidShare;

    // Events
    event GroupCreated(
        uint256 indexed groupId,
        address indexed creator,
        uint256 period,
        uint256 totalMembers,
        uint256 pledgeAmount
    );
    event MemberJoined(address indexed member, uint256 collateral);
    event ContributionMade(
        address indexed member,
        uint256 amount,
        uint256 round
    );
    event BidPlaced(address indexed bidder, uint256 amount, uint256 round);
    event RoundCompleted(
        uint256 indexed round,
        address indexed winner,
        uint256 amount
    );
    event RandomWinnerSelected(uint256 indexed round, address indexed winner);
    event WithdrawalMade(address indexed winner, uint256 amount, uint256 round);
    event BidShareClaimed(
        address indexed member,
        uint256 amount,
        uint256 round
    );
    event CollateralReturned(address indexed member, uint256 amount);

    // Errors
    error GroupFull();
    error AlreadyMember();
    error NotMember();
    error GroupNotActive();
    error InsufficientCollateral();
    error InsufficientAmount();
    error AlreadyContributed();
    error RoundNotComplete();
    error NoBids();
    error InvalidBid();
    error NoWinnerSelected();
    error AlreadyWon();
    error InvalidPeriod();

    /**
     * @dev Constructor
     * @param _period Number of periods in the ROSCA
     * @param _totalMembers Total number of members allowed
     * @param _pledgeAmount Amount each member pledges per period
     * @param _usdcToken USDC token address
     * @param _vrfCoordinator Chainlink VRF coordinator address
     * @param _keyHash Chainlink VRF key hash
     * @param _subscriptionId Chainlink VRF subscription ID
     */
    constructor(
        uint256 _period,
        uint256 _totalMembers,
        uint256 _pledgeAmount,
        IERC20 _usdcToken,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) Ownable(msg.sender) {
        require(_period > 0, "Period must be greater than 0");
        require(_totalMembers > 1, "Must have at least 2 members");
        require(_pledgeAmount > 0, "Pledge amount must be greater than 0");

        period = _period;
        totalMembers = _totalMembers;
        pledgeAmount = _pledgeAmount;
        usdcToken = _usdcToken;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        KEY_HASH = _keyHash;
        SUBSCRIPTION_ID = _subscriptionId;

        isActive = true;
        currentRound = 1;
        currentPeriod = 1;
    }

    /**
     * @dev Join the ROSCA group
     * @param collateral Amount of USDC as collateral (period * pledgeAmount)
     */
    function join(uint256 collateral) external nonReentrant {
        if (!isActive) revert GroupNotActive();
        if (memberCount >= totalMembers) revert GroupFull();
        if (isMember[msg.sender]) revert AlreadyMember();
        if (collateral != period * pledgeAmount)
            revert InsufficientCollateral();

        // Transfer USDC collateral
        require(
            usdcToken.transferFrom(msg.sender, address(this), collateral),
            "Transfer failed"
        );

        // Add member
        isMember[msg.sender] = true;
        memberIndex[msg.sender] = memberCount;
        members.push(msg.sender);
        memberCount++;

        emit MemberJoined(msg.sender, collateral);

        // Start first round if group is full
        if (memberCount == totalMembers) {
            currentRound = 1;
            currentPeriod = 1;
        }
    }

    /**
     * @dev Contribute to current round
     * @param amount Total amount to contribute (must be >= pledgeAmount)
     */
    function contribute(uint256 amount) external nonReentrant {
        if (!isActive) revert GroupNotActive();
        if (!isMember[msg.sender]) revert NotMember();
        if (hasContributed[currentRound][msg.sender])
            revert AlreadyContributed();
        if (amount < pledgeAmount) revert InsufficientAmount();

        // Transfer the total amount
        require(
            usdcToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        // Mark as contributed
        hasContributed[currentRound][msg.sender] = true;
        memberContribution[msg.sender] += amount;
        roundTotalContribution[currentRound] += amount;
        totalContributed += amount;

        emit ContributionMade(msg.sender, amount, currentRound);

        // Handle bidding - if amount > pledgeAmount, the excess is considered a bid
        if (amount > pledgeAmount) {
            uint256 bidAmount = amount - pledgeAmount;
            if (bidAmount <= highestBid) revert InvalidBid();

            highestBid = bidAmount;
            highestBidder = msg.sender;
            roundBidAmount[currentRound] += bidAmount;

            emit BidPlaced(msg.sender, bidAmount, currentRound);
        }

        // Check if round is complete
        if (getContributionCount() == memberCount) {
            completeRound();
        }
    }

    /**
     * @dev Complete the current round
     */
    function completeRound() internal {
        address winner;

        if (highestBidder != address(0)) {
            // Highest bidder wins
            winner = highestBidder;
            roundWinner[currentRound] = winner;
            hasWon[winner] = true;

            // Distribute bid amount among losers (excluding previous winners)
            if (roundBidAmount[currentRound] > 0) {
                distributeBidAmount(currentRound);
            }

            emit RoundCompleted(
                currentRound,
                winner,
                roundTotalContribution[currentRound]
            );
        } else if (highestBidder == address(0)) {
            // No bids, check if this is the last round with only one eligible member
            address[] memory eligibleMembers = getEligibleMembers();

            if (eligibleMembers.length == 1) {
                // Only one eligible member left, they win automatically
                winner = eligibleMembers[0];
                roundWinner[currentRound] = winner;
                hasWon[winner] = true;

                emit RoundCompleted(
                    currentRound,
                    winner,
                    roundTotalContribution[currentRound]
                );
            } else {
                // Multiple eligible members, use Chainlink VRF for random selection
                requestRandomWinner();
                return;
            }
        }

        // Automatically transfer winnings to winner
        uint256 amount = pledgeAmount * totalMembers;
        require(usdcToken.transfer(winner, amount), "Transfer failed");
        emit WithdrawalMade(winner, amount, currentRound);

        // Reset for next round
        resetRound();
    }

    /**
     * @dev Request random winner from Chainlink VRF
     */
    function requestRandomWinner() internal {
        require(!waitingForRandomness, "Already waiting for randomness");

        randomRequestId = COORDINATOR.requestRandomWords(
            KEY_HASH,
            SUBSCRIPTION_ID,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            1
        );

        waitingForRandomness = true;
    }

    /**
     * @dev Chainlink VRF callback
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(requestId == randomRequestId, "Invalid request ID");
        require(waitingForRandomness, "Not waiting for randomness");

        // Select random winner from eligible members
        address[] memory eligibleMembers = getEligibleMembers();
        require(eligibleMembers.length > 0, "No eligible members");

        uint256 randomIndex = randomWords[0] % eligibleMembers.length;
        address winner = eligibleMembers[randomIndex];

        roundWinner[currentRound] = winner;
        hasWon[winner] = true;

        waitingForRandomness = false;

        emit RandomWinnerSelected(currentRound, winner);
        emit RoundCompleted(
            currentRound,
            winner,
            roundTotalContribution[currentRound]
        );

        // Automatically transfer winnings to winner
        uint256 amount = pledgeAmount * totalMembers;
        require(usdcToken.transfer(winner, amount), "Transfer failed");
        emit WithdrawalMade(winner, amount, currentRound);

        // Reset for next round
        resetRound();
    }

    /**
     * @dev Distribute bid amount among losers (excluding previous winners)
     * @param round The round number
     */
    function distributeBidAmount(uint256 round) internal {
        uint256 totalBidAmount = roundBidAmount[round];
        uint256 protocolFee = (totalBidAmount * 20) / 100; // 20% protocol fee
        uint256 distributionAmount = totalBidAmount - protocolFee;

        // Count eligible losers (those who haven't won yet and contributed to this round)
        uint256 eligibleLosersCount = 0;
        for (uint256 i = 0; i < memberCount; i++) {
            address member = members[i];
            if (
                !hasWon[member] &&
                hasContributed[round][member] &&
                member != roundWinner[round]
            ) {
                eligibleLosersCount++;
            }
        }

        // If no eligible losers, protocol keeps the entire bid amount
        if (eligibleLosersCount == 0) {
            return;
        }

        // Calculate share per eligible loser
        uint256 sharePerLoser = distributionAmount / eligibleLosersCount;

        // Distribute to eligible losers
        for (uint256 i = 0; i < memberCount; i++) {
            address member = members[i];
            if (
                !hasWon[member] &&
                hasContributed[round][member] &&
                member != roundWinner[round]
            ) {
                // Transfer share to member
                require(
                    usdcToken.transfer(member, sharePerLoser),
                    "Transfer failed"
                );
                emit BidShareClaimed(member, sharePerLoser, round);
            }
        }
    }

    /**
     * @dev Reset round state for next round
     */
    function resetRound() internal {
        // Clear round state
        for (uint256 i = 0; i < members.length; i++) {
            hasContributed[currentRound][members[i]] = false;
        }

        highestBid = 0;
        highestBidder = address(0);

        currentRound++;

        // Check if Group is complete
        if (currentRound > period) {
            isActive = false;
            returnCollateral();
        }
    }

    /**
     * @dev Get eligible members for random selection (those who haven't won yet)
     */
    function getEligibleMembers() public view returns (address[] memory) {
        address[] memory eligible = new address[](memberCount);
        uint256 eligibleCount = 0;

        for (uint256 i = 0; i < memberCount; i++) {
            if (!hasWon[members[i]]) {
                eligible[eligibleCount] = members[i];
                eligibleCount++;
            }
        }

        // Resize array
        address[] memory result = new address[](eligibleCount);
        for (uint256 i = 0; i < eligibleCount; i++) {
            result[i] = eligible[i];
        }

        return result;
    }

    /**
     * @dev Get contribution count for current round
     */
    function getContributionCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < memberCount; i++) {
            if (hasContributed[currentRound][members[i]]) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Get all members
     */
    function getAllMembers() external view returns (address[] memory) {
        return members;
    }

    /**
     * @dev Get member contribution for current round
     */
    function getMemberContribution(
        address member
    ) external view returns (uint256) {
        return memberContribution[member];
    }

    /**
     * @dev Return original collateral to members after ROSCA is complete
     * Can only be called when all rounds are finished
     * Each member gets back their original collateral amount
     */
    function returnCollateral() internal {
        require(!isActive, "Group must be complete");
        require(currentRound > period, "All rounds must be finished");

        uint256 collateralPerMember = period * pledgeAmount; // 300 USDC per member

        for (uint256 i = 0; i < memberCount; i++) {
            address member = members[i];

            // Return original collateral to each member
            require(
                usdcToken.transfer(member, collateralPerMember),
                "Collateral transfer failed"
            );

            emit CollateralReturned(member, collateralPerMember);
        }
    }

    /**
     * @dev Emergency pause (only owner)
     */
    function pause() external onlyOwner {
        isActive = false;
    }

    /**
     * @dev Resume (only owner)
     */
    function resume() external onlyOwner {
        isActive = true;
    }
}
