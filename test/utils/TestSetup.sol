// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {IUSDX, IERC20Faucet, IERC20} from "test/utils/TestInterfaces.sol";
import {IStETH, IWstETH} from "test/utils/TestInterfaces.sol";
import {USDXBridge} from "src/L1/USDXBridge.sol";
import {LGEStaking} from "src/L1/LGEStaking.sol";
import {LGEMigrationV1, IL1LidoTokensBridge, IL1StandardBridge} from "src/L1/LGEMigrationV1.sol";
import {OzUSD} from "src/L2/OzUSD.sol";
import {WozUSD} from "src/L2/WozUSD.sol";

contract TestSetup is Test {
    /// L1
    address public constant faucetOwner = 0xC959483DBa39aa9E78757139af0e9a2EDEb3f42D;
    IL1StandardBridge public l1StandardBridge;
    IL1LidoTokensBridge public l1LidoTokensBridge;
    IERC20Faucet public usdc;
    IERC20Faucet public usdt;
    IERC20Faucet public dai;
    IStETH public stETH;
    IWstETH public wstETH;

    IUSDX public usdx;
    USDXBridge public usdxBridge;
    LGEStaking public lgeStaking;
    LGEMigrationV1 public lgeMigration;

    /// L2

    IERC20 public l2USDX;
    OzUSD public ozUSD;
    WozUSD public wozUSD;

    /// Universal
    address public hexTrust;
    address public alice;
    address public bob;

    function setUp() public virtual {
        hexTrust = vm.envAddress("ADMIN");
        alice = makeAddr("ALICE");
        bob = makeAddr("BOB");
    }

    modifier prank(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    /// FORK L1 ///

    function _forkL1Mainnet() internal {
        string memory rpcURL = vm.envString("L1_MAINNET_RPC_URL");
        uint256 l1Fork = vm.createFork(rpcURL);
        vm.selectFork(l1Fork);
        /// Environment
        vm.deal(hexTrust, 10_000 ether);
        vm.deal(alice, 10_000 ether);
        vm.deal(bob, 10_000 ether);

        usdx = IUSDX(0xf8750b54d86BE7aE9e32b4A0C826811198D63313);
        usdc = IERC20Faucet(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        usdt = IERC20Faucet(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        dai = IERC20Faucet(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    }

    function _distributeMainnetTokens(address _user) internal {
        deal(address(usdc), _user, 1e18);
        deal(address(usdt), _user, 1e18);
        deal(address(dai), _user, 1e18);

        /*
        vm.deal(faucetOwner, 10_000 ether);
        uint256 amount0 = stETH.submit{value: 10_000 ether}(address(69));
        stETH.approve(address(wstETH), amount0);
        uint256 amount1 = wstETH.wrap(amount0);
        wstETH.transfer(_user, amount1);
        */
    }

    /// @dev import these from env
    function _forkL1Sepolia() internal {
        string memory rpcURL = vm.envString("L1_TESTNET_RPC_URL");
        uint256 l1Fork = vm.createFork(rpcURL);
        vm.selectFork(l1Fork);
        /// Environment
        vm.deal(hexTrust, 10_000 ether);
        vm.deal(alice, 10_000 ether);
        vm.deal(bob, 10_000 ether);

        l1StandardBridge = IL1StandardBridge(payable(0xb9558CE3C11EC69e18632A8e5B316581e852dB91));
        l1LidoTokensBridge = IL1LidoTokensBridge(0xd836932faEaC34FdFF0bb14696E92bA33805D4E3);
        usdx = IUSDX(0x43bd82D1e29a1bEC03AfD11D5a3252779b8c760c);
        usdc = IERC20Faucet(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8);
        usdt = IERC20Faucet(0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0);
        dai = IERC20Faucet(0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357);
        stETH = IStETH(0x3e3FE7dBc6B4C189E7128855dD526361c49b40Af);
        wstETH = IWstETH(0xB82381A3fBD3FaFA77B3a7bE693342618240067b);
        _distributeSepoliaTokens(alice);
        _distributeSepoliaTokens(bob);
    }

    function _distributeSepoliaTokens(address _user) internal prank(faucetOwner) {
        usdc.mint(_user, 1e18);
        usdt.mint(_user, 1e18);
        dai.mint(_user, 1e30);
        vm.deal(faucetOwner, 10_000 ether);
        uint256 amount0 = stETH.submit{value: 10_000 ether}(address(69));
        stETH.approve(address(wstETH), amount0);
        uint256 amount1 = wstETH.wrap(amount0);
        wstETH.transfer(_user, amount1);
    }

    /// FORK L2 ///

    function _forkL2() internal {
        string memory rpcURL = vm.envString("L2_TESTNET_RPC_URL");
        uint256 l2Fork = vm.createFork(rpcURL);
        vm.selectFork(l2Fork);
        /// Environment
        vm.deal(hexTrust, 10_000 ether);
        vm.deal(alice, 10_000 ether);
        vm.deal(bob, 10_000 ether);
        l2USDX = IERC20(vm.envAddress("L2_SEPOLIA_USDX"));
        deal(address(l2USDX), hexTrust, 10_000 ether);
        deal(address(l2USDX), alice, 10_000 ether);
        deal(address(l2USDX), bob, 10_000 ether);
    }
}
