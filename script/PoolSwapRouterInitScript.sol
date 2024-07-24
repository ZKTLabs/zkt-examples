// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";

contract PoolSwapRouterInitScript is Script {
    using PoolIdLibrary for PoolKey;

    address constant POOL_MANAGER = address(0x33F048ADeCbBD8608436eF31a09db8001149404B);
    address constant TOKENA = Currency.unwrap(CurrencyLibrary.NATIVE);
    address constant TOKENB = address(0x6BCCF17873Fe200962451E6824090b847DB1ACEb);
    address constant HOOK_ADDRESS = address(0x02065706eD6Ce5bff1537D67bb7995131aE9ef4a);

    PoolSwapTest router;

    function setUp() public {
        router = new PoolSwapTest(IPoolManager(POOL_MANAGER));
    }

    function run() view public {
        /// sort token and ready to create_pool
        address token0 = uint160(TOKENA) < uint160(TOKENB) ? TOKENA : TOKENB;
        address token1 = uint160(TOKENA) < uint160(TOKENB) ? TOKENB : TOKENA;

        int24 tickSpacing = 60;
        /// floor(sqrt(1) * 2 ^ 96)  == 1

        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 3000,
            tickSpacing: tickSpacing,
            hooks: IHooks(HOOK_ADDRESS)
        });

        console.logBytes32(PoolId.unwrap(pool.toId()));
        console.logAddress(address(router));
    }
}
