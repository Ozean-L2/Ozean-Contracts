// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ScriptUtils} from "script/utils/ScriptUtils.sol";
import {OzUSD} from "src/L2/OzUSD.sol";

contract OzUSDDeploy is ScriptUtils {
    OzUSD public ozUSD;
    address public hexTrust;
    uint256 public initialSharesAmount = 1e18;

    function setUp(address _hexTrust) external {
        hexTrust = _hexTrust;
    }

    function run() external payable broadcast {
        require(hexTrust != address(0), "Script: Zero address.");
        require(initialSharesAmount == 1e18, "Script: Zero amount.");

        ozUSD = new OzUSD{value: initialSharesAmount}(hexTrust, initialSharesAmount);

        require(address(ozUSD).balance == 1e18, "Script: Initial supply.");
        require(ozUSD.balanceOf(address(0xdead)) == 1e18, "Script: Initial supply.");
    }
}
