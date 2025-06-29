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
        _distributeMainnetTokens(alice);

        vm.startPrank(hexTrust);
        usdxBridgeAlt.setAllowlist(address(usdt), true);
        usdxBridgeAlt.setAllowlist(address(dai), true);

        usdxBridgeAlt.setDepositCap(address(usdt), 1e30);
        usdxBridgeAlt.setDepositCap(address(dai), 1e30);
        vm.stopPrank();
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
        vm.expectRevert(USDXBridgeAlt.InvalidArrayLength.selector);
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
        vm.expectRevert(USDXBridgeAlt.ZeroAddress.selector);
        usdxBridgeAlt = new USDXBridgeAlt(hexTrust, address(usdx), eid, stablecoins, depositCaps);
    }

    /// BRIDGE STABLECOINS ///

    function testBridgeUSDXRevertConditions() public prank(alice) {
        /// Non-accepted stablecoin/ERC20
        uint256 _amount = 100e18;
        TestERC20Decimals usde = new TestERC20Decimals(18);

        {
            uint256 minAmount = usdxBridgeAlt.getBridgeAmount(address(usde), _amount);
            vm.expectRevert(USDXBridgeAlt.StablecoinNotAccepted.selector);
            usdxBridgeAlt.bridge(address(usde), _amount, minAmount, alice);
        }

        /// Deposit zero
        vm.expectRevert(USDXBridgeAlt.ZeroAmount.selector);
        usdxBridgeAlt.bridge(address(dai), 0, 0, alice);

        /// Deposit Cap exceeded
        uint256 excess = usdxBridgeAlt.depositCap(address(dai)) + 1;

        {
            uint256 minAmount = usdxBridgeAlt.getBridgeAmount(address(dai), excess);
            vm.expectRevert(USDXBridgeAlt.ExceedsDepositCap.selector);
            usdxBridgeAlt.bridge(address(dai), excess, minAmount, alice);
        }

        /// Insufficient LZ fee passed
        usdc.approve(address(usdxBridgeAlt), 100e6);

        {
            uint256 minAmount = usdxBridgeAlt.getBridgeAmount(address(usdc), 100e6);
            vm.expectRevert(USDXBridgeAlt.InsufficientLayerZeroFee.selector);
            usdxBridgeAlt.bridge{value: 0}(address(usdc), 100e6, minAmount, alice);
        }

        vm.stopPrank();
        vm.startPrank(hexTrust);

        /// Rebasing token
        TestERC20DecimalsFeeOnTransfer feeOnTransfer = new TestERC20DecimalsFeeOnTransfer(18);
        feeOnTransfer.mint(hexTrust, 1 ether);

        feeOnTransfer.approve(address(usdxBridgeAlt), ~uint256(0));
        usdxBridgeAlt.setAllowlist(address(feeOnTransfer), true);
        usdxBridgeAlt.setDepositCap(address(feeOnTransfer), 1e30);

        {
            uint256 minAmount = usdxBridgeAlt.getBridgeAmount(address(feeOnTransfer), 1 ether);
            vm.expectRevert(USDXBridgeAlt.FeeOnTransferTokenNotSupported.selector);
            usdxBridgeAlt.bridge(address(feeOnTransfer), 1 ether, minAmount, hexTrust);
        }

        {
            uint256 minAmount = usdxBridgeAlt.getBridgeAmount(address(feeOnTransfer), 1 ether);
            vm.expectRevert(USDXBridgeAlt.ZeroAddress.selector);
            usdxBridgeAlt.bridge(address(feeOnTransfer), 1 ether, minAmount, address(0));
        }
    }

    function testBridgeUSDXWithUSDC() public prank(alice) {
        /// Mint and approve
        uint256 _amount = 100e6;
        usdc.approve(address(usdxBridgeAlt), _amount);

        uint256 aliceBalanceBefore = address(alice).balance;
        uint256 bridgeBalanceBefore = address(usdxBridgeAlt).balance;

        /// Bridge
        usdxBridgeAlt.bridge{value: 0.01 ether}(address(usdc), _amount, _amount, alice);

        assertEq(usdxBridgeAlt.totalBridged(address(usdc)), _amount);

        uint256 aliceBalanceAfter = address(alice).balance;
        uint256 bridgeBalanceAfter = address(usdxBridgeAlt).balance;

        // Check Alice's balance decreased (paid for the bridge fee)
        assertLt(aliceBalanceAfter, aliceBalanceBefore);

        // Check bridge contract's ETH balance remains zero (assumes it forwarded all ETH or refunded)
        assertEq(bridgeBalanceBefore, 0);
        assertEq(bridgeBalanceAfter, 0);
    }

    function testBridgeUSDXWithUSDT() public prank(alice) {
        /// Mint and approve
        uint256 _amount = 100e6;
        IERC20Alt(address(usdt)).approve(address(usdxBridgeAlt), _amount);

        /// Bridge
        usdxBridgeAlt.bridge{value: 0.01 ether}(address(usdt), _amount, _amount, alice);

        assertEq(usdxBridgeAlt.totalBridged(address(usdt)), _amount);
    }

    function testBridgeUSDXWithDAI() public prank(alice) {
        /// Mint and approve
        uint256 _amount = 1e18;
        dai.approve(address(usdxBridgeAlt), _amount);

        /// Bridge
        usdxBridgeAlt.bridge{value: 0.01 ether}(address(dai), _amount, _amount, alice);

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

    function testWithdrawETH() public prank(alice) {
        // Send some ETH directly to the contract
        uint256 _amount = 1 ether;
        vm.deal(address(usdxBridgeAlt), _amount);
        uint256 balanceBefore = address(usdxBridgeAlt).balance;

        // Try withdrawing as non-owner
        vm.expectRevert("Ownable: caller is not the owner");
        usdxBridgeAlt.withdrawETH(_amount, alice);

        vm.stopPrank();

        // Owner should be allowed to withdraw
        vm.startPrank(hexTrust);

        address recipient = hexTrust;
        uint256 recipientBalanceBefore = recipient.balance;

        vm.expectEmit(true, true, true, true);
        emit USDXBridgeAlt.WithdrawETH(_amount, recipient);
        usdxBridgeAlt.withdrawETH(_amount, recipient);

        // Check balances after withdrawal
        assertEq(address(usdxBridgeAlt).balance, balanceBefore - _amount);
        assertEq(recipient.balance, recipientBalanceBefore + _amount);

        vm.stopPrank();
    }

    function testWithdrawERC20() public prank(alice) {
        /// Send some tokens directly to the contract
        uint256 _amount = 1e18;
        dai.transfer(address(usdxBridgeAlt), _amount);
        uint256 balanceBefore = dai.balanceOf(address(usdxBridgeAlt));

        /// Non-owner revert
        vm.expectRevert("Ownable: caller is not the owner");
        usdxBridgeAlt.withdrawERC20(address(dai), _amount);

        /// Owner allowed
        vm.stopPrank();
        vm.startPrank(hexTrust);

        vm.expectEmit(true, true, true, true);
        emit USDXBridgeAlt.WithdrawERC20(address(dai), _amount, hexTrust);
        usdxBridgeAlt.withdrawERC20(address(dai), _amount);

        assertEq(dai.balanceOf(address(usdxBridgeAlt)), balanceBefore - _amount);
        assertEq(dai.balanceOf(hexTrust), _amount);
    }

    function testBridgeUSDXWithUSDCAndWithdraw() public prank(alice) {
        /// Alice mints and approves
        uint256 _amount = 100e6;
        usdc.approve(address(usdxBridgeAlt), _amount);

        /// Alice bridges
        usdxBridgeAlt.bridge{value: 0.01 ether}(address(usdc), _amount, _amount, alice);

        /// Owner withdraws deposited USDC
        vm.stopPrank();
        vm.startPrank(hexTrust);

        vm.expectEmit(true, true, true, true);
        emit USDXBridgeAlt.WithdrawERC20(address(usdc), _amount, hexTrust);
        usdxBridgeAlt.withdrawERC20(address(usdc), _amount);

        assertEq(usdc.balanceOf(hexTrust), _amount);
    }

    function testDepositCapPerTokenRespectsNativeDecimals() public prank(hexTrust) {
        uint256 usdcCap = 1_000_000; // 1 USDC in 6 decimals
        uint256 daiCap = 1e18;       // 1 DAI in 18 decimals

        // Set deposit caps as owner
        usdxBridgeAlt.setDepositCap(address(usdc), usdcCap);
        usdxBridgeAlt.setDepositCap(address(dai), daiCap);
        vm.stopPrank();

        // Approve USDC and bridge exactly at cap (positive test)
        vm.startPrank(alice);
        usdc.approve(address(usdxBridgeAlt), usdcCap);
        uint256 minAmount = usdxBridgeAlt.getBridgeAmount(address(usdc), usdcCap);
        usdxBridgeAlt.bridge{value: 0.01 ether}(address(usdc), usdcCap, minAmount, alice);
        assertEq(usdxBridgeAlt.totalBridged(address(usdc)), usdcCap);

        // Try to bridge more than cap — should revert (negative test)
        usdc.approve(address(usdxBridgeAlt), 1);
        minAmount = usdxBridgeAlt.getBridgeAmount(address(usdc), 1);
        vm.expectRevert(USDXBridgeAlt.ExceedsDepositCap.selector);
        usdxBridgeAlt.bridge{value: 0.01 ether}(address(usdc), 1, minAmount, alice);

        // Approve DAI and bridge exactly at cap (positive test)
        dai.approve(address(usdxBridgeAlt), daiCap);
        minAmount = usdxBridgeAlt.getBridgeAmount(address(dai), daiCap);
        usdxBridgeAlt.bridge{value: 0.01 ether}(address(dai), daiCap, minAmount, alice);
        assertEq(usdxBridgeAlt.totalBridged(address(dai)), daiCap);

        // Try to bridge more than cap — should revert (negative test)
        dai.approve(address(usdxBridgeAlt), 1);
        minAmount = usdxBridgeAlt.getBridgeAmount(address(dai), 1);
        vm.expectRevert(USDXBridgeAlt.ExceedsDepositCap.selector);
        usdxBridgeAlt.bridge{value: 0.01 ether}(address(dai), 1, minAmount, alice);

        vm.stopPrank();
    }
}
