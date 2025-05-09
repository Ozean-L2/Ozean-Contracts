// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract Constants {
    address public constant ADMIN = 0xe43420E1f83530AAf8ad94e6904FDbdc3556Da2B;
    uint256 public constant INITIAL_SHARE_AMOUNT = 1000000000000000000;

    /// Flare id for L0 testing
    uint32 public constant EID = 30295;
    uint32 public constant TESTNET_EID = 40294;

    address public constant L1_MAINNET_STANDARD_BRIDGE = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
    address public constant L1_MAINNET_LIDO_BRIDGE = address(420);
    address public constant L1_MAINNET_USDX_BRIDGE = address(420);
    address public constant L1_MAINNET_LGE_STAKING = 0xdD4297dECCE33fdA78dB8330832b51F3df610db9;
    address public constant L1_MAINNET_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant L1_MAINNET_USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant L1_MAINNET_DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant L1_MAINNET_WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant L1_MAINNET_WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant L1_MAINNET_USDX = 0xf8750b54d86BE7aE9e32b4A0C826811198D63313;
    address public constant L2_MAINNET_USDX = address(69);
    address public constant L2_MAINNET_OZUSD = address(69);

    address public constant L1_SEPOLIA_STANDARD_BRIDGE = 0x8f42BD64b98f35EC696b968e3ad073886464dEC1;
    address public constant L1_SEPOLIA_LIDO_BRIDGE = 0xd836932faEaC34FdFF0bb14696E92bA33805D4E3;
    address public constant L1_SEPOLIA_USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
    address public constant L1_SEPOLIA_USDT = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;
    address public constant L1_SEPOLIA_DAI = 0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357;
    address public constant L1_SEPOLIA_WSTETH = 0xB82381A3fBD3FaFA77B3a7bE693342618240067b;
    address public constant L1_SEPOLIA_WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address public constant L1_SEPOLIA_USDX = 0x43bd82D1e29a1bEC03AfD11D5a3252779b8c760c;
    address public constant L2_SEPOLIA_USDX = 0xe29f6fbc4CB3F01e2D38F0Aab7D8861285EE9C36;
    address public constant L2_SEPOLIA_OZUSD = 0x743af9531E0f9944E42C2a74D9C65514925d6830;

    /// LGE STAKING ///

    function _getMainnetLGEArrays()
        internal
        pure
        returns (address[] memory L1_MAINNET_LGE_TOKENS, uint256[] memory L1_MAINNET_LGE_CAPS)
    {
        /// Ensure token address and deposit caps share the same index
        /// and are normalised for decimals.
        /// Tokens: WBTC, SolvBTC, WSOL, WstETH, WETH, SUSDE, USDY, WUSDM, USDX, USDC
        /// Caps  : 1e16, 1e26   , 1e17, 1e26  , 1e26, 1e26 , 1e26, 1e26 , 1e26, 1e14
        /// Decis : 8   , 18     , 9   , 18    , 18  , 18   , 18  , 18   , 18  , 6
        L1_MAINNET_LGE_TOKENS = new address[](10);
        L1_MAINNET_LGE_TOKENS[0] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        L1_MAINNET_LGE_TOKENS[1] = 0x7A56E1C57C7475CCf742a1832B028F0456652F97;
        L1_MAINNET_LGE_TOKENS[2] = 0xD31a59c85aE9D8edEFeC411D448f90841571b89c;
        L1_MAINNET_LGE_TOKENS[3] = L1_MAINNET_WSTETH;
        L1_MAINNET_LGE_TOKENS[4] = L1_MAINNET_WETH;
        L1_MAINNET_LGE_TOKENS[5] = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;
        L1_MAINNET_LGE_TOKENS[6] = 0x96F6eF951840721AdBF46Ac996b59E0235CB985C;
        L1_MAINNET_LGE_TOKENS[7] = 0x57F5E098CaD7A3D1Eed53991D4d66C45C9AF7812;
        L1_MAINNET_LGE_TOKENS[8] = L1_MAINNET_USDX;
        L1_MAINNET_LGE_TOKENS[9] = L1_MAINNET_USDC;

        L1_MAINNET_LGE_CAPS = new uint256[](10);
        L1_MAINNET_LGE_CAPS[0] = 10000000000000000;
        L1_MAINNET_LGE_CAPS[1] = 100000000000000000000000000;
        L1_MAINNET_LGE_CAPS[2] = 100000000000000000;
        L1_MAINNET_LGE_CAPS[3] = 100000000000000000000000000;
        L1_MAINNET_LGE_CAPS[4] = 100000000000000000000000000;
        L1_MAINNET_LGE_CAPS[5] = 100000000000000000000000000;
        L1_MAINNET_LGE_CAPS[6] = 100000000000000000000000000;
        L1_MAINNET_LGE_CAPS[7] = 100000000000000000000000000;
        L1_MAINNET_LGE_CAPS[8] = 100000000000000000000000000;
        L1_MAINNET_LGE_CAPS[9] = 100000000000000;
    }

    function _getSepoliaLGEArrays()
        internal
        pure
        returns (address[] memory L1_SEPOLIA_LGE_TOKENS, uint256[] memory L1_SEPOLIA_LGE_CAPS)
    {
        /// Tokens: WETH, USDC, USDT,  DAI, WSTETH
        /// Caps  : 1e24, 1e12, 1e12, 1e24,   1e24
        L1_SEPOLIA_LGE_TOKENS = new address[](5);
        L1_SEPOLIA_LGE_TOKENS[0] = L1_SEPOLIA_WETH;
        L1_SEPOLIA_LGE_TOKENS[1] = L1_SEPOLIA_USDC;
        L1_SEPOLIA_LGE_TOKENS[2] = L1_SEPOLIA_USDT;
        L1_SEPOLIA_LGE_TOKENS[3] = L1_SEPOLIA_DAI;
        L1_SEPOLIA_LGE_TOKENS[4] = L1_SEPOLIA_WSTETH;

        L1_SEPOLIA_LGE_CAPS = new uint256[](5);
        L1_SEPOLIA_LGE_CAPS[0] = 1000000000000000000000000;
        L1_SEPOLIA_LGE_CAPS[1] = 1000000000000;
        L1_SEPOLIA_LGE_CAPS[2] = 1000000000000;
        L1_SEPOLIA_LGE_CAPS[3] = 1000000000000000000000000;
        L1_SEPOLIA_LGE_CAPS[4] = 1000000000000000000000000;
    }

    /// LGE MIGRATION V1 ///

    function _getMainnetMigrationArrays()
        internal
        pure
        returns (
            address[] memory L1_MAINNET_ADDRESSES,
            address[] memory L2_MAINNET_ADDRESSES,
            address[] memory L2_MAINNET_RESTRICTED_ADDRESSES
        )
    {}

    function _getSepoliaMigrationArrays()
        internal
        pure
        returns (
            address[] memory L1_SEPOLIA_ADDRESSES,
            address[] memory L2_SEPOLIA_ADDRESSES,
            address[] memory L2_SEPOLIA_RESTRICTED_ADDRESSES
        )
    {
        /// Tokens: USDC, USDT, DAI, WSTETH
        L1_SEPOLIA_ADDRESSES = new address[](4);
        L1_SEPOLIA_ADDRESSES[0] = L1_SEPOLIA_USDC;
        L1_SEPOLIA_ADDRESSES[1] = L1_SEPOLIA_USDT;
        L1_SEPOLIA_ADDRESSES[2] = L1_SEPOLIA_DAI;
        L1_SEPOLIA_ADDRESSES[3] = L1_SEPOLIA_WSTETH;

        /// Incorrect except final address
        L2_SEPOLIA_ADDRESSES = new address[](4);
        L2_SEPOLIA_ADDRESSES[0] = L1_SEPOLIA_USDC;
        L2_SEPOLIA_ADDRESSES[1] = L1_SEPOLIA_USDT;
        L2_SEPOLIA_ADDRESSES[2] = L1_SEPOLIA_DAI;
        L2_SEPOLIA_ADDRESSES[3] = 0x0733Df3e178c32f44B85B731D5475156a6E16391;

        L2_SEPOLIA_RESTRICTED_ADDRESSES = new address[](2);
        L2_SEPOLIA_RESTRICTED_ADDRESSES[0] = 0x00000000000000000000000000000000000003e8;
        L2_SEPOLIA_RESTRICTED_ADDRESSES[1] = 0x00000000000000000000000000000000000003e9;
    }

    /// USDX BRIDGE ///

    function _getMainnetUSDXBridgeArrays()
        internal
        pure
        returns (address[] memory L1_MAINNET_BRIDGE_TOKENS, uint256[] memory L1_MAINNET_BRIDGE_CAPS)
    {
        /// Tokens: USDC, USDT,  DAI
        /// Caps  : 1e30, 1e30, 1e30
        /// Functionally unlimited, no need to normalise for decimals unless lowered.
        L1_MAINNET_BRIDGE_TOKENS = new address[](1);
        L1_MAINNET_BRIDGE_TOKENS[0] = L1_MAINNET_USDC;
        // L1_MAINNET_BRIDGE_TOKENS[1] = L1_MAINNET_USDT;
        // L1_MAINNET_BRIDGE_TOKENS[2] = L1_MAINNET_DAI;

        L1_MAINNET_BRIDGE_CAPS = new uint256[](1);
        L1_MAINNET_BRIDGE_CAPS[0] = 1000000000000000000000000000000;
        // L1_MAINNET_BRIDGE_CAPS[1] = 1000000000000000000000000000000;
        // L1_MAINNET_BRIDGE_CAPS[2] = 1000000000000000000000000000000;
    }

    function _getSepoliaUSDXBridgeArrays()
        internal
        pure
        returns (address[] memory L1_SEPOLIA_BRIDGE_TOKENS, uint256[] memory L1_SEPOLIA_BRIDGE_CAPS)
    {
        L1_SEPOLIA_BRIDGE_TOKENS = new address[](1);
        L1_SEPOLIA_BRIDGE_TOKENS[0] = L1_SEPOLIA_USDC;
        // L1_SEPOLIA_BRIDGE_TOKENS[1] = L1_SEPOLIA_USDT;
        // L1_SEPOLIA_BRIDGE_TOKENS[2] = L1_SEPOLIA_DAI;

        L1_SEPOLIA_BRIDGE_CAPS = new uint256[](1);
        L1_SEPOLIA_BRIDGE_CAPS[0] = 1000000000000000000000000000000;
        // L1_SEPOLIA_BRIDGE_CAPS[1] = 1000000000000000000000000000000;
        // L1_SEPOLIA_BRIDGE_CAPS[2] = 1000000000000000000000000000000;
    }
}
