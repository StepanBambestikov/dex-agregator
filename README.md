# Cross-Chain DEX Aggregator

[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)](https://soliditylang.org/)
[![Forge](https://img.shields.io/badge/Built%20with-Forge-orange)](https://getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Project Overview

A cross-chain decentralized exchange (DEX) aggregator that enables optimal token swaps across multiple blockchain networks while providing the best available rates from integrated DEX platforms.

## Key Features

- **Multi-Chain Support**: Works across Ethereum, Arbitrum, and Optimism (mainnets and testnets)
- **DEX Integration**: Supports Uniswap V2/V3 and SushiSwap
- **Cross-Chain Messaging**: Utilizes Axelar Network for secure cross-chain communication

## Technical Architecture

### Cross chain logic

![alt text](https://github.com/StepanBambestikov/dex-agregator/blob/main/images/crosschainLogic.png?raw=true)

### Inner chain logic

![alt text](https://github.com/StepanBambestikov/dex-agregator/blob/main/images/innerLogic.png?raw=true)

### Core Components

1. **InnerChainRouter**: Handles intra-chain swaps and route optimization
2. **InnerChainRegistry**: Manages registered DEX adapters within a chain
3. **OuterChainRouter**: Facilitates cross-chain transactions via Axelar
4. **OuterChainRegistry**: Stores cross-chain configuration and partner router addresses
5. **DEX Adapters**: Modular integrations with various DEX protocols

The project does not provide for taking a commission for executing swap and cross-chain transfer commands.
Therefore, the execution of commands is limited to a maximum of one transfer across the bridge, for which the user pays a commission.

## Deployment

### Supported Networks

| Network  | Status  | DEX Support              |
| -------- | ------- | ------------------------ |
| Ethereum | ✅ Live | Uniswap V2/V3, SushiSwap |
| Arbitrum | ✅ Live | SushiSwap, Uniswap V3    |
| Optimism | ✅ Live | Uniswap V3               |

### Deployment Scripts

```bash
# Deploy to Ethereum
forge script script/DeployWithConfig.s.sol:DeployWithConfig --rpc-url ETH_RPC_URL --sig "deployToEthereum()" --broadcast -vvvv

# Deploy to Arbitrum
forge script script/DeployWithConfig.s.sol:DeployWithConfig --rpc-url ARB_RPC_URL --sig "deployToArbitrum()" --broadcast -vvvv

# Deploy to Optimism
forge script script/DeployWithConfig.s.sol:DeployWithConfig --rpc-url OPT_RPC_URL --sig "deployToOptimism()" --broadcast -vvvv
```

## Configuration

Set up your environment variables in `.env`:

```ini
ETH_RPC_URL=https://eth-mainnet.alchemyapi.io/v2/YOUR_KEY
ARB_RPC_URL=https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY
OPT_RPC_URL=https://opt-mainnet.g.alchemy.com/v2/YOUR_KEY
ETHERSCAN_API_KEY=YOUR_KEY
ARBISCAN_API_KEY=YOUR_KEY
```

## Usage Examples

### Cross-Chain Swap (Ethereum → Arbitrum)

````solidity
// Initialize routers
IOuterChainRouter outerRouter = IOuterChainRouter(0x...);
IInnerChainRouter innerRouter = IInnerChainRouter(0x...);

## Development

### Prerequisites

- Foundry (forge, cast, anvil)
- Git

### Setup

1. Clone repository:

```bash
git clone https://github.com/your-repo/cross-chain-dex.git
cd cross-chain-dex
````

2. Install dependencies:

```bash
forge install
```

3. Build project:

```bash
forge build
```

### Testing

Run all tests:

```bash
forge test -vv
```

Run specific test suite:

```bash
forge test --match-test testUniswapV2Swaps -vv
```

## Deploy ethereum sepolia

```
=== Deploying to ethereum ===
  Deployed InnerChainRegistry at: 0xe1bad821B0a748Ddf7ee2Ad44BA7d1AC2E5fe067
  Deployed UniswapV2Adapter at: 0xd6F782e84C08C67D3cb79f70e1DEB383264398dd
  Deployed SushiSwapAdapter at: 0x4b6360969530926Ac9d9B2A98799d965e6755667
  Deployed UniswapV3Adapter at: 0x15c8D1cDF375893eCA8F3ff5702EBf9640d220f9
  Deployed InnerChainRouter at: 0x744C68430876469F5abBE9fECF483AEB5A4820A8
  Deployed OuterChainRegistry at: 0x22c99651FdB8Da16390d833cde5d268122e7475B
  Deployed OuterChainRouterAxelar at: 0xd993A31234C12139022b2351495EFD1E124be0cD

=== Deployment Summary ===
  Network: ethereum
  Destination Chain: optimism
  --------------------------
  Core Contracts:
  - InnerChainRegistry: 0xe1bad821B0a748Ddf7ee2Ad44BA7d1AC2E5fe067
  - InnerChainRouter: 0x744C68430876469F5abBE9fECF483AEB5A4820A8
  - OuterChainRegistry: 0x22c99651FdB8Da16390d833cde5d268122e7475B
  - OuterChainRouter: 0xd993A31234C12139022b2351495EFD1E124be0cD
  --------------------------
  DEX Adapters Configured:
  - UniswapV2: Enabled
  - SushiSwap: Enabled
  - UniswapV3: Enabled
  --------------------------
  Axelar Configuration:
  - Gateway: 0x4F4495243837681061C4743b74B3eEdf548D56A5
  - Gas Service: 0x2d5d7d31F671F86C782533cc367F14109a082712
```
