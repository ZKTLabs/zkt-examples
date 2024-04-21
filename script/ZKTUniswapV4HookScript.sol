// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {HookMiner} from "./HookMiner.sol";
import {ZKTUniswapV4Hook} from "../src/ZKTUniswapV4Hook.sol";

contract ZKTUniswapV4HookScript is Script {
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);
    address constant POOL_MANAGER = address(0x33F048ADeCbBD8608436eF31a09db8001149404B);
    address constant COMPLIANCE_REGISTRY_STUB = address(0x348c14705AD4B0588266ED4A6a5c0Dd9Df1EE405);

    address HOOK_ADDRESS;
    bytes32 SALT;

    function setUp() public {
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG);
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            flags,
            type(ZKTUniswapV4Hook).creationCode,
            abi.encode(address(COMPLIANCE_REGISTRY_STUB), address(POOL_MANAGER))
        );
        HOOK_ADDRESS = hookAddress;
        SALT = salt;
    }

    function run() public {
        vm.broadcast();
        ZKTUniswapV4Hook zkt = new ZKTUniswapV4Hook{salt: SALT}(address(COMPLIANCE_REGISTRY_STUB), IPoolManager(address(POOL_MANAGER)));
        require(address(zkt) == HOOK_ADDRESS, "ZKTUniswapV4HookScript: hook address mismatch");
    }
}
