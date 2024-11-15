// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TransportDApp} from "../src/TransportDapp.sol"; // Update the import path as necessary

contract TransportDAppScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        
        // Deploy the TransportDApp contract
        TransportDApp transportDApp = new TransportDApp();

        console.log("TransportDApp deployed at:", address(transportDApp));

        vm.stopBroadcast();
    }
}
