# Ozean-Contracts

This is a [Foundry](https://book.getfoundry.sh/) repo for the set of custom Ozean L2 smart contracts. 

## Useful Commands
- `forge test -vvv`
- `forge coverage --report lcov`

## Layer One Deployments

### Mainnet

TBD

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
| **ozUSD Impl (DEPRECATED)** | [0x9e76FE3E3859A4BF1C30d2DAD7b3C35d8654Eb50](https://ozean-testnet.explorer.caldera.xyz/address/0x9e76FE3E3859A4BF1C30d2DAD7b3C35d8654Eb50)|
| **ozUSD Proxy (DEPRECATED)** | [0x1Ce4888a6dED8d6aE5F5D9ca1CABc758c680950b](https://ozean-testnet.explorer.caldera.xyz/address/0x1Ce4888a6dED8d6aE5F5D9ca1CABc758c680950b)|
| **wozUSD (DEPRECATED)**  | [0x2f6807b76c426527C3a5C442E8697f12C554195b](https://ozean-testnet.explorer.caldera.xyz/address/0x2f6807b76c426527C3a5C442E8697f12C554195b)|


### TECH DEBT

- Several remappings are un-intuitive and only made to navigate audit milestones + dependency bad practices. Before next audit, clean up with more liberal use of interfaces.
- Most of these contracts are built for the OP custom gas token branch, which is now deprecated, everything except the `LGE Staking` contract needs updating for the new environment
