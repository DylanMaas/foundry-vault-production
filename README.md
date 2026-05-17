# 🏦 Foundry Vault Production

> Built by [DylanMaas](https://github.com/DylanMaas) as part of a journey toward becoming a blockchain developer.
> This is the production-grade successor to [foundry-learning-vault](https://github.com/DylanMaas/foundry-learning-vault).

## What is this?

A production-grade tokenized vault built on the **ERC4626 standard**, with an **Aave V3 yield strategy**. Users deposit USDC and receive vault shares in return. The vault automatically forwards deposited USDC to Aave V3, where it earns yield. As the vault's aUSDC balance grows, each share becomes redeemable for more underlying USDC.

---

## Architecture

```
User
  │
  ▼
ProductionVault (ERC4626)
  │  - Mints/burns shares
  │  - Tracks totalAssets = vault balance + strategy balance
  │  - Owner-controlled: pause, minimum deposit, strategy
  │
  ▼
AaveStrategy
  │  - Receives USDC from vault on deposit
  │  - Supplies to Aave V3 → receives aUSDC
  │  - aUSDC balance grows over time (yield)
  │  - Returns USDC to vault on withdrawal
  │
  ▼
Aave V3 Pool (Sepolia)
```

---

## What is ERC4626?

ERC4626 is the official Ethereum standard for tokenized vaults. Before ERC4626, every vault (Yearn, Aave, Compound) had its own interface — integrating with each required custom code. ERC4626 standardizes the interface so any DeFi protocol can interact with any compliant vault without custom integration work.

---

## The four entry points

ERC4626 defines four ways to interact with the vault:

| Function | You specify | You receive | Use case |
|---|---|---|---|
| `deposit(assets, receiver)` | exact assets to pay | whatever shares that's worth | Regular user deposit |
| `mint(shares, receiver)` | exact shares to receive | whatever assets that costs | Protocol needing exact share amounts |
| `redeem(shares, receiver, owner)` | exact shares to burn | whatever assets that's worth | Regular user withdrawal |
| `withdraw(assets, receiver, owner)` | exact assets to receive | whatever shares that costs | Paying exact bills, treasury management |

**Simple rule:**
- Know what you're **paying**? → `deposit` or `redeem`
- Know what you're **receiving**? → `mint` or `withdraw`

---

## Features

### ERC4626 compliance
Full ERC4626 compliance inherited from OpenZeppelin's battle-tested implementation, including all four entry points, preview functions, and max functions.

### Aave V3 yield strategy
Deposited USDC is automatically supplied to Aave V3 via `AaveStrategy`. The vault's `totalAssets` includes both the vault's direct balance and the strategy's aUSDC balance, so yield accrues automatically to all shareholders.

### Inflation attack protection
ERC4626's virtual shares offset (`+1`) prevents the first-depositor inflation attack where an attacker manipulates the share price to steal subsequent deposits.

### Minimum deposit threshold
The owner can set a minimum deposit to prevent dust deposits:
```solidity
vault.setMinimumDeposit(100e6); // minimum 100 USDC
```

### Pausable
Emergency stop mechanism — owner can pause all deposits and withdrawals:
```solidity
vault.pause();
vault.unpause();
```

### Ownable + ReentrancyGuard
All admin functions restricted to the contract owner. Double reentrancy protection via CEI pattern and OpenZeppelin's `ReentrancyGuard`.

---

## Project structure

```
src/
├── ProductionVault.sol          # ERC4626 vault with strategy routing
└── strategies/
    └── AaveStrategy.sol         # Aave V3 yield strategy

test/
├── ProductionVaultTest.t.sol    # 22 tests: deployment, accounting,
│                                # deposit, mint, withdraw, redeem,
│                                # pause, minimum deposit, fuzz tests
└── AaveStrategyTest.t.sol       # 3 tests: strategy integration with
                                 # real Aave V3 on Sepolia fork

script/
├── HelperConfig.s.sol           # Network config (Anvil vs Sepolia)
└── DeployProductionVault.s.sol  # Deploys vault + strategy
```

---

## Running tests

### Without fork (Anvil — fast, no strategy)
```bash
forge test --match-path test/ProductionVaultTest.t.sol -vv
```

### With Sepolia fork (includes Aave strategy tests)
```bash
source .env
forge test --fork-url $SEPOLIA_RPC_URL --fork-block-number 7600000 -vv
```

Requires a `.env` file with:
```
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

### Deploy to local Anvil
```bash
anvil
forge script script/DeployProductionVault.s.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

---

## Known limitations and shortcuts

This is a portfolio/learning project. The following shortcuts were made to get all 25 tests passing — a production deployment would need to address these:

**Sepolia USDC supply cap**
The Aave V3 Sepolia pool has a supply cap on USDC. Fork tests are pinned to block `7600000` where the cap was not yet exceeded. Running tests at the latest block would hit error `51` (`SUPPLY_CAP_EXCEEDED`). In production, supply cap management would be handled by monitoring and governance.

**Two USDC tokens on Sepolia**
There are two USDC contracts on Sepolia — Circle's official USDC (`0x1c7D4B...`) and Aave's testnet USDC (`0x94a9D9...`). The vault uses Aave's testnet USDC because it is the one supported by the Aave V3 Sepolia pool. On mainnet, there is only one USDC.

**`deal` instead of `mint`**
Tests use Foundry's `deal` cheatcode to give users token balances instead of calling `mint`. This is necessary because real USDC (FiatToken) restricts minting to authorized addresses. `deal` directly manipulates storage — acceptable in tests, not possible in production.

**Fuzz test bounds**
Fuzz tests are bounded to `1e6 - 1000e6` (1 to 1000 USDC) to stay within Aave's supply cap on the forked block. Real production fuzz tests would use mainnet forks with much higher bounds.

**`assertApproxEqAbs` with 1 wei tolerance**
Some assertions allow a 1 wei difference due to rounding in Aave's aToken math and ERC4626's virtual offset. This is expected and acceptable in production — no funds are lost, it's purely a precision artifact.

**Hardcoded block number**
Fork tests use `--fork-block-number 7600000` to ensure reproducibility. Without pinning the block, Aave's state changes between test runs would cause non-deterministic failures.

---

## Sepolia addresses used

| Contract | Address |
|---|---|
| Aave V3 Pool | `0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951` |
| Aave testnet USDC | `0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8` |
| aUSDC (Sepolia) | `0x16dA4541aD1807f4443d92D26044C1147406EB80` |

---

## What's next

| Feature | Why it matters |
|---|---|
| Mainnet fork tests | More realistic testing against production Aave |
| Fee mechanism | Management and performance fees |
| Invariant tests | Ensure `totalAssets` always backs outstanding shares |
| Strategy switchability | Owner can swap strategies without migrating funds |
| Sepolia live deployment | Deploy and verify on Sepolia Etherscan |

---

## Acknowledgements

Built with guidance from Claude (Anthropic) using a step-by-step TDD approach.
Inspired by [Patrick Collins](https://github.com/PatrickAlphaC) and the Cyfrin Updraft curriculum.
Built on [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) and [Aave V3](https://github.com/aave/aave-v3-core).
