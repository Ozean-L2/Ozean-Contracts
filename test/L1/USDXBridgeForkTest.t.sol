// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {TestSetup} from "test/utils/TestSetup.sol";
import {TestERC20Decimals} from "test/utils/Mocks.sol";
import {AddressAliasHelper} from "optimism/src/vendor/AddressAliasHelper.sol";
import {USDXBridgeDeploy, USDXBridge} from "script/L1/USDXBridgeDeploy.s.sol";

contract USDXBridgeForkTest is TestSetup {
    /// USDXBridge
    event BridgeDeposit(address indexed _stablecoin, uint256 _amount, address indexed _to);
    event WithdrawCoins(address indexed _coin, uint256 _amount, address indexed _to);
    event AllowlistSet(address indexed _coin, bool _set);
    event DepositCapSet(address indexed _coin, uint256 _newDepositCap);
    /// Optimism
    event TransactionDeposited(address indexed from, address indexed to, uint256 indexed version, bytes opaqueData);

    function setUp() public override {
        super.setUp();
        _forkL1();

        /// Deploy USDXBridge
        USDXBridgeDeploy deployScript = new USDXBridgeDeploy();
        deployScript.setUp(hexTrust, address(usdc), address(usdt), address(dai), optimismPortal, systemConfig);
        deployScript.run();
        usdxBridge = deployScript.usdxBridge();
    }

    /// SETUP ///

    function testDeployRevertWithUnequalArrayLengths() public {
        address[] memory stablecoins = new address[](3);
        stablecoins[0] = address(usdc);
        stablecoins[1] = address(usdt);
        stablecoins[2] = address(dai);
        uint256[] memory depositCaps = new uint256[](2);
        depositCaps[0] = 1e30;
        depositCaps[1] = 1e30;
        vm.expectRevert("USDXBridge: Stablecoins array length must equal the Deposit Caps array length.");
        usdxBridge = new USDXBridge(hexTrust, optimismPortal, systemConfig, stablecoins, depositCaps);
    }

    function testInitialize() public view {
        /// Environment
        (address addr, uint8 decimals) = systemConfig.gasPayingToken();
        assertEq(addr, address(usdx));
        assertEq(decimals, 18);

        /// Bridge
        assertEq(usdxBridge.owner(), hexTrust);
        assertEq(address(usdxBridge.usdx()), address(usdx));
        assertEq(address(usdxBridge.portal()), address(optimismPortal));
        assertEq(address(usdxBridge.config()), address(systemConfig));
        assertEq(usdx.allowance(address(usdxBridge), address(optimismPortal)), 0);
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

    /// @dev Deposit USDX directly via portal, bypassing usdx bridge
    function testNativeGasDeposit(uint256 _amount) public prank(alice) {
        _amount = bound(_amount, 1, 100_000e18);

        /// Mint and approve
        usdx.mint(alice, _amount);
        usdx.approve(address(optimismPortal), _amount);

        /// Bridge directly
        vm.expectEmit(true, true, true, true);
        emit TransactionDeposited(
            AddressAliasHelper.applyL1ToL2Alias(alice), alice, 0, _getOpaqueData(_amount, _amount, 21000, false, "")
        );
        optimismPortal.depositERC20Transaction({
            _to: alice,
            _mint: _amount,
            _value: _amount,
            _gasLimit: 21000,
            _isCreation: false,
            _data: ""
        });

        assertEq(usdx.balanceOf(address(optimismPortal)), _amount);
    }

    /// BRIDGE STABLECOINS ///

    function testBridgeUSDXRevertConditions(uint256 _amount) public prank(alice) {
        _amount = bound(_amount, 1, 100_000e18);

        /// Non-accepted stablecoin/ERC20
        TestERC20Decimals usde = new TestERC20Decimals(18);
        vm.expectRevert("USDXBridge: Stablecoin not accepted.");
        usdxBridge.bridge(address(usde), _amount, alice);

        /// Deposit zero
        vm.expectRevert("USDXBridge: May not bridge nothing.");
        usdxBridge.bridge(address(dai), 0, alice);

        /// Deposit Cap exceeded
        uint256 excess = usdxBridge.depositCap(address(dai)) + 1;
        vm.expectRevert("USDXBridge: Bridge amount exceeds deposit cap.");
        usdxBridge.bridge(address(dai), excess, alice);
    }

    function testBridgeUSDXWithUSDC(uint256 _amount) public prank(alice) {
        _amount = bound(_amount, 1, 100_000e6);

        /// Mint and approve
        usdc.mint(alice, _amount);
        usdc.approve(address(usdxBridge), _amount);
        uint256 usdxAmount = _amount * (10 ** 12);

        /// Bridge
        vm.expectEmit(true, true, true, true);
        emit TransactionDeposited(
            AddressAliasHelper.applyL1ToL2Alias(address(usdxBridge)),
            alice,
            0,
            _getOpaqueData(usdxAmount, usdxAmount, 21000, false, "")
        );
        vm.expectEmit(true, true, true, true);
        emit BridgeDeposit(address(usdc), _amount, alice);
        usdxBridge.bridge(address(usdc), _amount, alice);

        assertEq(usdx.balanceOf(address(optimismPortal)), usdxAmount);
        assertEq(usdxBridge.totalBridged(address(usdc)), usdxAmount);
        assertEq(usdx.allowance(address(usdxBridge), address(optimismPortal)), 0);
    }

    function testBridgeUSDXWithUSDT(uint256 _amount) public prank(alice) {
        _amount = bound(_amount, 1, 100_000e6);

        /// Mint and approve
        usdt.mint(alice, _amount);
        usdt.approve(address(usdxBridge), _amount);
        uint256 usdxAmount = _amount * (10 ** 12);

        /// Bridge
        vm.expectEmit(true, true, true, true);
        emit TransactionDeposited(
            AddressAliasHelper.applyL1ToL2Alias(address(usdxBridge)),
            alice,
            0,
            _getOpaqueData(usdxAmount, usdxAmount, 21000, false, "")
        );
        vm.expectEmit(true, true, true, true);
        emit BridgeDeposit(address(usdt), _amount, alice);
        usdxBridge.bridge(address(usdt), _amount, alice);

        assertEq(usdx.balanceOf(address(optimismPortal)), usdxAmount);
        assertEq(usdxBridge.totalBridged(address(usdt)), usdxAmount);
        assertEq(usdx.allowance(address(usdxBridge), address(optimismPortal)), 0);
    }

    function testBridgeUSDXWithDAI(uint256 _amount) public prank(alice) {
        _amount = bound(_amount, 1, 100_000e18);

        /// Mint and approve
        dai.mint(alice, _amount);
        dai.approve(address(usdxBridge), _amount);

        /// Bridge
        vm.expectEmit(true, true, true, true);
        emit TransactionDeposited(
            AddressAliasHelper.applyL1ToL2Alias(address(usdxBridge)),
            alice,
            0,
            _getOpaqueData(_amount, _amount, 21000, false, "")
        );
        vm.expectEmit(true, true, true, true);
        emit BridgeDeposit(address(dai), _amount, alice);
        usdxBridge.bridge(address(dai), _amount, alice);

        assertEq(usdx.balanceOf(address(optimismPortal)), _amount);
        assertEq(usdxBridge.totalBridged(address(dai)), _amount);
        assertEq(usdx.allowance(address(usdxBridge), address(optimismPortal)), 0);
    }

    function testBridgeUSDXWithStablecoinWithOddDecimals(uint256 _amount, uint8 _decimals) public prank(alice) {
        _decimals = uint8(bound(_decimals, 0, 24));
        _amount = bound(_amount, 1, 100_000 * (10 ** _decimals));

        /// Create, mint, and approve
        TestERC20Decimals usde = new TestERC20Decimals(_decimals);
        usde.mint(alice, _amount);
        usde.approve(address(usdxBridge), _amount);

        uint256 usdxAmount;
        if (_decimals <= 18) {
            usdxAmount = _amount * (10 ** (18 - _decimals));
        } else {
            usdxAmount = _amount / (10 ** (_decimals - 18));
        }

        /// Owner adds stablecoin to allowlist
        vm.stopPrank();
        vm.startPrank(hexTrust);

        vm.expectEmit(true, true, true, true);
        emit AllowlistSet(address(usde), true);
        usdxBridge.setAllowlist(address(usde), true);

        vm.expectEmit(true, true, true, true);
        emit DepositCapSet(address(usde), 1e30);
        usdxBridge.setDepositCap(address(usde), 1e30);

        vm.stopPrank();
        vm.startPrank(alice);

        /// Bridge
        vm.expectEmit(true, true, true, true);
        emit TransactionDeposited(
            AddressAliasHelper.applyL1ToL2Alias(address(usdxBridge)),
            alice,
            0,
            _getOpaqueData(usdxAmount, usdxAmount, 21000, false, "")
        );
        vm.expectEmit(true, true, true, true);
        emit BridgeDeposit(address(usde), _amount, alice);
        usdxBridge.bridge(address(usde), _amount, alice);

        assertEq(usdx.balanceOf(address(optimismPortal)), usdxAmount);
        assertEq(usdxBridge.totalBridged(address(usde)), usdxAmount);
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
        emit AllowlistSet(address(usde), true);
        usdxBridge.setAllowlist(address(usde), true);

        /// Remove DAI
        vm.expectEmit(true, true, true, true);
        emit AllowlistSet(address(dai), false);
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
        emit DepositCapSet(address(usdc), _newCap);
        usdxBridge.setDepositCap(address(usdc), _newCap);

        vm.stopPrank();

        assertEq(usdxBridge.depositCap(address(usdc)), _newCap);
    }

    function testWithdrawERC20(uint256 _amount) public {
        /// Send some tokens directly to the contract
        dai.mint(address(usdxBridge), _amount);

        assertEq(dai.balanceOf(address(usdxBridge)), _amount);

        /// Non-owner revert
        vm.expectRevert("Ownable: caller is not the owner");
        usdxBridge.withdrawERC20(address(dai), _amount);

        /// Owner allowed
        vm.startPrank(hexTrust);

        vm.expectEmit(true, true, true, true);
        emit WithdrawCoins(address(dai), _amount, hexTrust);
        usdxBridge.withdrawERC20(address(dai), _amount);

        vm.stopPrank();

        assertEq(dai.balanceOf(address(usdxBridge)), 0);
        assertEq(dai.balanceOf(hexTrust), _amount);
    }

    function testBridgeUSDXWithUSDCAndWithdraw(uint256 _amount) public prank(alice) {
        _amount = bound(_amount, 1, 100_000e6);

        /// Alice mints and approves
        usdc.mint(alice, _amount);
        usdc.approve(address(usdxBridge), _amount);
        uint256 usdxAmount = _amount * (10 ** 12);

        /// Alice bridges
        vm.expectEmit(true, true, true, true);
        emit TransactionDeposited(
            AddressAliasHelper.applyL1ToL2Alias(address(usdxBridge)),
            alice,
            0,
            _getOpaqueData(usdxAmount, usdxAmount, 21000, false, "")
        );
        usdxBridge.bridge(address(usdc), _amount, alice);

        assertEq(usdx.balanceOf(address(optimismPortal)), usdxAmount);
        assertEq(usdxBridge.totalBridged(address(usdc)), usdxAmount);

        /// Owner withdraws deposited USDC
        vm.stopPrank();
        vm.startPrank(hexTrust);

        vm.expectEmit(true, true, true, true);
        emit WithdrawCoins(address(usdc), _amount, hexTrust);
        usdxBridge.withdrawERC20(address(usdc), _amount);

        assertEq(usdc.balanceOf(address(usdxBridge)), 0);
        assertEq(usdc.balanceOf(hexTrust), _amount);
    }

    /// HELPERS ///

    function _getOpaqueData(
        uint256 _mint,
        uint256 _value,
        uint64 _gasLimit,
        bool _isCreation,
        bytes memory _data
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(_mint, _value, _gasLimit, _isCreation, _data);
    }
}