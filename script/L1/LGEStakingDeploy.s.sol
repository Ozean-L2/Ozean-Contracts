// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ScriptUtils, console} from "script/utils/ScriptUtils.sol";
import {LGEStaking} from "src/L1/LGEStaking.sol";

contract LGEStakingDeploy is ScriptUtils {
    LGEStaking public lgeStaking;

    function run() external broadcast {
        /// Environment Vars
        address hexTrust;
        address[] memory tokens;
        uint256[] memory depositCaps;
        if (block.chainid == 1) {
            hexTrust = ADMIN;
            (tokens, depositCaps) = _getMainnetLGEArrays();
        } else if (block.chainid == 11155111) {
            hexTrust = ADMIN;
            (tokens, depositCaps) = _getSepoliaLGEArrays();
        } else {
            revert();
        }
        /// Pre-deploy checks
        require(hexTrust != address(0), "Script: Zero address.");
        uint256 length = tokens.length;
        require(length == depositCaps.length, "Script: Unequal length.");
        for (uint256 i; i < length; i++) {
            require(tokens[i] != address(0), "Script: Zero address.");
            require(depositCaps[i] != 0, "Script: Zero amount.");
        }
        /// Deploy
        bytes memory deployData = abi.encode(hexTrust, tokens, depositCaps);
        console.logBytes(deployData);
        lgeStaking = new LGEStaking(hexTrust, tokens, depositCaps);
        /// Post-deploy checks
        require(lgeStaking.owner() == hexTrust, "Script: Wrong owner.");
        require(address(lgeStaking.lgeMigration()) == address(0), "Script: Migration is set.");
        require(lgeStaking.migrationActivated() == false, "Script: Migration is set.");
        for (uint256 i; i < length; i++) {
            require(lgeStaking.depositCap(tokens[i]) == depositCaps[i], "Script: Incorrect deposit cap.");
            require(lgeStaking.totalDeposited(tokens[i]) == 0, "Script: Incorrect total deposited.");
        }
    }
}
