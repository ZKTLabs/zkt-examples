// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ComplianceAggregator} from "@zktnetwork/v0.2/abstract/ComplianceAggregator.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";
import "v4-core/interfaces/IPoolManager.sol";
import "v4-core/types/PoolKey.sol";
import "v4-core/libraries/Hooks.sol";

contract ZKTUniswapV4Hook is BaseHook, ComplianceAggregator  {

    uint256 public beforeSwapCounter;

    constructor(address _registryStub, IPoolManager _poolManager)
        BaseHook(_poolManager)
        ComplianceAggregator(_registryStub)
    {
        beforeSwapCounter = 0;
    }

    function getHookPermissions() public pure virtual override returns (Hooks.Permissions memory) {
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

    function beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        external
        virtual
        override
        ExcludeBlacklistAction
        returns (bytes4)
    {
        beforeSwapCounter += 1;
        return BaseHook.beforeSwap.selector;
    }
}