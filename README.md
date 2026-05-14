# 🏦 Foundry Vault Production

> Built by [DylanMaas](https://github.com/DylanMaas) as part of a journey toward becoming a blockchain developer.
> This is the production-grade successor to [foundry-learning-vault](https://github.com/DylanMaas/foundry-learning-vault).

## What is this?

A production-grade tokenized vault built on the **ERC4626 standard** — the official Ethereum standard for tokenized vaults. Users deposit an ERC20 token and receive vault shares in return. As the vault's balance grows, each share becomes redeemable for more underlying tokens.

Unlike the learning vault, this implementation is fully ERC4626 compliant, making it plug-and-play with the broader DeFi ecosystem.

---

## What is ERC4626?

ERC4626 is the official Ethereum standard for tokenized vaults. Before ERC4626, every vault (Yearn, Aave, Compound) had its own interface — integrating with each required custom code. ERC4626 standardizes the interface so any DeFi protocol can interact with any compliant vault without custom integration work.

---

## The four entry points

ERC4626 defines four ways to interact with the vault, split by whether you specify what you're **paying** or what you're **receiving**:

| Function | You specify | You receive | Use case |
|---|---|---|---|
| `deposit(assets, receiver)` | exact assets to pay | whatever shares that's worth | Regular user deposit |
| `mint(shares, receiver)` | exact shares to receive | whatever assets that costs | Protocol needing exact share amounts |
| `redeem(shares, receiver, owner)` | exact shares to burn | whatever assets that's worth | Regular user withdrawal |
| `withdraw(assets, receiver, owner)` | exact assets to receive | whatever shares that costs | Paying exact bills, treasury management |

### Example — vault holds 200 USDC, 100 shares outstanding (each share worth 2 USDC):

**`deposit(100 USDC)`**
```
shares = 100 * (100 + 1) / (200 + 1) ≈ 50 shares
```
You pay 100 USDC, get ~50 shares. You control what you pay.

**`mint(50 shares)`**
```
assets = 50 * (200 + 1) / (100 + 1) ≈ 100 USDC
```
You pay ~100 USDC, get exactly 50 shares. You control what you receive.

**`redeem(50 shares)`**
```
assets = 50 * (200 + 1) / (100 + 1) ≈ 100 USDC
```
You burn 50 shares, get ~100 USDC. You control what you pay.

**`withdraw(100 USDC)`**
```
shares = 100 * (100 + 1) / (200 + 1) ≈ 50 shares
```
You burn ~50 shares, get exactly 100 USDC. You control what you receive.

**Simple rule:**
- Know what you're **paying**? → `deposit` or `redeem`
- Know what you're **receiving**? → `mint` or `withdraw`

---

## Features

### ERC4626 compliance
Full ERC4626 compliance inherited from OpenZeppelin's battle-tested implementation, 
including all four entry points, preview functions (`previewDeposit`, `previewMint`, 
`previewWithdraw`, `previewRedeem`), and max functions (`maxDeposit`, `maxMint`, 
`maxWithdraw`, `maxRedeem`).

### Inflation attack protection
ERC4626's virtual shares offset prevents the first-depositor inflation attack — where an attacker front-runs the first deposit, donates tokens to manipulate the share price, and steals subsequent depositors' funds. The `+1` virtual offset makes this attack unprofitable.

### Minimum deposit threshold
The owner can set a minimum deposit amount to prevent dust deposits and protect vault accounting:
```solidity
vault.setMinimumDeposit(100e18); // minimum 100 tokens
```

### Pausable
The owner can pause all deposits and withdrawals in an emergency:
```solidity
vault.pause();   // stop all activity
vault.unpause(); // resume
```

### Ownable
All admin functions (pause, setMinimumDeposit) are restricted to the contract owner set at deployment.

### ReentrancyGuard
Second layer of reentrancy protection on top of the CEI (Checks-Effects-Interactions) pattern.

---

## Project structure

```
src/
└── ProductionVault.sol         # The vault contract

test/
└── ProductionVaultTest.t.sol   # Tests covering deployment, accounting,
                                # deposit, mint, withdraw, redeem,
                                # pause, minimum deposit, and fuzz tests

script/
├── HelperConfig.s.sol          # Network config (Anvil vs Sepolia)
└── DeployProductionVault.s.sol # Deploy script
```

---

## Running locally

```bash
# Install dependencies
forge install

# Run tests
forge test -vv

# Deploy to local Anvil node
anvil
forge script script/DeployProductionVault.s.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

---

## What's still missing

This vault is production-grade in architecture but not yet complete. Future additions:

| Feature | Why it matters |
|---|---|
| Yield strategy | Actually deploy capital to Aave/Compound to generate yield |
| Fee mechanism | Management and performance fees |
| Fuzz test rounding | `assertApproxEqAbs` for yield accrual scenarios |
| Invariant tests | Ensure `totalAssets` always matches outstanding shares |
| Sepolia deployment | Live testnet deployment and verification |

---

## Acknowledgements

Built with guidance from Claude (Anthropic) using a step-by-step TDD approach.
Inspired by [Patrick Collins](https://github.com/PatrickAlphaC) and the Cyfrin Updraft curriculum.
Built on [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts).
