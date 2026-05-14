// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ProductionVault is ERC4626, Ownable, Pausable, ReentrancyGuard {
    // -----------------------------------------------------------------
    // Errors
    // -----------------------------------------------------------------
    error ProductionVault__ZeroAmount();
    error ProductionVault__BelowMinimumDeposit(uint256 amount, uint256 minimum);

    // -----------------------------------------------------------------
    // State Variables
    // -----------------------------------------------------------------
    uint256 public s_minimumDeposit;

    // -----------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------
    constructor(IERC20 asset_, string memory name_, string memory symbol_, address initialOwner)
        ERC4626(asset_)
        ERC20(name_, symbol_)
        Ownable(initialOwner)
    {}

    // -----------------------------------------------------------------
    // External functions
    // -----------------------------------------------------------------
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMinimumDeposit(uint256 minimumDeposit_) external onlyOwner {
        s_minimumDeposit = minimumDeposit_;
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
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        virtual
        override
        whenNotPaused
        nonReentrant
    {
        if (shares == 0) revert ProductionVault__ZeroAmount();
        super._withdraw(caller, receiver, owner, assets, shares);
    }
}
