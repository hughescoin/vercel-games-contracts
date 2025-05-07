# plan.md

## 🎯 Project Overview

This project implements a simplified airdrop and payout system for short, deterministic onchain games like **Three Card Monte** and **Hangman**, using **Foundry v0.2.13** and **OpenZeppelin Contracts v5**.

### Key Features:

- Players pay to play using **ETH** or **USDC (ERC-20)**.
- If a player wins, they earn a **claimable reward** stored in the contract.
- Players must manually **claim their reward** (pull-based model).
- If players lose, no reward is recorded.
- The **contract owner** can withdraw leftover/forfeited funds accumulated from losses.

No complex game state is stored onchain. Win/loss logic is expected to be handled offchain or validated in frontend/backend flows.

---

## 🧱 Core Contract: `GameAirdrop.sol`

A single smart contract to handle:

- Receiving ETH or USDC payments from players.
- Recording reward balances for winners.
- Allowing users to claim their rewards in the same token used for payment.
- Letting the contract owner withdraw accumulated funds (e.g., from player losses).

### Key Functions

- `playGame(bool payWithETH, bool didWin, uint256 rewardAmount)`  
  Accepts a payment, and if the player wins, registers a reward.

- `claimReward(bool isETH)`  
  Lets players withdraw their rewards.

- `ownerWithdraw(address token, uint256 amount)`  
  Allows the owner to withdraw excess/unclaimed ETH or USDC.

---

## 🔐 Security & Safeguards

- **Reentrancy protection** for all claim and withdraw functions.
- **SafeERC20** and **Address.sendValue** used for secure fund handling.
- **OnlyOwner** modifier on `ownerWithdraw`.
- Win validation (`didWin`) is passed in externally for flexibility. Frontend/backend is responsible for validation in this version.

---

## 🧪 Testing & Tooling

- **Framework**: Foundry v0.2.13
- **Utilities**:
  - `forge-std` for test utilities
  - `ds-test` for assertions
- **Deployment**:
  - `forge script` for contract deployment
  - Use a Mock USDC token for local testing

---

## 🧰 Tech Stack

| Component      | Tooling                             |
| -------------- | ----------------------------------- |
| Language       | Solidity ^0.8.20                    |
| Framework      | Foundry v0.2.13                     |
| Token Support  | ETH & USDC (ERC-20)                 |
| Contracts Used | OpenZeppelin v5                     |
| Security Tools | ReentrancyGuard, Ownable, SafeERC20 |
| Reward Model   | Pull-based only                     |
| Game Examples  | Three Card Monte, Hangman           |

---

Let me know if you want to break out game-specific logic into separate contracts or keep everything in this central airdrop/payout manager.
