// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ScriptUtils, console} from "script/utils/ScriptUtils.sol";
import {LGEMigrationV1} from "src/L1/LGEMigrationV1.sol";

contract LGEMigrationDeploy is ScriptUtils {
    LGEMigrationV1 public lgeMigration;
    address public usdxBridge;
    address public lgeStaking;

    /// @dev Used in testing environment
    ///      Unnecessary for mainnet deployment once predicates deployed
    function setUp(address _usdxBridge, address _lgeStaking) external {
        usdxBridge = _usdxBridge;
        lgeStaking = _lgeStaking;
    }

    function run() external broadcast {
        /// Environment Vars
        address hexTrust;
        address l1StandardBridge;
        address l1LidoTokensBridge;
        address usdc;
        address wstETH;
        address[] memory l1Addresses;
        address[] memory l2Addresses;
        address[] memory restrictedL2Addresses;
        if (block.chainid == 1) {
            hexTrust = ADMIN;
            l1StandardBridge = L1_MAINNET_STANDARD_BRIDGE;
            l1LidoTokensBridge = L1_MAINNET_LIDO_BRIDGE;
            usdxBridge = L1_MAINNET_USDX_BRIDGE;
            lgeStaking = L1_MAINNET_LGE_STAKING;
            usdc = L1_MAINNET_USDC;
            wstETH = L1_MAINNET_WSTETH;
            (l1Addresses, l2Addresses, restrictedL2Addresses) = _getMainnetMigrationArrays();
        } else if (block.chainid == 11155111) {
            hexTrust = ADMIN;
            l1StandardBridge = L1_SEPOLIA_STANDARD_BRIDGE;
            l1LidoTokensBridge = L1_SEPOLIA_LIDO_BRIDGE;
            usdc = L1_SEPOLIA_USDC;
            wstETH = L1_SEPOLIA_WSTETH;
            (l1Addresses, l2Addresses, restrictedL2Addresses) = _getSepoliaMigrationArrays();
        } else {
            revert();
        }
        /// Pre-deploy checks
        require(hexTrust != address(0), "Script: Zero address.");
        require(l1StandardBridge != address(0), "Script: Zero address.");
        require(l1LidoTokensBridge != address(0), "Script: Zero address.");
        require(usdxBridge != address(0), "Script: Zero address.");
        require(lgeStaking != address(0), "Script: Zero address.");
        require(usdc != address(0), "Script: Zero address.");
        require(wstETH != address(0), "Script: Zero address.");
        uint256 length = l1Addresses.length;
        require(length == l2Addresses.length, "Script: Unequal length.");
        for (uint256 i; i < length; i++) {
            require(l1Addresses[i] != address(0), "Script: Zero address.");
            require(l2Addresses[i] != address(0), "Script: Zero address.");
        }
        /// Deploy
        bytes memory deployData = abi.encode(
            hexTrust,
            l1StandardBridge,
            l1LidoTokensBridge,
            usdxBridge,
            lgeStaking,
            usdc,
            wstETH,
            l1Addresses,
            l2Addresses,
            restrictedL2Addresses
        );
        console.logBytes(deployData);
        lgeMigration = new LGEMigrationV1(
            hexTrust,
            l1StandardBridge,
            l1LidoTokensBridge,
            usdxBridge,
            lgeStaking,
            usdc,
            wstETH,
            l1Addresses,
            l2Addresses,
            restrictedL2Addresses
        );
        /// Post-deploy checks
        require(lgeMigration.owner() == hexTrust, "Script: Wrong owner.");
    }
}
