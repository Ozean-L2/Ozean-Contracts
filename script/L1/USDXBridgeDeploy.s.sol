// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ScriptUtils, console} from "script/utils/ScriptUtils.sol";
import {USDXBridge} from "@src/L1/USDXBridge.sol";
import {OptimismPortal} from "optimism/src/L1/OptimismPortal.sol";
import {SystemConfig} from "optimism/src/L1/SystemConfig.sol";

contract USDXBridgeDeploy is ScriptUtils {
    USDXBridge public usdxBridge;
    function run() external broadcast {
        /// Environment Vars
        address hexTrust;
        address usdx;
        OptimismPortal optimismPortal;
        SystemConfig systemConfig;
        address[] memory stablecoins;
        uint256[] memory depositCaps;
        if (block.chainid == 1) {
            hexTrust = vm.envAddress("ADMIN");
            usdx = vm.envAddress("L1_MAINNET_USDX");
            optimismPortal = OptimismPortal(payable(vm.envAddress("L1_MAINNET_PORTAL")));
            systemConfig = SystemConfig(vm.envAddress("L1_MAINNET_CONFIG"));
            stablecoins = vm.envAddress("L1_MAINNET_BRIDGE_TOKENS", ",");
            depositCaps = vm.envUint("L1_MAINNET_BRIDGE_CAPS", ",");
        } else if (block.chainid == 11155111) {
            hexTrust = vm.envAddress("ADMIN");
            usdx = vm.envAddress("L1_SEPOLIA_USDX");
            optimismPortal = OptimismPortal(payable(vm.envAddress("L1_SEPOLIA_PORTAL")));
            systemConfig = SystemConfig(vm.envAddress("L1_SEPOLIA_CONFIG"));
            stablecoins = vm.envAddress("L1_SEPOLIA_BRIDGE_TOKENS", ",");
            depositCaps = vm.envUint("L1_SEPOLIA_BRIDGE_CAPS", ",");
        } else revert();
        /// Pre-deploy checks
        require(hexTrust != address(0), "Script: Zero address.");
        require(address(optimismPortal) != address(0), "Script: Zero address.");
        require(address(systemConfig) != address(0), "Script: Zero address.");
        uint256 length = stablecoins.length;
        require(length == depositCaps.length, "Script: Unequal length.");
        for (uint256 i; i < length; i++) {
            require(stablecoins[i] != address(0), "Script: Zero address.");
            require(depositCaps[i] != 0, "Script: Zero amount.");
        }
        /// Deploy
        bytes memory deployData = abi.encode(hexTrust, optimismPortal, systemConfig, stablecoins, depositCaps);
        console.logBytes(deployData);
        usdxBridge = new USDXBridge(hexTrust, optimismPortal, systemConfig, stablecoins, depositCaps);
        /// Post-deploy checks
        require(usdxBridge.owner() == hexTrust, "Script: Wrong owner.");
        require(address(usdxBridge.usdx()) == usdx, "Script: Wrong address.");
        require(address(usdxBridge.portal()) == address(optimismPortal), "Script: Wrong address.");
        require(address(usdxBridge.config()) == address(systemConfig), "Script: Wrong address.");
        require(usdxBridge.gasLimit() == 21000, "Script: Wrong value.");
        for (uint256 i; i < length; i++) {
            require(usdxBridge.depositCap(stablecoins[i]) == depositCaps[i], "Script: Incorrect deposit cap.");
        } 
    }
}
