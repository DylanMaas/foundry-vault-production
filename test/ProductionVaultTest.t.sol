// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ProductionVault} from "../src/ProductionVault.sol";
import {DeployProductionVault} from "../script/DeployProductionVault.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProductionVaultTest is Test {
    // ---------------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------------
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares); // owner is share receiver
    event Withdraw(
        address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    ProductionVault productionVault;
    HelperConfig helperConfig;
    ERC20Mock asset;

    uint256 constant DEPOSIT_AMOUNT = 100e18;
    uint256 constant PARTIAL_WITHDRAWAL_AMOUNT = 50e18;
    uint256 constant MINIMUM_DEPOSIT = 200e18;

    address public owner;
    address public user = address(2);

    function setUp() public {
        DeployProductionVault deployer = new DeployProductionVault();
        (productionVault, helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();
        asset = ERC20Mock(config.asset);
        owner = config.owner;

        asset.mint(user, DEPOSIT_AMOUNT);

        vm.prank(user);
        asset.approve(address(productionVault), DEPOSIT_AMOUNT);
    }

    modifier depositFirst() {
        vm.prank(user);
        productionVault.deposit(DEPOSIT_AMOUNT, user);
        _;
    }

    // ---------------------------------------------------------------------
    // Deployment Tests
    // ---------------------------------------------------------------------

    function test_deployment_assetIsSet() public view {
        assertEq(address(productionVault.asset()), address(asset));
    }

    function test_deployment_ownerIsSet() public view {
        assertEq(productionVault.owner(), owner);
    }

    function test_deployment_nameAndSymbol() public view {
        assertEq(productionVault.name(), "Production Vault");
        assertEq(productionVault.symbol(), "pvUSDC");
    }

    // ---------------------------------------------------------------------
    // Accounting Tests
    // ---------------------------------------------------------------------

    function test_totalAssets_isZeroOnDeployment() public view {
        assertEq(productionVault.totalAssets(), 0);
    }

    function test_convertToShares_oneToOneWhenEmpty() public view {
        assertEq(productionVault.convertToShares(DEPOSIT_AMOUNT), DEPOSIT_AMOUNT);
    }

    function test_convertToAssets_oneToOneWhenEmpty() public view {
        assertEq(productionVault.convertToAssets(DEPOSIT_AMOUNT), DEPOSIT_AMOUNT);
    }

    // ---------------------------------------------------------------------
    // Deposit Tests
    // ---------------------------------------------------------------------
    function test_deposit_mintsCorrectShares() public {
        vm.prank(user);
        uint256 shares = productionVault.deposit(DEPOSIT_AMOUNT, user);

        assertEq(shares, DEPOSIT_AMOUNT);
        assertEq(productionVault.totalAssets(), DEPOSIT_AMOUNT);
        assertEq(productionVault.balanceOf(user), DEPOSIT_AMOUNT);
    }

    function test_deposit_revertsIfAmountIsZero() public {
        vm.expectRevert(ProductionVault.ProductionVault__ZeroAmount.selector);

        vm.prank(user);
        productionVault.deposit(0, user);
    }

    function test_deposit_emitsEventAfterDepositing() public {
        vm.expectEmit(true, true, false, true);
        emit Deposit(user, user, DEPOSIT_AMOUNT, DEPOSIT_AMOUNT);

        vm.prank(user);
        productionVault.deposit(DEPOSIT_AMOUNT, user);
    }

    function test_deposit_revertsWhenPaused() public {
        vm.prank(owner);
        productionVault.pause();

        vm.expectRevert();
        vm.prank(user);
        productionVault.deposit(DEPOSIT_AMOUNT, user);
    }

    // ---------------------------------------------------------------------
    // Mint Tests
    // ---------------------------------------------------------------------
    function test_mint_mintsCorrectShares() public {
        vm.prank(user);
        uint256 assets = productionVault.mint(DEPOSIT_AMOUNT, user);

        assertEq(assets, DEPOSIT_AMOUNT);
        assertEq(productionVault.totalAssets(), DEPOSIT_AMOUNT);
        assertEq(productionVault.balanceOf(user), DEPOSIT_AMOUNT);
    }

    // ---------------------------------------------------------------------
    // Withdraw Tests
    // ---------------------------------------------------------------------
    function test_withdraw_returnsCorrectAssets() public depositFirst {
        vm.prank(user);
        uint256 assets = productionVault.withdraw(DEPOSIT_AMOUNT, user, user);

        assertEq(assets, DEPOSIT_AMOUNT);
        assertEq(productionVault.totalAssets(), 0);
        assertEq(productionVault.balanceOf(user), 0);
    }

    function test_withdraw_returnsCorrectAssetsForPartialWithdraw() public depositFirst {
        vm.prank(user);
        uint256 assets = productionVault.withdraw(PARTIAL_WITHDRAWAL_AMOUNT, user, user);

        assertEq(assets, PARTIAL_WITHDRAWAL_AMOUNT);
        assertEq(productionVault.totalAssets(), PARTIAL_WITHDRAWAL_AMOUNT);
        assertEq(productionVault.balanceOf(user), PARTIAL_WITHDRAWAL_AMOUNT);
    }

    function test_withdraw_revertsIfAmountIsZero() public {
        vm.expectRevert(ProductionVault.ProductionVault__ZeroAmount.selector);

        vm.prank(user);
        productionVault.withdraw(0, user, user);
    }

    function test_withdraw_emitsEventAfterWithdrawing() public depositFirst {
        vm.expectEmit(true, true, true, true);
        emit Withdraw(user, user, user, DEPOSIT_AMOUNT, DEPOSIT_AMOUNT);

        vm.prank(user);
        productionVault.withdraw(DEPOSIT_AMOUNT, user, user);
    }

    function test_withdraw_revertsWhenPaused() public {
        vm.prank(owner);
        productionVault.pause();

        vm.expectRevert();
        vm.prank(user);
        productionVault.withdraw(DEPOSIT_AMOUNT, user, user);
    }

    // ---------------------------------------------------------------------
    // Withdraw Tests (asset-denominated)
    // ---------------------------------------------------------------------
    function test_withdraw_byAssetAmount() public depositFirst {
        vm.prank(user);
        uint256 shares = productionVault.withdraw(DEPOSIT_AMOUNT, user, user);

        assertEq(shares, DEPOSIT_AMOUNT);
        assertEq(productionVault.totalAssets(), 0);
        assertEq(productionVault.balanceOf(user), 0);
    }

    // ---------------------------------------------------------------------
    // Minimum Deposit Tests
    // ---------------------------------------------------------------------
    function test_setMinimumDeposit_onlyOwner() public {
        vm.prank(owner);
        productionVault.setMinimumDeposit(MINIMUM_DEPOSIT);

        assertEq(productionVault.s_minimumDeposit(), MINIMUM_DEPOSIT);
    }

    function test_setMinimumDeposit_revertsIfNotOnlyOwner() public {
        vm.expectRevert();

        vm.prank(user);
        productionVault.setMinimumDeposit(MINIMUM_DEPOSIT);
    }

    function test_setMinimumDeposit_revertsIfBelowMinimumDeposit() public {
        vm.prank(owner);
        productionVault.setMinimumDeposit(MINIMUM_DEPOSIT);

        vm.expectRevert(
            abi.encodeWithSelector(
                ProductionVault.ProductionVault__BelowMinimumDeposit.selector, DEPOSIT_AMOUNT, MINIMUM_DEPOSIT
            )
        );
        vm.prank(user);
        productionVault.deposit(DEPOSIT_AMOUNT, user);
    }

    // ---------------------------------------------------------------------
    // Fuzz Tests
    // ---------------------------------------------------------------------
    function testFuzz_deposit_mintsCorrectShares(uint256 amount) public {
        amount = bound(amount, 1, 1000000e18);

        asset.mint(user, amount);
        vm.prank(user);
        asset.approve(address(productionVault), amount);

        vm.prank(user);
        uint256 shares = productionVault.deposit(amount, user);

        assertEq(shares, amount);
        assertEq(productionVault.totalAssets(), amount);
        assertEq(productionVault.balanceOf(user), amount);
    }

    function testFuzz_withdraw_returnsCorrectAssets(uint256 amount) public {
        amount = bound(amount, 1, 1000000e18);

        asset.mint(user, amount);
        vm.prank(user);
        asset.approve(address(productionVault), amount);

        vm.prank(user);
        productionVault.deposit(amount, user);

        vm.prank(user);
        uint256 assets = productionVault.withdraw(amount, user, user);

        assertEq(assets, amount);
        assertEq(productionVault.totalAssets(), 0);
        assertEq(productionVault.balanceOf(user), 0);
    }
}
