# 100 Solidity Smart Contracts

A hands-on learning repo for Solidity and Web3. The goal is to implement **100 smart contracts** from scratch — covering tokens, DeFi primitives, auctions, governance, and more.

> Educational / practice code. Not audited. Do not deploy to mainnet with real funds.

## Progress

| Status | Count |
|--------|------:|
| Written | 12 |
| Target | 100 |

## Contracts

| # | File | What it teaches |
|---|------|-----------------|
| 1 | [`ERE-20.sol`](./ERE-20.sol) | Custom ERC-20: mint, burn, transfer, allowance |
| 2 | [`Escrow.sol`](./Escrow.sol) | ETH escrow with arbiter approve / refund |
| 3 | [`DutchAuction.sol`](./DutchAuction.sol) | Time-decaying price auction |
| 4 | [`TokenVesting.sol`](./TokenVesting.sol) | Cliff + linear token vesting |
| 5 | [`AMM.sol`](./AMM.sol) | Constant-product AMM with LP tokens |
| 6 | [`Collateral.sol`](./Collateral.sol) | Collateralized deposits / withdrawals |
| 7 | [`Overcollateralized-Lending.sol`](./Overcollateralized-Lending.sol) | Overcollateralized borrow / repay |
| 8 | [`Staking.sol`](./Staking.sol) | Token staking with rewards |
| 9 | [`Fee-spliter.sol`](./Fee-spliter.sol) | Multi-recipient fee split |
| 10 | [`Voting.sol`](./Voting.sol) | Multi-owner confirmation / voting |
| 11 | [`Markle-Airdrop.sol`](./Markle-Airdrop.sol) | Merkle-proof token airdrop |
| 12 | [`Splitting.sol`](./Splitting.sol) | Placeholder / in progress |

## Tooling

- **Solidity** `0.8.26`
- **ethers.js** `v6` — used by `tools/gen.js` to build Merkle trees for the airdrop contract

```bash
npm install
node tools/gen.js   # generates data/airdrop-data.json (root + proofs)
```

## Structure

```
smart-contracts/
├── *.sol                 # practice contracts
├── tools/
│   └── gen.js            # Merkle tree generator for airdrop
├── data/
│   └── airdrop-data.json # sample root / claims / proofs
├── package.json
└── README.md
```

## How I'm learning

Each contract focuses on one pattern:

1. Write the happy path (deposit, transfer, claim, etc.)
2. Add custom errors and events
3. Think about access control and edge cases
4. Move on to the next pattern

## Disclaimer

These contracts are for learning Solidity. They may contain bugs, incomplete logic, or insecure patterns on purpose while I'm practicing. Treat them as study notes, not production code.

## License

See SPDX headers in each file (`SEE LICENSE IN LICENSE`).
