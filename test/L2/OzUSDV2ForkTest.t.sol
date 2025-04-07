// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {TestSetup} from "test/utils/TestSetup.sol";
import {OzUSDV2Deploy, OzUSDV2, IERC20Metadata} from "script/L2/OzUSDV2Deploy.s.sol";

/// mint/redeem - shares
/// deposit/withdraw - assets

/// @dev forge test --match-contract OzUSDV2ForkTest
contract OzUSDV2ForkTest is TestSetup {
    function setUp() public override {
        super.setUp();
        _forkL2();

        /// Deploy ozUSD
        OzUSDV2Deploy deployScript = new OzUSDV2Deploy();
        deployScript.run();
        ozUSDV2 = deployScript.ozUSD();
    }

    function testInitialize() public view {
        assertEq(ozUSDV2.asset(), address(l2USDX));
        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18);
        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18);
        assertEq(ozUSDV2.totalAssets(), 1e18);
    }

    function testDeployRevertConditions() public {
        vm.expectRevert("OzUSD: Must deploy with at least one USDX.");
        ozUSDV2 = new OzUSDV2(IERC20Metadata(address(l2USDX)), hexTrust, 1e18 - 1);
    }

    function testDistributeYield() public prank(alice) {
        uint256 amount = 100 ether;
        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18);
        assertEq(ozUSDV2.convertToAssets(amount), amount);

        /// Owner only
        vm.expectRevert("Ownable: caller is not the owner");
        ozUSDV2.distributeYield(1e18);

        vm.stopPrank();
        vm.startPrank(hexTrust);

        /// Allowance
        vm.expectRevert("ERC20: insufficient allowance");
        ozUSDV2.distributeYield(1e18);

        l2USDX.approve(address(ozUSDV2), amount);

        /// Distribute
        vm.expectEmit(true, true, true, true);
        emit OzUSDV2.YieldDistributed(1e18, 1e18 + amount);
        ozUSDV2.distributeYield(amount);

        assertEq(ozUSDV2.convertToAssets(amount), (amount * l2USDX.balanceOf(address(ozUSDV2))) / 1e18);
    }

    /// SHARES ///

    function testMintAndDistributeYield() public prank(alice) {
        uint256 _amountA = 100 ether;
        uint256 _amountB = 250 ether;

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18);
        assertEq(ozUSDV2.convertToAssets(_amountA), _amountA);

        l2USDX.approve(address(ozUSDV2), _amountA);
        ozUSDV2.mint(_amountA, alice);

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18 + _amountA);
        assertEq(ozUSDV2.balanceOf(alice), _amountA);
        assertEq(ozUSDV2.convertToAssets(_amountA), _amountA);

        vm.stopPrank();
        vm.startPrank(hexTrust);

        l2USDX.approve(address(ozUSDV2), _amountB);

        vm.expectEmit(true, true, true, true);
        emit OzUSDV2.YieldDistributed(1e18 + _amountA, 1e18 + _amountA + _amountB);
        ozUSDV2.distributeYield(_amountB);

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18 + _amountA + _amountB);
        assertEq(ozUSDV2.balanceOf(alice), _amountA);
        assertEq(ozUSDV2.convertToAssets(_amountA), (_amountA * (1e18 + _amountA + _amountB)) / (1e18 + _amountA));
    }

    function testMintAndRedeem() public prank(alice) {
        uint256 _amountA = 100 ether;

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18);
        assertEq(ozUSDV2.convertToAssets(_amountA), _amountA);

        l2USDX.approve(address(ozUSDV2), _amountA);
        ozUSDV2.mint(_amountA, alice);

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18 + _amountA);
        assertEq(ozUSDV2.convertToAssets(_amountA), _amountA);

        ozUSDV2.approve(alice, _amountA);
        ozUSDV2.redeem(_amountA, alice, alice);

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18);
        assertEq(ozUSDV2.balanceOf(alice), 0);
        assertEq(ozUSDV2.convertToAssets(_amountA), _amountA);
    }

    function testMintDistributeYieldAndRedeem() public prank(alice) {
        uint256 _amountA = 100 ether;
        uint256 _amountB = 250 ether;

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18);
        assertEq(ozUSDV2.convertToAssets(_amountA), _amountA);

        l2USDX.approve(address(ozUSDV2), _amountA);
        ozUSDV2.mint(_amountA, alice);

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18 + _amountA);
        assertEq(ozUSDV2.balanceOf(alice), _amountA);
        assertEq(ozUSDV2.convertToAssets(_amountA), _amountA);

        vm.stopPrank();
        vm.startPrank(hexTrust);

        l2USDX.approve(address(ozUSDV2), _amountB);

        vm.expectEmit(true, true, true, true);
        emit OzUSDV2.YieldDistributed(1e18 + _amountA, 1e18 + _amountA + _amountB);
        ozUSDV2.distributeYield(_amountB);

        vm.stopPrank();
        vm.startPrank(alice);

        uint256 predictedAliceAmount = (_amountA * (1e18 + _amountA + _amountB)) / (1e18 + _amountA);

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18 + _amountA + _amountB);
        assertEq(ozUSDV2.balanceOf(alice), _amountA);
        assertEq(ozUSDV2.convertToAssets(_amountA), predictedAliceAmount);

        ozUSDV2.redeem(_amountA, alice, alice);
        assertEq(l2USDX.balanceOf(address(ozUSDV2)), (1e18 + _amountA + _amountB) - predictedAliceAmount);
        assertEq(ozUSDV2.totalAssets(), (1e18 + _amountA + _amountB) - predictedAliceAmount);
    }

    /// ASSETS ///

    function testDepositAndDistributeYield() public prank(alice) {
        uint256 _amountA = 100 ether;
        uint256 _amountB = 250 ether;

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18);
        assertEq(ozUSDV2.convertToShares(_amountA), _amountA);

        l2USDX.approve(address(ozUSDV2), _amountA);
        ozUSDV2.deposit(_amountA, alice);

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18 + _amountA);
        assertEq(ozUSDV2.balanceOf(alice), _amountA);
        assertEq(ozUSDV2.convertToShares(_amountA), _amountA);

        vm.stopPrank();
        vm.startPrank(hexTrust);

        l2USDX.approve(address(ozUSDV2), _amountB);

        vm.expectEmit(true, true, true, true);
        emit OzUSDV2.YieldDistributed(1e18 + _amountA, 1e18 + _amountA + _amountB);
        ozUSDV2.distributeYield(_amountB);

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18 + _amountA + _amountB);
        assertEq(ozUSDV2.balanceOf(alice), _amountA);
        assertEq(ozUSDV2.convertToShares(_amountA), (_amountA * (1e18 + _amountA) / (1e18 + _amountA + _amountB)));
    }

    function testDepositAndWithdraw() public prank(alice) {
        uint256 _amountA = 100 ether;

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18);
        assertEq(ozUSDV2.convertToShares(_amountA), _amountA);

        l2USDX.approve(address(ozUSDV2), _amountA);
        ozUSDV2.deposit(_amountA, alice);

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18 + _amountA);
        assertEq(ozUSDV2.convertToShares(_amountA), _amountA);

        ozUSDV2.approve(alice, _amountA);
        ozUSDV2.withdraw(_amountA, alice, alice);

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18);
        assertEq(ozUSDV2.balanceOf(alice), 0);
        assertEq(ozUSDV2.convertToShares(_amountA), _amountA);
    }

    function testDepositDistributeYieldAndWithdraw() public prank(alice) {
        uint256 _amountA = 100 ether;
        uint256 _amountB = 250 ether;

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18);
        assertEq(ozUSDV2.convertToShares(_amountA), _amountA);

        l2USDX.approve(address(ozUSDV2), _amountA);
        ozUSDV2.deposit(_amountA, alice);

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18 + _amountA);
        assertEq(ozUSDV2.balanceOf(alice), _amountA);
        assertEq(ozUSDV2.convertToShares(_amountA), _amountA);

        vm.stopPrank();
        vm.startPrank(hexTrust);

        l2USDX.approve(address(ozUSDV2), _amountB);

        vm.expectEmit(true, true, true, true);
        emit OzUSDV2.YieldDistributed(1e18 + _amountA, 1e18 + _amountA + _amountB);
        ozUSDV2.distributeYield(_amountB);

        vm.stopPrank();
        vm.startPrank(alice);

        uint256 predictedAliceAmount = (_amountA * (1e18 + _amountA) / (1e18 + _amountA + _amountB));

        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18 + _amountA + _amountB);
        assertEq(ozUSDV2.balanceOf(alice), _amountA);
        assertEq(ozUSDV2.convertToShares(_amountA), predictedAliceAmount);

        ozUSDV2.withdraw(predictedAliceAmount, alice, alice);
        assertEq(l2USDX.balanceOf(address(ozUSDV2)), (1e18 + _amountA + _amountB) - predictedAliceAmount);
    }

    /// PAUSED ///

    function testPaused() public prank(alice) {
        assertEq(ozUSDV2.paused(), false);

        /// Revert for non-owner
        vm.expectRevert("Ownable: caller is not the owner");
        ozUSDV2.setPaused(true);

        vm.stopPrank();
        vm.startPrank(hexTrust);

        ozUSDV2.setPaused(true);
        assertEq(ozUSDV2.paused(), true);

        vm.expectRevert("Pausable: paused");
        ozUSDV2.mint(1, alice);

        vm.expectRevert("Pausable: paused");
        ozUSDV2.deposit(1, alice);

        ozUSDV2.setPaused(false);
        assertEq(ozUSDV2.paused(), false);
    }

    /// OVERRIDES ///

    function testDirectTransfer() public prank(alice) {
        assertEq(ozUSDV2.totalAssets(), 1e18);
        assertEq(ozUSDV2.convertToAssets(1e18), 1e18);
        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18);

        /// Sending USDX directly to the contract DOES NOT distributed yield or increase totalAssets
        uint256 _amountA = 100 ether;
        l2USDX.transfer(address(ozUSDV2), _amountA);

        assertEq(ozUSDV2.totalAssets(), 1e18);
        assertEq(ozUSDV2.convertToAssets(1e18), 1e18);
        assertEq(l2USDX.balanceOf(address(ozUSDV2)), 1e18 + _amountA);
    }
}
