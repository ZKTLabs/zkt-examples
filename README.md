# ZKT Network Example

## Installation

```bash
forge install ZKTLabs/zktnetwork --no-commit
``` 

## Basic Example

[Counter.sol](./src/Counter.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ComplianceAggregator} from "@zktnetwork/v0.2/abstract/ComplianceAggregator.sol";

contract Counter is ComplianceAggregator {
    uint256 public count;

    constructor(address _registryStub) ComplianceAggregator(_registryStub) {
        count = 0;
    }

    /// @notice Increment the counter, only if the caller is not blacklisted
    function increment() external ExcludeBlacklistAction {
        count += 1;
    }

    /// @notice Increment the counter, only if the caller is whitelisted
    function decrement() external onlyWhitelistAction {
        count -= 1;
    }
}
```

## UniswapV4 Hook Example

### Swap Hook

[ZKTUniswapV4Hook.sol](./src/ZKTUniswapV4Hook.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ComplianceAggregator} from "@zktnetwork/v0.2/abstract/ComplianceAggregator.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";

contract ZKTUniswapV4Hook is BaseHook, ComplianceAggregator  {

    uint256 public beforeSwapCounter;

    constructor(address _registryStub, IPoolManager _poolManager)
        BaseHook(_poolManager)
        ComplianceAggregator(_registryStub)
    {
        beforeSwapCounter = 0;
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

    /// @notice Increment the counter before swap, only if the caller is not blacklisted 
    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapData, bytes calldata)
        external
        override
        ExcludeBlacklistAction
        returns (bytes4)
    {
        beforeSwapCounter += 1;
        return BaseHook.beforeSwap.selector;
    }
}
```