// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {ProductionVault} from "../src/ProductionVault.sol";
import {AaveStrategy} from "../src/strategies/AaveStrategy.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployProductionVault is Script {
    function run() external returns (ProductionVault productionVault, HelperConfig helperConfig) {
        helperConfig = new HelperConfig(); // This comes with the mocks
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();

        vm.startBroadcast(config.owner);
        productionVault = new ProductionVault(IERC20(config.asset), config.name, config.symbol, config.owner);

        // only deploy strategy if Aave addresses are set
        if (config.aavePool != address(0)) {
            AaveStrategy strategy =
                new AaveStrategy(config.aavePool, config.asset, config.aToken, address(productionVault), config.owner);

            productionVault.setStrategy(strategy);
        }

        vm.stopBroadcast();
        return (productionVault, helperConfig);
    }
}
