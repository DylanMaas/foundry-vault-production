// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AaveStrategy} from "./strategies/AaveStrategy.sol";

contract ProductionVault is ERC4626, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    // -----------------------------------------------------------------
    // Errors
    // -----------------------------------------------------------------

    error ProductionVault__ZeroAmount();
    error ProductionVault__BelowMinimumDeposit(uint256 amount, uint256 minimum);
    error ProductionVault__StrategyNotSet();

    // -----------------------------------------------------------------
    // State Variables
    // -----------------------------------------------------------------
    uint256 public s_minimumDeposit;
    AaveStrategy public s_strategy;

    // -----------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------
    constructor(IERC20 asset_, string memory name_, string memory symbol_, address initialOwner)
        ERC4626(asset_)
        ERC20(name_, symbol_)
        Ownable(initialOwner)
    {}

    // -----------------------------------------------------------------
    // External & Public functions
    // -----------------------------------------------------------------
    function totalAssets() public view override returns (uint256) {
        uint256 vaultBalance = super.totalAssets();
        if (address(s_strategy) == address(0)) return vaultBalance;
        return vaultBalance + s_strategy.totalAssets();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMinimumDeposit(uint256 minimumDeposit_) external onlyOwner {
        s_minimumDeposit = minimumDeposit_;
    }

    function setStrategy(AaveStrategy strategy_) external onlyOwner {
        s_strategy = strategy_;
    }

    // -----------------------------------------------------------------
    // Internal functions
    // -----------------------------------------------------------------

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
        internal
        virtual
        override
        whenNotPaused
        nonReentrant
    {
        if (assets == 0) revert ProductionVault__ZeroAmount();
        if (assets < s_minimumDeposit) revert ProductionVault__BelowMinimumDeposit(assets, s_minimumDeposit);

        super._deposit(caller, receiver, assets, shares);

        if (address(s_strategy) != address(0)) {
            IERC20(asset()).safeTransfer(address(s_strategy), assets);
            s_strategy.deposit(assets);
        }
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        virtual
        override
        whenNotPaused
        nonReentrant
    {
        if (shares == 0) revert ProductionVault__ZeroAmount();

        if (address(s_strategy) != address(0)) {
            s_strategy.withdraw(assets);
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }
}
