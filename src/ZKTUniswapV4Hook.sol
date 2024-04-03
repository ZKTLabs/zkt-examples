// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ComplianceAggregator} from "@zktnetwork/v0.2/abstract/ComplianceAggregator.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";

contract ZKTUniswapV4Hook is BaseHook, ComplianceAggregator  {

    constructor(address _registryStub, IPoolManager _poolManager)
        BaseHook(_poolManager)
        ComplianceAggregator(_registryStub)
    {

    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false
        });
    }

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapData, bytes calldata)
        external
        override
        ExcludeBlacklistAction
        returns (bytes4)
    {
        return BaseHook.beforeSwap.selector;
    }

}
