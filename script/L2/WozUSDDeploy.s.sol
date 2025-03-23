// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ScriptUtils, console} from "script/utils/ScriptUtils.sol";
import {OzUSD} from "src/L2/OzUSD.sol";
import {WozUSD} from "src/L2/WozUSD.sol";

contract WozUSDDeploy is ScriptUtils {
    OzUSD public ozUSD;
    WozUSD public wozUSD;

    function setUp(OzUSD _ozUSD) external {
        ozUSD = _ozUSD;
    }

    function run() external broadcast {
        wozUSD = new WozUSD(ozUSD);
    }
}
