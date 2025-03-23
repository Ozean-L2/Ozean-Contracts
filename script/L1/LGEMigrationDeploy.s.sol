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
            hexTrust = vm.envAddress("ADMIN");
            l1StandardBridge = vm.envAddress("L1_MAINNET_STANDARD_BRIDGE");
            l1LidoTokensBridge = vm.envAddress("L1_MAINNET_LIDO_BRIDGE");
            usdxBridge = vm.envAddress("L1_MAINNET_USDX_BRIDGE");
            lgeStaking = vm.envAddress("L1_MAINNET_LGE_STAKING");
            usdc = vm.envAddress("L1_MAINNET_USDC");
            wstETH = vm.envAddress("L1_MAINNET_WSTETH");
            l1Addresses = vm.envAddress("L1_MAINNET_ADDRESSES", ",");
            l2Addresses = vm.envAddress("L2_MAINNET_ADDRESSES", ",");
            restrictedL2Addresses = vm.envAddress("L2_MAINNET_RESTRICTED_ADDRESSES", ",");
        } else if (block.chainid == 11155111) {
            hexTrust = vm.envAddress("ADMIN");
            l1StandardBridge = vm.envAddress("L1_SEPOLIA_STANDARD_BRIDGE");
            l1LidoTokensBridge = vm.envAddress("L1_SEPOLIA_LIDO_BRIDGE");
            //usdxBridge = vm.envAddress("L1_SEPOLIA_USDX_BRIDGE");
            //lgeStaking = vm.envAddress("L1_SEPOLIA_LGE_STAKING");
            usdc = vm.envAddress("L1_SEPOLIA_USDC");
            wstETH = vm.envAddress("L1_SEPOLIA_WSTETH");
            l1Addresses = vm.envAddress("L1_SEPOLIA_ADDRESSES", ",");
            l2Addresses = vm.envAddress("L2_SEPOLIA_ADDRESSES", ",");
            restrictedL2Addresses = vm.envAddress("L2_SEPOLIA_RESTRICTED_ADDRESSES", ",");
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
