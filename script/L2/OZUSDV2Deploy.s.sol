// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ScriptUtils, console} from "script/utils/ScriptUtils.sol";
import {OzUSDV2, IERC20Metadata} from "src/L2/OzUSDV2.sol";

contract OzUSDV2Deploy is ScriptUtils {
    OzUSDV2 public ozUSD;

    function run() external payable broadcast {
        /// Environment Vars
        address hexTrust;
        address l2USDX;
        uint256 initialSharesAmount;
        if (block.chainid == 1) {
            hexTrust = vm.envAddress("ADMIN");
            l2USDX = vm.envAddress("L2_MAINNET_USDX");
            initialSharesAmount = vm.envUint("INITIAL_SHARE_AMOUNT");
        } else if (block.chainid == 31911) {
            hexTrust = vm.envAddress("ADMIN");
            l2USDX = vm.envAddress("L2_SEPOLIA_USDX");
            initialSharesAmount = vm.envUint("INITIAL_SHARE_AMOUNT");
        } else {
            revert();
        }
        require(hexTrust != address(0), "Script: Zero address.");
        require(l2USDX != address(0), "Script: Zero address.");
        require(initialSharesAmount == 1e18, "Script: Zero amount.");
        /// Approve
        /// @dev Need to approve USDX to be deposited to the yet to-be-deployed ozUSD contract
        address predictedAddress = vm.computeCreateAddress(hexTrust, vm.getNonce(hexTrust) + 1);
        IERC20Metadata(l2USDX).approve(predictedAddress, 1e18);
        /// Deploy
        bytes memory deployData = abi.encode(IERC20Metadata(l2USDX), hexTrust, initialSharesAmount);
        console.logBytes(deployData);
        ozUSD = new OzUSDV2(IERC20Metadata(l2USDX), hexTrust, initialSharesAmount);
        /// Post-deploy checks
        require(address(ozUSD) == predictedAddress, "Script: Wrong Predicted Address.");
        require(IERC20Metadata(l2USDX).balanceOf(address(ozUSD)) == initialSharesAmount, "Script: Initial supply.");
        require(ozUSD.balanceOf(address(0xdead)) == initialSharesAmount, "Script: Initial supply.");
        require(address(ozUSD.asset()) == l2USDX, "Script: Wrong address.");
    }
}
