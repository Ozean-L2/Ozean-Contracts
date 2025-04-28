pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Constants} from "script/Constants.sol";

contract ScriptUtils is Script, Constants {
    modifier broadcast() {
        vm.startBroadcast(ADMIN);
        _;
        vm.stopBroadcast();
    }
}
