// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ScriptUtils, console} from "script/utils/ScriptUtils.sol";
import {USDXBridge} from "src/L1/USDXBridge.sol";
import {Constants} from "script/Constants.sol";

contract USDXBridgeDeploy is ScriptUtils {
    USDXBridge public usdxBridge;

    function run() external broadcast {
        /// Environment Vars
        address hexTrust;
        address l1USDX;
        address l2USDX;
        address[] memory stablecoins;
        uint256[] memory depositCaps;

        if (block.chainid == 1) {
            hexTrust = ADMIN;
            l1USDX = L1_MAINNET_USDX;
            l2USDX = L2_MAINNET_USDX;
            (stablecoins, depositCaps) = _getMainnetUSDXBridgeArrays();
        } else if (block.chainid == 11155111) {
            hexTrust = ADMIN;
            l1USDX = L1_SEPOLIA_USDX;
            l2USDX = L2_SEPOLIA_USDX;
            (stablecoins, depositCaps) = _getSepoliaUSDXBridgeArrays();
        } else {
            revert("Unsupported chain");
        }

        /// Pre-deploy checks
        require(hexTrust != address(0), "Script: Zero address.");
        require(l1USDX != address(0), "Script: Zero address.");
        require(l2USDX != address(0), "Script: Zero address.");
        uint256 length = stablecoins.length;
        require(length == depositCaps.length, "Script: Unequal length.");
        for (uint256 i; i < length; i++) {
            require(stablecoins[i] != address(0), "Script: Zero address.");
            require(depositCaps[i] != 0, "Script: Zero amount.");
        }

        /// Deploy
        bytes memory deployData = abi.encode(hexTrust, l1USDX, l2USDX, stablecoins, depositCaps);
        console.logBytes(deployData);
        usdxBridge = new USDXBridge(hexTrust, l1USDX, l2USDX, stablecoins, depositCaps);

        /// Post-deploy checks
        require(usdxBridge.owner() == hexTrust, "Script: Wrong owner.");
        require(address(usdxBridge.l1USDX()) == l1USDX, "Script: Wrong address.");
        require(usdxBridge.l2USDX() == l2USDX, "Script: Wrong address.");
        require(usdxBridge.gasLimit() == 21000, "Script: Wrong value.");
        for (uint256 i; i < length; i++) {
            require(usdxBridge.depositCap(stablecoins[i]) == depositCaps[i], "Script: Incorrect deposit cap.");
        }
    }
}