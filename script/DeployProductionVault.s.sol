// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {ProductionVault} from "../src/ProductionVault.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployProductionVault is Script {
    function run() external returns (ProductionVault, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with the mocks
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();

        vm.startBroadcast();
        ProductionVault productionVault =
            new ProductionVault(IERC20(config.asset), config.name, config.symbol, config.owner);

        vm.stopBroadcast();
        return (productionVault, helperConfig);
    }
}
