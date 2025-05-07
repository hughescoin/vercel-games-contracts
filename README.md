# Onchain Game Contracts

This repository contains smart contracts designed to handle payments and rewards for onchain games. The contracts provide a secure and flexible way to manage entry fees and rewards in both ETH and USDC.

## Overview

The contracts serve as the backend logic for onchain games, handling:

- Entry fee collection (ETH or USDC)
- Reward distribution
- Contract funding and management
- Balance tracking

## Contracts

### GameAirdrop.sol

The base contract that provides core functionality for game payments and rewards:

- Entry fee collection in ETH or USDC
- Reward recording and claiming
- Owner-only functions for contract management
- Balance tracking for both ETH and USDC

### GameAirdropSigned.sol

An enhanced version of GameAirdrop that adds signature-based reward verification:

- All features from GameAirdrop
- Signature-based reward recording for enhanced security
- Protection against replay attacks
- Deadline-based signature validation

## Key Features

### Entry Fees

- Configurable entry fees for both ETH and USDC
- Owner can update fees independently
- Default entry fees:
  - ETH: 0.0001 ETH
  - USDC: 0.10 USDC

### Rewards

- Configurable reward amounts for both ETH and USDC
- Default rewards:
  - ETH: 0.0001 ETH
  - USDC: 1 USDC
- Secure reward claiming mechanism

### Security Features

- Owner-only functions for critical operations
- Signature verification for reward recording (GameAirdropSigned)
- Protection against replay attacks
- Safe token transfers using OpenZeppelin's SafeERC20

## Usage

1. Deploy the contract (either GameAirdrop or GameAirdropSigned)
2. Fund the contract with ETH and/or USDC
3. Players can start games by paying the entry fee
4. Record rewards for successful players
5. Players can claim their rewards

## Development

Built with:

- Solidity ^0.8.19
- OpenZeppelin Contracts
- Foundry for testing and deployment

## License

MIT

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/downloads)

## Installation

1. Clone the repository:

```bash
git clone <your-repo-url>
cd game-contracts
```

2. Install dependencies:

```bash
forge install
```

## Configuration

Create a `.env` file with the following variables:

```
BASE_RPC_URL=<your-base-rpc-url>
BASE_SEPOLIA_RPC_URL=<your-base-sepolia-rpc-url>
BASESCAN_API_KEY=<your-basescan-api-key>
PRIVATE_KEY=<your-private-key>
```

## Deployment

To deploy to Base Sepolia testnet:

```bash
source .env
forge script script/Deploy.s.sol:Deploy --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify -vvvv
```

To deploy to Base mainnet:

```bash
source .env
forge script script/Deploy.s.sol:Deploy --rpc-url $BASE_RPC_URL --broadcast --verify -vvvv
```

## Testing

Run the test suite:

```bash
forge test
```

Run tests with gas reporting:

```bash
forge test --gas-report
```

## Contract Usage

### For Players

1. Play a game by calling `playGame`:

   - Pay with ETH: Send ETH along with the call
   - Pay with USDC: Approve the contract first, then call without ETH

2. Claim rewards using `claimReward`:
   - Specify whether claiming ETH or USDC rewards
   - Rewards are sent directly to the player's wallet

### For Contract Owner

- Withdraw accumulated funds using `ownerWithdraw`
- Monitor game activity through emitted events

## Security Features

- ReentrancyGuard for all external functions
- Pull-based reward claiming
- SafeERC20 for token transfers
- Ownable access control

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
