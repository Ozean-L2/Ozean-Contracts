// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ScriptUtils} from "script/utils/ScriptUtils.sol";
import {OzUSD} from "src/L2/OzUSD.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract OzUSDDeploy is ScriptUtils {
    OzUSD public implementation;
    TransparentUpgradeableProxy public proxy;
    address public admin = makeAddr("admin");
    uint256 public initialSharesAmount = 1e18;

    function run() external broadcast {
        /// Deploy implementation
        implementation = new OzUSD();

        /// Deploy Proxy
        proxy = new TransparentUpgradeableProxy{value: initialSharesAmount}(
            address(implementation), admin, abi.encodeWithSignature("initialize(uint256)", initialSharesAmount)
        );
    }
}
