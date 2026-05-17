// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address asset;
        address aavePool;
        address aToken;
        address owner;
        string name;
        string symbol;
    }

    NetworkConfig public activeNetworkConfig;

    // uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // first anvil private key

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory sepoliaConfig) {
        sepoliaConfig = NetworkConfig({
            asset: 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8, // USDC on Sepolia
            aavePool: 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951,
            aToken: 0x16dA4541aD1807f4443d92D26044C1147406EB80,
            name: "Production Vault",
            symbol: "pvUSDC",
            owner: msg.sender
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
        // check to see if we set an active network config. If not equal to 0 address, that means we have already set it!!
        if (activeNetworkConfig.asset != address(0)) {
            return activeNetworkConfig;
        }

        // Deploy mocks
        vm.startBroadcast();
        ERC20Mock mockAsset = new ERC20Mock();
        vm.stopBroadcast();

        anvilNetworkConfig = NetworkConfig({
            asset: address(mockAsset),
            aavePool: address(0), // no Aave on Anvil
            aToken: address(0), // no Aave on Anvil
            name: "Production Vault",
            symbol: "pvUSDC",
            owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 // Anvil default address
        });
        return anvilNetworkConfig;
    }

    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
