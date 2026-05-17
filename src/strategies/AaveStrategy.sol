// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPool} from "@aave/contracts/interfaces/IPool.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AaveStrategy is Ownable {
    using SafeERC20 for IERC20;

    // -----------------------------------------------------------------
    // State
    // -----------------------------------------------------------------
    IPool public immutable i_aavePool;
    IERC20 public immutable i_asset;
    IERC20 public immutable i_aToken;
    address public immutable i_vault;

    // -----------------------------------------------------------------
    // Errors
    // -----------------------------------------------------------------
    error AaveStrategy__OnlyVault();

    // -----------------------------------------------------------------
    // Modifiers
    // -----------------------------------------------------------------
    modifier onlyVault() {
        if (msg.sender != i_vault) revert AaveStrategy__OnlyVault();
        _;
    }

    // -----------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------
    constructor(address aavePool_, address asset_, address aToken_, address vault_, address owner_) Ownable(owner_) {
        i_aavePool = IPool(aavePool_);
        i_asset = IERC20(asset_);
        i_aToken = IERC20(aToken_);
        i_vault = vault_;
    }

    // -----------------------------------------------------------------
    // External functions
    // -----------------------------------------------------------------

    function deposit(uint256 amount_) external onlyVault {
        i_asset.forceApprove(address(i_aavePool), amount_);
        i_aavePool.supply(address(i_asset), amount_, address(this), 0);
        // pulls USDC from vault, approves Aave pool, supplies to Aave
    }

    function withdraw(uint256 amount_) external onlyVault {
        i_aavePool.withdraw(address(i_asset), amount_, i_vault);
        // withdraws from Aave and sends directly to vault
    }

    function totalAssets() external view returns (uint256) {
        return i_aToken.balanceOf(address(this));
        // reads aUSDC balance which grows automatically as yield accrues
    }
}
