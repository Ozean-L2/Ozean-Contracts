# Ozean-Contracts

This is a [Foundry](https://book.getfoundry.sh/) repo for the set of custom Ozean L2 smart contracts. 

## Useful Commands
- `forge test -vvv`
- `forge coverage --report lcov`

## Deployment Flow
- Run the following deployment script, replacing the `{$PRIVATE_KEY}`, `{$PATH}`, and `{$RPC_URL}` values as necessary: `forge script {$PATH} --private-key {$PRIVATE_KEY --rpc-url {$RPC_URL} --broadcast`
- Produce the standard input JSON file using the following command: `forge verify-contract --compiler-version 0.8.28 --show-standard-json-input {$CONTRACT_ADDRESS} {$CONTRACT_NAME}`
- Use the produced file to verify the contract on the relevant block explorers.
- Consult [this documentation](https://book.getfoundry.sh/forge/deploying) for more information.

## Layer Zero
- [LayerZeroScan](https://testnet.layerzeroscan.com/)
- [OFT Implementation](https://docs.layerzero.network/v2/developers/evm/oft/quickstart)
- [Endpoints](https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts)

## Layer One Deployments

### Mainnet

#### Contracts:

| **Contract** | **Address** |
|:---:|:---:|
| **LGE Staking** | [0xdD4297dECCE33fdA78dB8330832b51F3df610db9](https://etherscan.io/address/0xdD4297dECCE33fdA78dB8330832b51F3df610db9#code)|

[LGE Staking Admin](https://etherscan.io/address/0x8A358c6ef869e3A1110398cC12581deB5946eB1a#code)

### Sepolia

#### Contracts:

The `USDX (Basic ERC20)` contract is a basic ERC20 token that allows for infinite minting and is a simple stand-in for USDX on Sepolia. In contrast, the `USDX (Hex Trust L0 Path)` contract has been deployed by Hex Trust and is the official testnet deployment related to [this repo](https://github.com/hextrust/hex-stablecoin-usd). Layer Zero is not currently supported on the Ozean testnet and so in order to produce an E2E test flow the USDX bridging, the Flare testnet in used instead.

Note that the `USDXBridgeAlt` contract does not have minting rights for USDX, and needs to be seeded with tokens for the bridge to work. Additionally, the bridge is configured for the [Flare Testnet](https://testnet.flarescan.com/).

Testnet tokens can be minted for free from the [Aave Faucet](https://app.aave.com/faucet/).

| **Contract** | **Address** |
|:---:|:---:|
| **USDX (Basic ERC20)** | [0x43bd82D1e29a1bEC03AfD11D5a3252779b8c760c](https://sepolia.etherscan.io/token/0x43bd82d1e29a1bec03afd11d5a3252779b8c760c#code)|
| **USDX (Hex Trust L0 Path)** | [0x5DB6dA53eF70870f20d3E90Fa7c518A95C4B1563](https://sepolia.etherscan.io/address/0x5DB6dA53eF70870f20d3E90Fa7c518A95C4B1563)|
| **USDX Bridge Alt (L0 Flare Path)** | [0x14D72e0C6f6b1117CfBF6a66C79158c8d6a18bC7](https://eth-sepolia.blockscout.com/address/0x14D72e0C6f6b1117CfBF6a66C79158c8d6a18bC7)|
| **USDX Bridge (OP Standard Bridge Path)** | [0x850964Bc9C2D10510BD62b8d325d0888e78391C1](https://sepolia.etherscan.io/address/0x850964Bc9C2D10510BD62b8d325d0888e78391C1#writeContract)|
| **LGE Staking** | [0xBAFAAfC8E2d8F6Ebf9Fa49646C36D640B4e07203](https://sepolia.etherscan.io/address/0xBAFAAfC8E2d8F6Ebf9Fa49646C36D640B4e07203#code)|

## Layer Two Deployments

### Ozean Mainnet

TBD...

### Ozean Poseidon

#### Contracts:

| **Contract** | **Address** |
|:---:|:---:|
| **USDX (OP Standard Bridge Path)** | [0xe29f6fbc4CB3F01e2D38F0Aab7D8861285EE9C36](https://poseidon-testnet.explorer.caldera.xyz/token/0xe29f6fbc4CB3F01e2D38F0Aab7D8861285EE9C36?tab=contract)|
| **ozUSDV2 (OP Standard Bridge Path)** | [0x743af9531E0f9944E42C2a74D9C65514925d6830](https://poseidon-testnet.explorer.caldera.xyz/address/0x743af9531E0f9944E42C2a74D9C65514925d6830)|

### Flare Testnet

| **Contract** | **Address** |
|:---:|:---:|
| **USDX (L0 Flare Path)** | [0x6ccB96ae6D52e88ed2269288F5e47bD2914C2785](https://testnet.flarescan.com/token/0x6ccB96ae6D52e88ed2269288F5e47bD2914C2785?type=erc20&chainid=114)|