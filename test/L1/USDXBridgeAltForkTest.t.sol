// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {TestSetup} from "test/utils/TestSetup.sol";
import {TestERC20Decimals, TestERC20DecimalsFeeOnTransfer} from "test/utils/Mocks.sol";
import {IERC20Alt} from "test/utils/TestInterfaces.sol";
import {USDXBridgeAltDeploy, USDXBridgeAlt} from "script/L1/USDXBridgeAltDeploy.s.sol";

/// @dev forge test --match-contract USDXBridgeAltForkMainetTest
contract USDXBridgeAltForkMainetTest is TestSetup {
    function setUp() public override {
        super.setUp();
        _forkL1Mainnet();

        /// Deploy USDXBridgeAlt
        USDXBridgeAltDeploy deployScript = new USDXBridgeAltDeploy();
        deployScript.run();
        usdxBridgeAlt = deployScript.usdxBridgeAlt();

        /// Alt bridge seeded
        deal(address(usdx), address(usdxBridgeAlt), 100e18);
    }

    /// SETUP ///

    function testInitialize() public view {
        assertEq(usdxBridgeAlt.owner(), hexTrust);
        assertEq(address(usdxBridgeAlt.l1USDX()), address(usdx));
        assertEq(usdxBridgeAlt.allowlisted(address(usdc)), true);
        assertEq(usdxBridgeAlt.allowlisted(address(usdt)), true);
        assertEq(usdxBridgeAlt.allowlisted(address(dai)), true);
        assertEq(usdxBridgeAlt.depositCap(address(usdc)), 1e30);
        assertEq(usdxBridgeAlt.depositCap(address(usdt)), 1e30);
        assertEq(usdxBridgeAlt.depositCap(address(dai)), 1e30);
        assertEq(usdxBridgeAlt.totalBridged(address(usdc)), 0);
        assertEq(usdxBridgeAlt.totalBridged(address(usdt)), 0);
        assertEq(usdxBridgeAlt.totalBridged(address(dai)), 0);
    }

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
        usdxBridgeAlt = new USDXBridgeAlt(hexTrust, address(usdx), eid, stablecoins, depositCaps);

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
        usdxBridgeAlt = new USDXBridgeAlt(hexTrust, address(usdx), eid, stablecoins, depositCaps);
    }

    /// BRIDGE STABLECOINS ///

    function testBridgeUSDXRevertConditions() public prank(alice) {
        /// Non-accepted stablecoin/ERC20
        uint256 _amount = 100e18;
        TestERC20Decimals usde = new TestERC20Decimals(18);
        vm.expectRevert("USDX Bridge: Stablecoin not accepted.");
        usdxBridgeAlt.bridge(address(usde), _amount, alice);

        /// Deposit zero
        vm.expectRevert("USDX Bridge: May not bridge nothing.");
        usdxBridgeAlt.bridge(address(dai), 0, alice);

        /// Deposit Cap exceeded
        uint256 excess = usdxBridgeAlt.depositCap(address(dai)) + 1;
        vm.expectRevert("USDX Bridge: Bridge amount exceeds deposit cap.");
        usdxBridgeAlt.bridge(address(dai), excess, alice);

        /// Insufficient LZ fee passed
        usdc.approve(address(usdxBridgeAlt), 100e6);
        vm.expectRevert("USDX Bridge: Layer Zero fee.");
        usdxBridgeAlt.bridge{value: 0}(address(usdc), 100e6, alice);

        vm.stopPrank();
        vm.startPrank(hexTrust);

        /// Rebasing token
        TestERC20DecimalsFeeOnTransfer feeOnTransfer = new TestERC20DecimalsFeeOnTransfer(18);
        feeOnTransfer.mint(hexTrust, 1 ether);

        feeOnTransfer.approve(address(usdxBridgeAlt), ~uint256(0));
        usdxBridgeAlt.setAllowlist(address(feeOnTransfer), true);
        usdxBridgeAlt.setDepositCap(address(feeOnTransfer), 1e30);

        vm.expectRevert("USDX Bridge: Fee-on-transfer tokens not supported.");
        usdxBridgeAlt.bridge(address(feeOnTransfer), 1 ether, hexTrust);
    }

    function testBridgeUSDXWithUSDC() public prank(alice) {
        /// Mint and approve
        uint256 _amount = 100e6;
        usdc.approve(address(usdxBridgeAlt), _amount);
        uint256 usdxAmount = _amount * (10 ** 12);

        /// Bridge
        vm.expectEmit(true, true, true, true);
        emit USDXBridgeAlt.BridgeDeposit(address(usdc), _amount, alice);
        usdxBridgeAlt.bridge{value: 0.01 ether}(address(usdc), _amount, alice);

        assertEq(usdxBridgeAlt.totalBridged(address(usdc)), usdxAmount);
    }

    function testBridgeUSDXWithUSDT() public prank(alice) {
        /// Mint and approve
        uint256 _amount = 100e6;
        IERC20Alt(address(usdt)).approve(address(usdxBridgeAlt), _amount);
        uint256 usdxAmount = _amount * (10 ** 12);

        /// Bridge
        vm.expectEmit(true, true, true, true);
        emit USDXBridgeAlt.BridgeDeposit(address(usdt), _amount, alice);
        usdxBridgeAlt.bridge{value: 0.01 ether}(address(usdt), _amount, alice);

        assertEq(usdxBridgeAlt.totalBridged(address(usdt)), usdxAmount);
    }

    function testBridgeUSDXWithDAI() public prank(alice) {
        /// Mint and approve
        uint256 _amount = 100e18;
        dai.approve(address(usdxBridgeAlt), _amount);

        /// Bridge
        vm.expectEmit(true, true, true, true);
        emit USDXBridgeAlt.BridgeDeposit(address(dai), _amount, alice);
        usdxBridgeAlt.bridge{value: 0.01 ether}(address(dai), _amount, alice);

        assertEq(usdxBridgeAlt.totalBridged(address(dai)), _amount);
    }

    /// OWNER ///

    function testSetAllowlist() public {
        TestERC20Decimals usde = new TestERC20Decimals(18);

        /// Non-owner revert
        vm.expectRevert("Ownable: caller is not the owner");
        usdxBridgeAlt.setAllowlist(address(usde), true);

        /// Owner allowed to set new coin
        vm.startPrank(hexTrust);

        /// Add USDE
        vm.expectEmit(true, true, true, true);
        emit USDXBridgeAlt.AllowlistSet(address(usde), true);
        usdxBridgeAlt.setAllowlist(address(usde), true);

        /// Remove DAI
        vm.expectEmit(true, true, true, true);
        emit USDXBridgeAlt.AllowlistSet(address(dai), false);
        usdxBridgeAlt.setAllowlist(address(dai), false);

        vm.stopPrank();

        assertEq(usdxBridgeAlt.allowlisted(address(usde)), true);
        assertEq(usdxBridgeAlt.allowlisted(address(dai)), false);
    }

    function testSetDepositCap(uint256 _newCap) public {
        /// Non-owner revert
        vm.expectRevert("Ownable: caller is not the owner");
        usdxBridgeAlt.setDepositCap(address(usdc), _newCap);

        assertEq(usdxBridgeAlt.depositCap(address(usdc)), 1e30);

        /// Owner allowed
        vm.startPrank(hexTrust);

        vm.expectEmit(true, true, true, true);
        emit USDXBridgeAlt.DepositCapSet(address(usdc), _newCap);
        usdxBridgeAlt.setDepositCap(address(usdc), _newCap);

        vm.stopPrank();

        assertEq(usdxBridgeAlt.depositCap(address(usdc)), _newCap);
    }

    function testWithdrawERC20() public prank(alice) {
        /// Send some tokens directly to the contract
        uint256 _amount = 100e18;
        dai.transfer(address(usdxBridgeAlt), _amount);
        uint256 balanceBefore = dai.balanceOf(address(usdxBridgeAlt));

        /// Non-owner revert
        vm.expectRevert("Ownable: caller is not the owner");
        usdxBridgeAlt.withdrawERC20(address(dai), _amount);

        /// Owner allowed
        vm.stopPrank();
        vm.startPrank(hexTrust);

        vm.expectEmit(true, true, true, true);
        emit USDXBridgeAlt.WithdrawCoins(address(dai), _amount, hexTrust);
        usdxBridgeAlt.withdrawERC20(address(dai), _amount);

        assertEq(dai.balanceOf(address(usdxBridgeAlt)), balanceBefore - _amount);
        assertEq(dai.balanceOf(hexTrust), _amount);
    }

    function testBridgeUSDXWithUSDCAndWithdraw() public prank(alice) {
        /// Alice mints and approves
        uint256 _amount = 100e6;
        usdc.approve(address(usdxBridgeAlt), _amount);

        /// Alice bridges
        usdxBridgeAlt.bridge{value: 0.01 ether}(address(usdc), _amount, alice);

        /// Owner withdraws deposited USDC
        vm.stopPrank();
        vm.startPrank(hexTrust);

        vm.expectEmit(true, true, true, true);
        emit USDXBridgeAlt.WithdrawCoins(address(usdc), _amount, hexTrust);
        usdxBridgeAlt.withdrawERC20(address(usdc), _amount);

        assertEq(usdc.balanceOf(hexTrust), _amount);
    }
}
