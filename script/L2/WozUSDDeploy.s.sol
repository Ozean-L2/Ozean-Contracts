// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ScriptUtils, console} from "script/utils/ScriptUtils.sol";
import {OzUSD} from "src/L2/OzUSD.sol";
import {WozUSD} from "src/L2/WozUSD.sol";

contract WozUSDDeploy is ScriptUtils {
    OzUSD public ozUSD = OzUSD(0x61A4cF946855F5985372D3b148267Ead3b931Cb8);
    WozUSD public wozUSD;

    /*
    function setUp(OzUSD _ozUSD) external {
        ozUSD = _ozUSD;
    }
    */

    function run() external broadcast {
        wozUSD = new WozUSD(ozUSD);
    }
}
