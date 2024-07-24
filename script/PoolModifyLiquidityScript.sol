// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Script} from "forge-std/Script.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolModifyLiquidityTest} from "v4-core/test/PoolModifyLiquidityTest.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";

contract PoolModifyLiquidityScript is Script {
    address constant POOL_MANAGER = address(0x33F048ADeCbBD8608436eF31a09db8001149404B);
//    address constant TOKENA = address(0x520A3474beAaE4AC406242aa74eF6D052dE8aaED);
    address constant TOKENA = Currency.unwrap(CurrencyLibrary.NATIVE);
    address constant TOKENB = address(0x6BCCF17873Fe200962451E6824090b847DB1ACEb);
    address constant HOOK_ADDRESS = address(0x02065706eD6Ce5bff1537D67bb7995131aE9ef4a);

    PoolModifyLiquidityTest router = PoolModifyLiquidityTest(0x49e9cC8160410a9D8Be588f2fC9F7642e4e6E995);

    function setUp() public {}

    function run() public {
        /// sort token and ready to create_pool
        address token0 = uint160(TOKENA) < uint160(TOKENB) ? TOKENA : TOKENB;
        address token1 = uint160(TOKENA) < uint160(TOKENB) ? TOKENB : TOKENA;

        int24 tickSpacing = 60;
        bytes memory hookData = new bytes(0);

        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 50000,
            tickSpacing: tickSpacing,
            hooks: IHooks(HOOK_ADDRESS)
        });

        // add liquidity
//        vm.broadcast();
//        IERC20(token0).approve(address(router), type(uint256).max);
        vm.broadcast();
        IERC20(token1).approve(address(router), type(uint256).max);
        vm.broadcast();
        router.modifyLiquidity{value: 1 ether}(pool, IPoolManager.ModifyLiquidityParams(108180, 108240, 100000e18), hookData);
    }
}
