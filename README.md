# Ozean-Contracts

This is a [Foundry](https://book.getfoundry.sh/) repo for the set of custom Ozean L2 smart contracts. 

## Useful Commands
- `forge test -vvv`
- `forge coverage --report lcov`

## Layer Zero
- [LayerZeroScan](https://testnet.layerzeroscan.com/)
- [OFT Implementation](https://docs.layerzero.network/v2/developers/evm/oft/quickstart)
- [Endpoints](https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts)


## Layer One Deployments

### Mainnet

#### Contracts:

| **Contract** | **Address** |
|:---:|:---:|
| **LGE Staking** | [0xdD4297dECCE33fdA78dB8330832b51F3df610db9](https://eth.blockscout.com/address/0xdD4297dECCE33fdA78dB8330832b51F3df610db9?tab=contract_source_code)|

#### LGE Staking Assets/Cap:

| **Asset** | **Address** | **Deposit Cap** | **Decimals** |
|:---:|:---:|:---:|:---:|
| **WBTC** | [0x2260fac5e5542a773aa44fbcfedf7c193bc2c599](https://etherscan.io/address/0x2260fac5e5542a773aa44fbcfedf7c193bc2c599)| 100_000_000 | 8 |
| **SolvBTC** | [0x7a56e1c57c7475ccf742a1832b028f0456652f97](https://etherscan.io/address/0x7a56e1c57c7475ccf742a1832b028f0456652f97)| 100_000_000 | 18 |
| **WSOL** | [0xD31a59c85aE9D8edEFeC411D448f90841571b89c](https://etherscan.io/address/0xD31a59c85aE9D8edEFeC411D448f90841571b89c)| 100_000_000 | 9 |
| **WstETH** | [0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0](https://etherscan.io/address/0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0)| 100_000_000 | 18 |
| **WETH** | [0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2](https://etherscan.io/address/0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)| 100_000_000 | 18 |
| **SUSDE** | [0x9D39A5DE30e57443BfF2A8307A4256c8797A3497](https://etherscan.io/address/0x9D39A5DE30e57443BfF2A8307A4256c8797A3497)| 100_000_000 | 18 |
| **USDY** | [0x96F6eF951840721AdBF46Ac996b59E0235CB985C](https://etherscan.io/address/0x96F6eF951840721AdBF46Ac996b59E0235CB985C)| 100_000_000 | 18 |
| **WUSDM** | [0x57F5E098CaD7A3D1Eed53991D4d66C45C9AF7812](https://etherscan.io/address/0x57F5E098CaD7A3D1Eed53991D4d66C45C9AF7812)| 100_000_000 | 18 |
| **USDX** | [0xf8750b54d86BE7aE9e32b4A0C826811198D63313](https://etherscan.io/address/0xf8750b54d86BE7aE9e32b4A0C826811198D63313)| 100_000_000 | 18 |
| **USDC** | [0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48](https://etherscan.io/address/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)| 100_000_000 | 6 |

[**LGE Staking Admin**](https://etherscan.io/address/0x8A358c6ef869e3A1110398cC12581deB5946eB1a#code)

### Sepolia

#### Contracts:

| **Contract** | **Address** |
|:---:|:---:|
| **USDX** | [0x43bd82D1e29a1bEC03AfD11D5a3252779b8c760c](https://sepolia.etherscan.io/token/0x43bd82d1e29a1bec03afd11d5a3252779b8c760c#code)|
| **USDX Bridge (DEPRECATED)** | [0x084C27a0bE5dF26ed47F00678027A6E76B14a0B4](https://sepolia.etherscan.io/address/0x084c27a0be5df26ed47f00678027a6e76b14a0b4#code)|
| **LGE Staking** | [0xBAFAAfC8E2d8F6Ebf9Fa49646C36D640B4e07203](https://sepolia.etherscan.io/address/0xBAFAAfC8E2d8F6Ebf9Fa49646C36D640B4e07203#code)|

#### USDX Bridge Assets/Cap:
| **Asset** | **Address** |**Deposit Cap** |
|:---:|:---:|:---:|
| **USDT** | [0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0](https://sepolia.etherscan.io/address/0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0)| 1_000_000_000_000 |
| **DAI** | [0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357](https://sepolia.etherscan.io/address/0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357)| 1_000_000_000_000 |
| **USDC** | [0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8](https://sepolia.etherscan.io/address/0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8)| 1_000_000_000_000 |
| **USDC** | [0x15795aadca3759d7b356DecE036c285b1FBb32aa](https://sepolia.etherscan.io/address/0x15795aadca3759d7b356DecE036c285b1FBb32aa)| 1_000_000_000_000 |

#### LGE Staking Assets/Cap:

| **Asset** | **Address** |**Deposit Cap** |
|:---:|:---:|:---:|
| **wstETH** | [0xB82381A3fBD3FaFA77B3a7bE693342618240067b](https://sepolia.etherscan.io/address/0xB82381A3fBD3FaFA77B3a7bE693342618240067b)| 1_000_000 |
| **WBTC** | [0x29f2D40B0605204364af54EC677bD022dA425d03](https://sepolia.etherscan.io/address/0x29f2D40B0605204364af54EC677bD022dA425d03)| 1_000_000 |
| **USDT** | [0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0](https://sepolia.etherscan.io/address/0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0)| 1_000_000 |
| **DAI** | [0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357](https://sepolia.etherscan.io/address/0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357)| 1_000_000 |
| **USDC** | [0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8](https://sepolia.etherscan.io/address/0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8)| 1_000_000 |
| **AAVE** | [0x88541670E55cC00bEEFD87eB59EDd1b7C511AC9a](https://sepolia.etherscan.io/address/0x88541670E55cC00bEEFD87eB59EDd1b7C511AC9a)| 1_000_000 |

[**Aave Faucet**](https://app.aave.com/faucet/)

## Layer Two Deployments

### Ozean Mainnet

TBD

### Ozean Poseidon

#### Contracts:

| **Contract** | **Address** |
|:---:|:---:|
| **ozUSDV2** | [0x743af9531E0f9944E42C2a74D9C65514925d6830](https://poseidon-testnet.explorer.caldera.xyz/address/0x743af9531E0f9944E42C2a74D9C65514925d6830)|
| **ozUSD Impl (DEPRECATED)** | [0x9e76FE3E3859A4BF1C30d2DAD7b3C35d8654Eb50](https://ozean-testnet.explorer.caldera.xyz/address/0x9e76FE3E3859A4BF1C30d2DAD7b3C35d8654Eb50)|
| **ozUSD Proxy (DEPRECATED)** | [0x1Ce4888a6dED8d6aE5F5D9ca1CABc758c680950b](https://ozean-testnet.explorer.caldera.xyz/address/0x1Ce4888a6dED8d6aE5F5D9ca1CABc758c680950b)|
| **wozUSD (DEPRECATED)**  | [0x2f6807b76c426527C3a5C442E8697f12C554195b](https://ozean-testnet.explorer.caldera.xyz/address/0x2f6807b76c426527C3a5C442E8697f12C554195b)|

