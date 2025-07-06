# Savio Protocol

frontend [link] https://github.com/andiz2/savio-fe
savio-layer-zero [link] https://github.com/AkashWarlocks/savio-smart-contracts

A cross-chain saving protocol that enables users to create collaborative saving groups with smart account wallets and seamless cross-chain USDC transfers using Circle's Cross-Chain Transfer Protocol (CCTP).

## 🚀 Features

- **Smart Account Wallets**: Account abstraction for enhanced user experience
- **Cross-Chain USDC Transfers**: Seamless token transfers across multiple chains using Circle CCTP
- **Collaborative Saving Groups**: Create and manage saving groups with multiple participants
- **Bidding System**: Competitive bidding rounds to determine fund distribution
- **Cross-Chain Participation**: Join saving groups from any supported chain
- **Collateral Management**: Secure collateral system for cross-chain participants

## 🏗️ Architecture

### Core Components

1. **SavioSmartAccount**: ERC-4337 compatible smart account wallet
2. **SavioSmartAccountFactory**: Factory contract for deploying smart accounts
3. **SavioProtocol**: Main protocol contract for saving groups
4. **SavioProtocolFactory**: Factory for deploying protocol instances
5. **SavioProtocolCCTP**: Cross-chain version with CCTP integration

### Cross-Chain Integration

- **Circle CCTP**: For secure USDC transfers across chains
- **LayerZero v2**: For cross-chain messaging and coordination
- **Account Abstraction**: For seamless wallet management

## 📦 Installation

```bash
# Clone the repository
git clone <repository-url>
cd savio-setup

# Install dependencies
forge install

# Build contracts
forge build
```

## 🔧 Configuration

### Environment Setup

Create a `.env` file with the following variables:

```env
# RPC URLs
SEPOLIA_RPC_URL=your_sepolia_rpc_url
BASE_SEPOLIA_RPC_URL=your_base_sepolia_rpc_url
POLYGON_AMOY_RPC_URL=your_polygon_amoy_rpc_url

# Private Keys (optional - can use --accounts dev)
PRIVATE_KEY=your_private_key

# CCTP Configuration
CCTP_TOKEN_MESSENGER=0x...  # Circle CCTP TokenMessenger address
CCTP_MESSAGE_TRANSMITTER=0x...  # Circle CCTP MessageTransmitter address
CCTP_TOKEN_MINTER=0x...  # Circle CCTP TokenMinter address

# USDC Addresses
USDC_SEPOLIA=0x...  # USDC on Sepolia
USDC_BASE_SEPOLIA=0x...  # USDC on Base Sepolia
USDC_POLYGON_AMOY=0x...  # USDC on Polygon Amoy
```

### Remappings

The project includes proper remappings for all dependencies:

```toml
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
@layerzerolabs/oapp-evm/=lib/devtools/packages/oapp-evm/
@layerzerolabs/lz-evm-protocol-v2/=lib/layerzero-v2/packages/layerzero-v2/evm/protocol
@account-abstraction/contracts/=lib/account-abstraction/contracts/
@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/
@evm-cctp-contracts/=lib/evm-cctp-contracts/src/
forge-std/=lib/forge-std/src/
```

## 🚀 Deployment

### Deploy Smart Account Factory

```bash
# Deploy to Sepolia
forge script script/DeploySavioSmartAccount.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify

# Deploy to Base Sepolia
forge script script/DeploySavioSmartAccount.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify

# Deploy to Polygon Amoy
forge script script/DeploySavioSmartAccount.s.sol --rpc-url $POLYGON_AMOY_RPC_URL --broadcast --verify
```

### Deploy Protocol Contracts

```bash
# Deploy to Sepolia
forge script script/DeploySavio.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify

# Deploy to Base Sepolia
forge script script/DeploySavio.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify

# Deploy to Polygon Amoy
forge script script/DeploySavio.s.sol --rpc-url $POLYGON_AMOY_RPC_URL --broadcast --verify
```

### Deploy CCTP Protocol

```bash
# Deploy CCTP-enabled protocol
forge script script/DeploySavioCCTP.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

## 🧪 Testing

### Run All Tests

```bash
forge test
```

### Run Specific Test Files

```bash
# Basic deployment tests
forge test --match-contract BasicDeployTest

# Positive flow tests
forge test --match-contract BasicPositiveTest

# CCTP integration tests
forge test --match-contract CCTPTest
```

### Test with Verbose Output

```bash
forge test -vvv
```

## 📋 Usage Examples

### Creating a Smart Account

```solidity
// Deploy a new smart account
SavioSmartAccount account = SavioSmartAccountFactory(factoryAddress).createAccount(owner, salt);
```

### Creating a Saving Group

```solidity
// Create a new saving group
uint256 groupId = protocol.createGroup(
    3,      // 3 periods
    4,      // 4 members
    100e6   // 100 USDC pledge per period
);
```

### Joining a Group Cross-Chain

```solidity
// Join from another chain with USDC collateral
protocol.joinGroupCrossChain(
    groupId,
    memberAddress,
    sourceDomain,
    collateralAmount
);
```

### Making Contributions

```solidity
// Make a local contribution
protocol.contribute(groupId, pledgeAmount);

// Process cross-chain contribution
protocol.processCrossChainContribution(
    groupId,
    memberAddress,
    amount,
    sourceDomain
);
```

## 🔗 Cross-Chain Integration

### CCTP Flow

1. **Burn USDC on Source Chain**: User burns USDC using Circle's TokenMessenger
2. **Message Transmission**: Cross-chain message sent via MessageTransmitter
3. **Mint USDC on Destination**: USDC minted on destination chain via TokenMinter
4. **Protocol Integration**: Savio protocol processes the cross-chain contribution

### Supported Chains

- **Sepolia**: Ethereum testnet
- **Base Sepolia**: Base testnet
- **Polygon Amoy**: Polygon testnet

## 📊 Contract Addresses

### Sepolia
- SavioSmartAccountFactory: `0x...`
- SavioProtocolFactory: `0x...`
- SavioProtocolCCTP: `0x...`

### Base Sepolia
- SavioSmartAccountFactory: `0x...`
- SavioProtocolFactory: `0x...`
- SavioProtocolCCTP: `0x...`

### Polygon Amoy
- SavioSmartAccountFactory: `0x...`
- SavioProtocolFactory: `0x...`
- SavioProtocolCCTP: `0x...`

## 🔒 Security

### Audited Dependencies

- **OpenZeppelin Contracts**: v5.3.0 (audited)
- **Circle CCTP**: Official Circle implementation
- **LayerZero v2**: Audited cross-chain messaging
- **Account Abstraction**: ERC-4337 standard

### Security Features

- Reentrancy protection
- Access control with Ownable
- Pausable functionality
- Cross-chain message validation
- Collateral management

## 🛠️ Development

### Project Structure

```
savio-setup/
├── src/
│   ├── SavioSmartAccount.sol          # Smart account implementation
│   ├── SavioSmartAccountFactory.sol   # Smart account factory
│   ├── SavioProtocol.sol              # Main protocol contract
│   ├── SavioProtocolFactory.sol       # Protocol factory
│   ├── SavioProtocolCCTP.sol          # CCTP-enabled protocol
│   └── mocks/
│       ├── MockUSDC.sol               # Mock USDC for testing
│       └── MockVRFCoordinator.sol     # Mock VRF for testing
├── script/
│   ├── DeploySavio.s.sol              # Protocol deployment
│   ├── DeploySavioSmartAccount.s.sol  # Smart account deployment
│   └── DeploySavioCCTP.s.sol          # CCTP deployment
├── test/
│   ├── BasicDeployTest.t.sol          # Deployment tests
│   └── BasicPositiveTest.t.sol        # Functionality tests
├── abi/
│   ├── factory.json                   # Factory ABI
│   └── group.json                     # Protocol ABI
└── lib/                               # Dependencies
```

### Adding New Chains

1. Update `config/chains.json` with new chain configuration
2. Add RPC URL to environment variables
3. Deploy contracts to new chain
4. Update contract addresses in documentation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Circle**: For CCTP implementation
- **LayerZero**: For cross-chain messaging infrastructure
- **OpenZeppelin**: For secure smart contract libraries
- **ERC-4337**: For account abstraction standards

## 📞 Support

For questions and support:
- Create an issue on GitHub
- Join our Discord community
- Email: support@savio-protocol.com

---

**Built with ❤️ for the Ethereum ecosystem**
