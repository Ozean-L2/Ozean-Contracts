// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ScriptUtils, console} from "script/utils/ScriptUtils.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {USDXBridgeAlt} from "src/L1/USDXBridgeAlt.sol";

contract USDXBridgeAltDeploy is ScriptUtils {
    USDXBridgeAlt public usdxBridgeAlt;

    function run() external broadcast {
        /// Environment Vars
        address hexTrust;
        address l1USDX;
        uint32 eid;
        address[] memory stablecoins;
        uint256[] memory depositCaps;
        if (block.chainid == 1) {
            hexTrust = ADMIN;
            l1USDX = L1_MAINNET_USDX;
            eid = EID;
            (stablecoins, depositCaps) = _getMainnetUSDXBridgeArrays();
        } else if (block.chainid == 11155111) {
            hexTrust = ADMIN;
            l1USDX = L1_SEPOLIA_USDX;
            eid = TESTNET_EID;
            (stablecoins, depositCaps) = _getSepoliaUSDXBridgeArrays();
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
        usdxBridgeAlt = new USDXBridgeAlt(hexTrust, l1USDX, eid, stablecoins, depositCaps);
        /// Post-deploy checks
        require(usdxBridgeAlt.owner() == hexTrust, "Script: Wrong owner.");
        require(address(usdxBridgeAlt.l1USDX()) == l1USDX, "Script: Wrong address.");
        require(usdxBridgeAlt.eid() == eid, "Script: Wrong value.");
        for (uint256 i; i < length; i++) {
            require(usdxBridgeAlt.depositCap(stablecoins[i]) == depositCaps[i], "Script: Incorrect deposit cap.");
        }
    }
}

contract Transfer is ScriptUtils {
    address public usdxBridgeAlt = 0x14D72e0C6f6b1117CfBF6a66C79158c8d6a18bC7;

    function run() external broadcast {
        IERC20(0x5DB6dA53eF70870f20d3E90Fa7c518A95C4B1563).transfer(usdxBridgeAlt, 90e18);
    }
}
