// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SavioSmartAccount.sol";

/**
 * @title SavioSmartAccountFactory
 * @dev Factory contract for deploying SavioSmartAccount instances
 */
contract SavioSmartAccountFactory is Ownable {
    using Clones for address;

    SavioSmartAccount public immutable accountImplementation;
    mapping(address => bool) public isAccountDeployed;

    event AccountCreated(
        address indexed account,
        address indexed owner,
        uint256 indexed salt
    );

    /**
     * @dev Constructor
     * @param _entryPoint The EntryPoint contract address
     */
    constructor(IEntryPoint _entryPoint) Ownable(msg.sender) {
        accountImplementation = new SavioSmartAccount(
            _entryPoint,
            address(this)
        );
    }

    /**
     * @dev Create a new account
     * @param owner The owner of the account
     * @param salt The salt for deterministic deployment
     * @return account The deployed account address
     */
    function createAccount(
        address owner,
        uint256 salt
    ) public returns (SavioSmartAccount account) {
        address addr = getAddress(owner, salt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return SavioSmartAccount(payable(addr));
        }
        account = SavioSmartAccount(
            payable(
                address(accountImplementation).cloneDeterministic(bytes32(salt))
            )
        );
        isAccountDeployed[address(account)] = true;
        emit AccountCreated(address(account), owner, salt);
    }

    /**
     * @dev Get the address of an account that would be deployed with the given parameters
     * @param salt The salt for deterministic deployment
     * @return The address of the account
     */
    function getAddress(
        address owner,
        uint256 salt
    ) public view returns (address) {
        return
            address(accountImplementation).predictDeterministicAddress(
                bytes32(salt),
                address(this)
            );
    }

    /**
     * @dev Check if an account is deployed
     * @param account The account address
     * @return True if the account is deployed
     */
    function checkAccountDeployed(address account) public view returns (bool) {
        return isAccountDeployed[account];
    }
}
