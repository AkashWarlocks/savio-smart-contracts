// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SavioSmartAccount
 * @dev Minimal ERC-4337 smart account based on BaseAccount with multi-sig support.
 */
contract SavioSmartAccount is BaseAccount, ReentrancyGuard {
    // Events
    event SmartAccountInitialized(address indexed owner, uint256 indexed salt);

    // State variables
    IEntryPoint private immutable _entryPoint;
    uint256 public nonce;
    mapping(address => bool) public isSigner;
    address[] public signers;
    uint256 public signerCount;

    // Modifiers
    modifier onlySigner() {
        require(
            isSigner[msg.sender],
            "SavioSmartAccount: caller is not a signer"
        );
        _;
    }
    modifier onlyEntryPoint() {
        require(
            msg.sender == address(entryPoint()),
            "SavioSmartAccount: caller is not entry point"
        );
        _;
    }

    /**
     * @dev Constructor
     * @param entryPoint_ The EntryPoint contract address
     * @param _owner The initial owner of the account
     */
    constructor(IEntryPoint entryPoint_, address _owner) {
        _entryPoint = entryPoint_;
        isSigner[_owner] = true;
        signers.push(_owner);
        signerCount = 1;
    }

    /**
     * @dev Return the entryPoint used by this account
     */
    function entryPoint() public view override returns (IEntryPoint) {
        return _entryPoint;
    }

    /**
     * @dev Add a new signer
     * @param signer The address of the new signer
     */
    function addSigner(address signer) external onlySigner {
        require(signer != address(0), "SavioSmartAccount: invalid signer");
        require(!isSigner[signer], "SavioSmartAccount: signer already exists");
        isSigner[signer] = true;
        signers.push(signer);
        signerCount++;
    }

    /**
     * @dev Remove a signer
     * @param signer The address of the signer to remove
     */
    function removeSigner(address signer) external onlySigner {
        require(isSigner[signer], "SavioSmartAccount: signer does not exist");
        require(
            signerCount > 1,
            "SavioSmartAccount: cannot remove last signer"
        );
        isSigner[signer] = false;
        signerCount--;
        // Remove from signers array
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }
    }

    /**
     * @dev Get all signers
     * @return Array of signer addresses
     */
    function getSigners() external view returns (address[] memory) {
        return signers;
    }

    /**
     * @dev Execute a transaction
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external override onlyEntryPoint nonReentrant {
        _call(target, value, data);
    }

    /**
     * @dev Execute a batch of transactions
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external onlyEntryPoint nonReentrant {
        require(
            targets.length == values.length && targets.length == datas.length,
            "SavioSmartAccount: array lengths mismatch"
        );
        for (uint256 i = 0; i < targets.length; i++) {
            _call(targets[i], values[i], datas[i]);
        }
    }

    /**
     * @dev Validate user operation
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 /*missingAccountFunds*/
    ) external override returns (uint256 validationData) {
        require(
            msg.sender == address(entryPoint()),
            "SavioSmartAccount: caller is not entry point"
        );
        // Verify signature
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address recoveredSigner = ECDSA.recover(hash, userOp.signature);
        require(
            isSigner[recoveredSigner],
            "SavioSmartAccount: invalid signature"
        );
        // Update nonce
        nonce++;
        return 0;
    }

    /**
     * @dev Implementation of BaseAccount's abstract _validateSignature
     */
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view override returns (uint256 validationData) {
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address recoveredSigner = ECDSA.recover(hash, userOp.signature);
        if (isSigner[recoveredSigner]) {
            return 0;
        } else {
            return 1;
        }
    }

    receive() external payable {}

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }
}
