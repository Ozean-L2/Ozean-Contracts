// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {TestSetup} from "test/utils/TestSetup.sol";
import {TestERC20Decimals, TestERC20DecimalsFeeOnTransfer} from "test/utils/Mocks.sol";
import {IERC20Alt} from "test/utils/TestInterfaces.sol";
import {USDXBridgeDeploy, USDXBridge} from "script/L1/USDXBridgeDeploy.s.sol";

/// @dev forge test --match-contract USDXBridgeForkMainetTest
contract USDXBridgeForkMainetTest is TestSetup {
    /// USDXBridge
    event BridgeDeposit(address indexed _stablecoin, uint256 _amount, address indexed _to);
    event WithdrawCoins(address indexed _coin, uint256 _amount, address indexed _to);
    event AllowlistSet(address indexed _coin, bool _set);
    event DepositCapSet(address indexed _coin, uint256 _newDepositCap);
    event GasLimitSet(uint64 _newGasLimit);
    /// Optimism
    event TransactionDeposited(address indexed from, address indexed to, uint256 indexed version, bytes opaqueData);

    function setUp() public override {
        super.setUp();
        _forkL1Mainnet();

        /// Deploy USDXBridge
        USDXBridgeDeploy deployScript = new USDXBridgeDeploy();
        deployScript.run();
        usdxBridge = deployScript.usdxBridge();

        /// Hex Trust grants bridge ability to mint USDX
        vm.prank(0xb8Ce31ad8bAD26e88Db17e68F695C64f67AD31EB);
        usdx.grantRole(0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6, address(usdxBridge));
    }

    /// SETUP ///

    function testInitialize() public view {
        assertEq(usdxBridge.owner(), hexTrust);
        //assertEq(address(usdxBridge.usdx()), address(usdx));
        assertEq(usdxBridge.gasLimit(), 21000);
        assertEq(usdxBridge.allowlisted(address(usdc)), true);
        assertEq(usdxBridge.allowlisted(address(usdt)), true);
        assertEq(usdxBridge.allowlisted(address(dai)), true);
        assertEq(usdxBridge.depositCap(address(usdc)), 1e30);
        assertEq(usdxBridge.depositCap(address(usdt)), 1e30);
        assertEq(usdxBridge.depositCap(address(dai)), 1e30);
        assertEq(usdxBridge.totalBridged(address(usdc)), 0);
        assertEq(usdxBridge.totalBridged(address(usdt)), 0);
        assertEq(usdxBridge.totalBridged(address(dai)), 0);
    }
}

    /*

    function testDeployRevertConditions() public {
        /// Unequal array length
        address[] memory stablecoins = new address[](3);
        stablecoins[0] = address(usdc);
        stablecoins[1] = address(usdt);
        stablecoins[2] = address(dai);
        uint256[] memory depositCaps = new uint256[](2);
        depositCaps[0] = 1e30;
        depositCaps[1] = 1e30;
        vm.expectRevert("USDX Bridge: Stablecoins array length must equal the Deposit Caps array length.");
        usdxBridge = new USDXBridge(hexTrust, optimismPortal, systemConfig, stablecoins, depositCaps);

        /// Zero address
        stablecoins = new address[](3);
        stablecoins[0] = address(usdc);
        stablecoins[1] = address(usdt);
        stablecoins[2] = address(0);
        depositCaps = new uint256[](3);
        depositCaps[0] = 1e30;
        depositCaps[1] = 1e30;
        depositCaps[2] = 1e30;
        vm.expectRevert("USDX Bridge: Zero address.");
        usdxBridge = new USDXBridge(hexTrust, optimismPortal, systemConfig, stablecoins, depositCaps);
    }

    /// @dev Deposit USDX directly via portal, bypassing usdx bridge
    function testNativeGasDeposit() public prank(alice) {
        /// Mint and approve
        uint256 _amount = 100e18;
        usdx.mint(alice, _amount);
        usdx.approve(address(optimismPortal), _amount);
        uint256 balanceBefore = usdx.balanceOf(address(optimismPortal));

        /// Zero address
        stablecoins = new address[](3);
        stablecoins[0] = address(usdc);
        stablecoins[1] = address(usdt);
        stablecoins[2] = address(0);
        depositCaps = new uint256[](3);
        depositCaps[0] = 1e30;
        depositCaps[1] = 1e30;
        depositCaps[2] = 1e30;
        vm.expectRevert("USDX Bridge: Zero address.");
        usdxBridge = new USDXBridge(hexTrust, address(usdx), eid, stablecoins, depositCaps);
    }

    /// BRIDGE STABLECOINS ///

    function testBridgeUSDXRevertConditions() public prank(alice) {
        /// Non-accepted stablecoin/ERC20
        uint256 _amount = 100e18;
        TestERC20Decimals usde = new TestERC20Decimals(18);
        vm.expectRevert("USDX Bridge: Stablecoin not accepted.");
        usdxBridge.bridge(address(usde), _amount, alice);

        /// Deposit zero
        vm.expectRevert("USDX Bridge: May not bridge nothing.");
        usdxBridge.bridge(address(dai), 0, alice);

        /// Deposit Cap exceeded
        uint256 excess = usdxBridge.depositCap(address(dai)) + 1;
        vm.expectRevert("USDX Bridge: Bridge amount exceeds deposit cap.");
        usdxBridge.bridge(address(dai), excess, alice);

        /// Insufficient LZ fee passed
        usdc.approve(address(usdxBridge), 100e6);
        vm.expectRevert("USDX Bridge: Layer Zero fee.");
        usdxBridge.bridge{value: 0}(address(usdc), 100e6, alice);

        vm.stopPrank();
        vm.startPrank(hexTrust);

        /// Rebasing token
        TestERC20DecimalsFeeOnTransfer feeOnTransfer = new TestERC20DecimalsFeeOnTransfer(18);
        feeOnTransfer.mint(hexTrust, 1 ether);

        feeOnTransfer.approve(address(usdxBridge), ~uint256(0));
        usdxBridge.setAllowlist(address(feeOnTransfer), true);
        usdxBridge.setDepositCap(address(feeOnTransfer), 1e30);

        vm.expectRevert("USDX Bridge: Fee-on-transfer tokens not supported.");
        usdxBridge.bridge(address(feeOnTransfer), 1 ether, hexTrust);
    }

    function testBridgeUSDXWithUSDC() public prank(alice) {
        /// Mint and approve
        uint256 _amount = 100e6;
        usdc.approve(address(usdxBridge), _amount);
        uint256 usdxAmount = _amount * (10 ** 12);

        /// Bridge
        vm.expectEmit(true, true, true, true);
        emit USDXBridge.BridgeDeposit(address(usdc), _amount, alice);
        usdxBridge.bridge{value: 0.01 ether}(address(usdc), _amount, alice);

        assertEq(usdxBridge.totalBridged(address(usdc)), usdxAmount);
    }

    function testBridgeUSDXWithUSDT() public prank(alice) {
        /// Mint and approve
        uint256 _amount = 100e6;
        IERC20Alt(address(usdt)).approve(address(usdxBridge), _amount);
        uint256 usdxAmount = _amount * (10 ** 12);

        /// Bridge
        vm.expectEmit(true, true, true, true);
        emit USDXBridge.BridgeDeposit(address(usdt), _amount, alice);
        usdxBridge.bridge{value: 0.01 ether}(address(usdt), _amount, alice);

        assertEq(usdxBridge.totalBridged(address(usdt)), usdxAmount);
    }

    function testBridgeUSDXWithDAI() public prank(alice) {
        /// Mint and approve
        uint256 _amount = 100e18;
        dai.approve(address(usdxBridge), _amount);

        /// Bridge
        vm.expectEmit(true, true, true, true);
        emit USDXBridge.BridgeDeposit(address(dai), _amount, alice);
        usdxBridge.bridge{value: 0.01 ether}(address(dai), _amount, alice);

        assertEq(usdxBridge.totalBridged(address(dai)), _amount);
    }

    /// OWNER ///

    function testSetAllowlist() public {
        TestERC20Decimals usde = new TestERC20Decimals(18);

        /// Non-owner revert
        vm.expectRevert("Ownable: caller is not the owner");
        usdxBridge.setAllowlist(address(usde), true);

        /// Owner allowed to set new coin
        vm.startPrank(hexTrust);

        /// Add USDE
        vm.expectEmit(true, true, true, true);
        emit USDXBridge.AllowlistSet(address(usde), true);
        usdxBridge.setAllowlist(address(usde), true);

        /// Remove DAI
        vm.expectEmit(true, true, true, true);
        emit USDXBridge.AllowlistSet(address(dai), false);
        usdxBridge.setAllowlist(address(dai), false);

        vm.stopPrank();

        assertEq(usdxBridge.allowlisted(address(usde)), true);
        assertEq(usdxBridge.allowlisted(address(dai)), false);
    }

    function testSetDepositCap(uint256 _newCap) public {
        /// Non-owner revert
        vm.expectRevert("Ownable: caller is not the owner");
        usdxBridge.setDepositCap(address(usdc), _newCap);

        assertEq(usdxBridge.depositCap(address(usdc)), 1e30);

        /// Owner allowed
        vm.startPrank(hexTrust);

        vm.expectEmit(true, true, true, true);
        emit USDXBridge.DepositCapSet(address(usdc), _newCap);
        usdxBridge.setDepositCap(address(usdc), _newCap);

        vm.stopPrank();

        assertEq(usdxBridge.depositCap(address(usdc)), _newCap);
    }

    function testWithdrawERC20() public prank(alice) {
        /// Send some tokens directly to the contract
        uint256 _amount = 100e18;
        dai.transfer(address(usdxBridge), _amount);
        uint256 balanceBefore = dai.balanceOf(address(usdxBridge));

        /// Non-owner revert
        vm.expectRevert("Ownable: caller is not the owner");
        usdxBridge.withdrawERC20(address(dai), _amount);

        /// Owner allowed
        vm.stopPrank();
        vm.startPrank(hexTrust);

        vm.expectEmit(true, true, true, true);
        emit USDXBridge.WithdrawCoins(address(dai), _amount, hexTrust);
        usdxBridge.withdrawERC20(address(dai), _amount);

        assertEq(dai.balanceOf(address(usdxBridge)), balanceBefore - _amount);
        assertEq(dai.balanceOf(hexTrust), _amount);
    }

    function testBridgeUSDXWithUSDCAndWithdraw() public prank(alice) {
        /// Alice mints and approves
        uint256 _amount = 100e6;
        usdc.approve(address(usdxBridge), _amount);

        /// Alice bridges
        usdxBridge.bridge{value: 0.01 ether}(address(usdc), _amount, alice);

        /// Owner withdraws deposited USDC
        vm.stopPrank();
        vm.startPrank(hexTrust);

        vm.expectEmit(true, true, true, true);
        emit USDXBridge.WithdrawCoins(address(usdc), _amount, hexTrust);
        usdxBridge.withdrawERC20(address(usdc), _amount);

        assertEq(usdc.balanceOf(hexTrust), _amount);
    }
}
