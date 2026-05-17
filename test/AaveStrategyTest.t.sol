// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ProductionVault} from "../src/ProductionVault.sol";
import {DeployProductionVault} from "../script/DeployProductionVault.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AaveStrategy} from "../src/strategies/AaveStrategy.sol";

contract ProductionVaultTest is Test {
    ProductionVault productionVault;
    AaveStrategy aaveStrategy;

    address public owner;
    address public user = address(2);

    // Aave Sepolia addresses
    address constant AAVE_POOL = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
    address constant USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
    address constant aUSDC = 0x16dA4541aD1807f4443d92D26044C1147406EB80;

    uint256 constant DEPOSIT_AMOUNT = 100e6; // USDC has 6 decimals!

    function setUp() public {
        owner = address(this);

        vm.startPrank(owner);
        productionVault = new ProductionVault(IERC20(USDC), "Production Vault", "pvUSDC", owner);

        aaveStrategy = new AaveStrategy(AAVE_POOL, USDC, aUSDC, address(productionVault), owner);

        productionVault.setStrategy(aaveStrategy);
        vm.stopPrank();
    }

    function test_strategy_isSetOnVault() public view {
        assertEq(address(productionVault.s_strategy()), address(aaveStrategy));
    }

    function test_strategy_depositForwardsToAave() public {
        // give user real USDC using deal
        deal(USDC, user, DEPOSIT_AMOUNT);

        vm.prank(user);
        IERC20(USDC).approve(address(productionVault), DEPOSIT_AMOUNT);

        vm.prank(user);
        productionVault.deposit(DEPOSIT_AMOUNT, user);

        // vault should have forwarded funds to strategy
        assertEq(IERC20(USDC).balanceOf(address(productionVault)), 0);
        assertApproxEqAbs(aaveStrategy.totalAssets(), DEPOSIT_AMOUNT, 1);
    }

    function test_strategy_totalAssetsIncludesAave() public {
        deal(USDC, user, DEPOSIT_AMOUNT);

        vm.prank(user);
        IERC20(USDC).approve(address(productionVault), DEPOSIT_AMOUNT);

        vm.prank(user);
        productionVault.deposit(DEPOSIT_AMOUNT, user);

        assertApproxEqAbs(productionVault.totalAssets(), DEPOSIT_AMOUNT, 1);
    }
}
