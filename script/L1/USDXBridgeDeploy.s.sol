// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ScriptUtils, console} from "script/utils/ScriptUtils.sol";
import {USDXBridge} from "src/L1/USDXBridge.sol";

contract USDXBridgeDeploy is ScriptUtils {
    USDXBridge public usdxBridge;

    function run() external broadcast {
        /// Environment Vars
        address hexTrust;
        address l1USDX;
        uint32 eid;
        address[] memory stablecoins;
        uint256[] memory depositCaps;
        if (block.chainid == 1) {
            hexTrust = vm.envAddress("ADMIN");
            l1USDX = vm.envAddress("L1_MAINNET_USDX");
            eid = uint32(vm.envUint("EID"));
            stablecoins = vm.envAddress("L1_MAINNET_BRIDGE_TOKENS", ",");
            depositCaps = vm.envUint("L1_MAINNET_BRIDGE_CAPS", ",");
        } else if (block.chainid == 11155111) {
            hexTrust = vm.envAddress("ADMIN");
            l1USDX = vm.envAddress("L1_SEPOLIA_USDX");
            eid = uint32(vm.envUint("EID"));
            stablecoins = vm.envAddress("L1_SEPOLIA_BRIDGE_TOKENS", ",");
            depositCaps = vm.envUint("L1_SEPOLIA_BRIDGE_CAPS", ",");
        } else {
            revert();
        }
        /// Pre-deploy checks
        require(hexTrust != address(0), "Script: Zero address.");
        require(l1USDX != address(0), "Script: Zero address.");
        require(eid != uint32(0), "Script: Zero amount.");
        uint256 length = stablecoins.length;
        require(length == depositCaps.length, "Script: Unequal length.");
        for (uint256 i; i < length; i++) {
            require(stablecoins[i] != address(0), "Script: Zero address.");
            require(depositCaps[i] != 0, "Script: Zero amount.");
        }
        /// Deploy
        bytes memory deployData = abi.encode(hexTrust, l1USDX, eid, stablecoins, depositCaps);
        console.logBytes(deployData);
        usdxBridge = new USDXBridge(hexTrust, l1USDX, eid, stablecoins, depositCaps);
        /// Post-deploy checks
        require(usdxBridge.owner() == hexTrust, "Script: Wrong owner.");
        require(address(usdxBridge.l1USDX()) == l1USDX, "Script: Wrong address.");
        require(usdxBridge.eid() == eid, "Script: Wrong value.");
        for (uint256 i; i < length; i++) {
            require(usdxBridge.depositCap(stablecoins[i]) == depositCaps[i], "Script: Incorrect deposit cap.");
        }
    }
}
