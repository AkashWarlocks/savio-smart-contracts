// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/mocks/MockUSDC.sol";

/**
 * @title HelperConfig
 * @dev Configuration helper for network-specific addresses and parameters
 */
contract HelperConfig is Script {
    struct NetworkConfig {
        address entryPoint;
        address layerZeroEndpoint;
        string name;
        address usdcAddress;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            // Sepolia
            activeNetworkConfig = NetworkConfig({
                entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
                layerZeroEndpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f, // Sepolia EndpointV2
                name: "Sepolia",
                usdcAddress: 0x50Ae5Ea38514bD561F6a60Ea9c48807452bb5Ccf
            });
        } else if (block.chainid == 80002) {
            // Amoy (Polygon Mumbai)
            activeNetworkConfig = NetworkConfig({
                entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
                layerZeroEndpoint: 0xf69186dfBa60DdB133E91E9A4B5673624293d8F8, // Mumbai EndpointV2
                name: "Amoy",
                usdcAddress: 0x50Ae5Ea38514bD561F6a60Ea9c48807452bb5Ccf
            });
        } else if (block.chainid == 421614) {
            // Arbitrum Sepolia
            activeNetworkConfig = NetworkConfig({
                entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
                layerZeroEndpoint: 0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab, // Arbitrum Sepolia EndpointV2
                name: "Arbitrum Sepolia",
                usdcAddress: 0x50Ae5Ea38514bD561F6a60Ea9c48807452bb5Ccf
            });
        } else if (block.chainid == 84532) {
            // Base Sepolia
            activeNetworkConfig = NetworkConfig({
                entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
                layerZeroEndpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f, // Base Sepolia EndpointV2
                name: "Base Sepolia",
                usdcAddress: 0x50Ae5Ea38514bD561F6a60Ea9c48807452bb5Ccf
            });
        } else {
            // Default/Anvil
            MockUSDC mockUSDC = new MockUSDC();
            activeNetworkConfig = NetworkConfig({
                entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
                layerZeroEndpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f, // Default to Sepolia for testing
                name: "Anvil",
                usdcAddress: address(mockUSDC)
            });
        }
    }

    /**
     * @notice Get the EntryPoint address for the current network
     * @return The EntryPoint address
     */
    function getEntryPoint() public view returns (address) {
        return activeNetworkConfig.entryPoint;
    }

    /**
     * @notice Get the LayerZero endpoint address for the current network
     * @return The LayerZero endpoint address
     */
    function getLayerZeroEndpoint() public view returns (address) {
        return activeNetworkConfig.layerZeroEndpoint;
    }

    /**
     * @notice Get the network name
     * @return The network name
     */
    function getNetworkName() public view returns (string memory) {
        return activeNetworkConfig.name;
    }

    /**
     * @notice Get the full network configuration
     * @return The NetworkConfig struct
     */
    function getActiveNetworkConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        return activeNetworkConfig;
    }
}
