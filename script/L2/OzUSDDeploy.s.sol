// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ScriptUtils, console} from "script/utils/ScriptUtils.sol";
import {OzUSD} from "@src/L2/OzUSD.sol";

contract OzUSDDeploy is ScriptUtils {
    OzUSD public ozUSD;
    function run() external payable broadcast {
        /// Environment Vars
        address hexTrust;
        uint256 initialSharesAmount;
        if (block.chainid == 1) {
            hexTrust = vm.envAddress("ADMIN");
            initialSharesAmount = vm.envUint("INITIAL_SHARE_AMOUNT");
        } else if (block.chainid == 7849306) {
            hexTrust = vm.envAddress("ADMIN");
            initialSharesAmount = vm.envUint("INITIAL_SHARE_AMOUNT");
        } else revert();
        require(hexTrust != address(0), "Script: Zero address.");
        require(initialSharesAmount == 1e18, "Script: Zero amount.");
        /// Deploy
        bytes memory deployData = abi.encode(hexTrust, initialSharesAmount);
        console.logBytes(deployData);
        ozUSD = new OzUSD{value: initialSharesAmount}(hexTrust, initialSharesAmount);
        /// Post-deploy checks
        require(address(ozUSD).balance == initialSharesAmount, "Script: Initial supply.");
        require(ozUSD.balanceOf(address(0xdead)) == initialSharesAmount, "Script: Initial supply.");
    }
}
