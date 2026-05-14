// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address asset;
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

    function getSepoliaConfig() public pure returns (NetworkConfig memory sepoliaConfig) {
        sepoliaConfig = NetworkConfig({
            asset: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238, // USDC on Sepolia
            name: "Production Vault",
            symbol: "pvUSDC",
            owner: 0x26dd5cb257a4f3C4C54D1eE524A1664E7013B29F // Sepolia test address
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
            name: "Production Vault",
            symbol: "pvUSDC",
            owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 // first standard Anvil account
        });
        return anvilNetworkConfig;
    }

    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
