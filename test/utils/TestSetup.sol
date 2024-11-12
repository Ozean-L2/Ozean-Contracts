// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {OptimismPortal} from "optimism/src/L1/OptimismPortal.sol";
import {SystemConfig} from "optimism/src/L1/SystemConfig.sol";
import {IUSDX, IERC20Faucet, IERC20} from "test/utils/TestInterfaces.sol";
import {USDXBridge} from "src/L1/USDXBridge.sol";

contract TestSetup is Test {
    USDXBridge public usdxBridge;
    OptimismPortal public optimismPortal;
    SystemConfig public systemConfig;
    IUSDX public usdx;
    IERC20Faucet public usdc;
    IERC20Faucet public usdt;
    IERC20Faucet public dai;
    address public hexTrust;
    address public alice;
    address public bob;

    function setUp() public virtual {
        hexTrust = makeAddr("HEX_TRUST");
        alice = makeAddr("ALICE");
        bob = makeAddr("BOB");
        vm.deal(hexTrust, 10_000 ether);
        vm.deal(alice, 10_000 ether);
        vm.deal(bob, 10_000 ether);
    }

    modifier prank(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    /// FORK L1 ///

    function _forkL1() internal {
        string memory rpcURL = vm.envString("L1_RPC_URL");
        uint256 l1Fork = vm.createFork(rpcURL);
        vm.selectFork(l1Fork);
        /// Environment
        optimismPortal = OptimismPortal(payable(0x6EeeA09335D09870dD467FD34ECc10Fdb5106527));
        systemConfig = SystemConfig(0xdEC733B0643E7c3Bd06576A4C70Ca87E301EAe87);
        usdx = IUSDX(0x43bd82D1e29a1bEC03AfD11D5a3252779b8c760c);
        usdc = IERC20Faucet(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8);
        usdt = IERC20Faucet(0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0);
        dai = IERC20Faucet(0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357);
        _distributeTokens(alice);
        _distributeTokens(bob);
    }

    function _distributeTokens(address _user) internal prank(0xC959483DBa39aa9E78757139af0e9a2EDEb3f42D) {
        usdc.mint(_user, 1e24);
        usdt.mint(_user, 1e24);
        dai.mint(_user, 1e24);
        /// Environment
    }

    /// FORK L2 ///

    function _forkL2() internal {
        string memory rpcURL = vm.envString("L2_RPC_URL");
        uint256 l2Fork = vm.createFork(rpcURL);
        vm.selectFork(l2Fork);
    }
}
