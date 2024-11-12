// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ScriptUtils} from "script/utils/ScriptUtils.sol";
import {LGEMigrationV1} from "src/L1/LGEMigrationV1.sol";

contract LGEMigrationDeploy is ScriptUtils {
    LGEMigrationV1 public lgeMigration;
    address public l1StandardBridge;
    address public lgeStaking;
    address[] public l1Addresses;
    address[] public l2Addresses;

    /// @dev Used in testing environment, unnecessary for mainnet deployment
    function setUp(
        address _l1StandardBridge,
        address _lgeStaking,
        address[] memory _l1Addresses,
        address[] memory _l2Addresses
    ) external {
        l1StandardBridge = _l1StandardBridge;
        lgeStaking = _lgeStaking;
        l1Addresses = _l1Addresses;
        l2Addresses = _l2Addresses;
    }

    function run() external broadcast {
        lgeMigration = new LGEMigrationV1(l1StandardBridge, lgeStaking, l1Addresses, l2Addresses);
    }
}
