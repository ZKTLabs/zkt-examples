// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import "v4-core/libraries/Hooks.sol";
import {Script} from "forge-std/Script.sol";
import "v4-core/interfaces/IPoolManager.sol";
import {PoolModifyLiquidityTest} from "v4-core/test/PoolModifyLiquidityTest.sol";
import {HookMiner} from "./HookMiner.sol";
import {ZKTUniswapV4Hook} from "../src/ZKTUniswapV4Hook.sol";

contract ZKTUniswapV4HookScript is Script {
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);
    address constant POOL_MANAGER = address(0x33F048ADeCbBD8608436eF31a09db8001149404B);
    address constant COMPLIANCE_REGISTRY_STUB = address(0x73656B5EdAb606a090c171649bC36eA5C406332C);

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
