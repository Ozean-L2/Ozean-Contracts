// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";

contract TestSetup is Test {
    address public hexTrust;

    function setUp() public virtual {
        /// Setup environment
        hexTrust = makeAddr("HEX_TRUST");
    }

    function forkL1() internal {

    }

    function forkL2() internal {

    }

    modifier prank(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }
}
