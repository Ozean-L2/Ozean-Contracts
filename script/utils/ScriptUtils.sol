pragma solidity 0.8.28;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

contract ScriptUtils is Script {
    modifier broadcast() {
        vm.startBroadcast(vm.envAddress("ADMIN"));
        _;
        vm.stopBroadcast();
    }
}
