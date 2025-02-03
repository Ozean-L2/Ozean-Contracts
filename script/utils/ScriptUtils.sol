pragma solidity 0.8.15;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

contract ScriptUtils is Script {
    modifier broadcast() {
        vm.startBroadcast(msg.sender);
        _;
        vm.stopBroadcast();
    }
}
