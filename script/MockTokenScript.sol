// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {MockUSDC} from "../src/mock/MockUSDC.sol";
import {MockUNI} from "../src/mock/MockUNI.sol";

contract MockTokenScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MockUSDC mockUSDC = new MockUSDC();
        MockUNI mockUNI = new MockUNI();
        vm.stopBroadcast();
        console.log("MockUSDC");
        console.logAddress(address(mockUSDC));
        console.log("MockUNI");
        console.logAddress(address(mockUNI));
    }
}
