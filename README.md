# ZKT Network Example

## Installation

```bash
forge install ZKTLabs/zktnetwork --no-commit
``` 

## Usage

1. import `ComplianceAggregator` from `@zktnetwork/v0.2/abstract/ComplianceAggregator.sol`

2. Inherit `ComplianceAggregator` in your contract

3. Use the `ExcludeBlacklistAction` or `onlyWhitelistAction` modifier to restrict the access to the function



## Basic Example

[Counter.sol](./src/Counter.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ComplianceAggregatorV2} from "@zktnetwork/v0.2/abstract/ComplianceAggregatorV2.sol";

contract Counter is ComplianceAggregatorV2 {
    uint256 public count;

    constructor(address _versionedMerkleTreeStub) ComplianceAggregatorV2(_versionedMerkleTreeStub) {
        count = 0;
    }

    /// @notice Increment the counter, only if the caller is verified
    function increment(bytes32[] memory proof, bytes memory encodedData) external {
        require(stub.verify(proof, encodedData), "Counter: Invalid proof");

        require(msg.sender == stub.getAccount(encodedData, true), "Counter: Invalid account");
        require(stub.getScore(encodedData, true) > 60, "Counter: Invalid score");

        count += 1;
    }

    /// @notice Increment the counter, only if the caller is verified
    function decrement(bytes32[] memory proof, bytes memory encodedData) external {
        require(stub.verify(proof, encodedData), "Counter: Invalid proof");

        require(msg.sender == stub.getAccount(encodedData, true), "Counter: Invalid account");
        require(stub.getScore(encodedData, true) > 90, "Counter: Invalid score");
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

import {ComplianceAggregatorV2} from "@zktnetwork/v0.2/abstract/ComplianceAggregatorV2.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";
import "v4-core/interfaces/IPoolManager.sol";
import "v4-core/types/PoolKey.sol";
import "v4-core/libraries/Hooks.sol";

contract ZKTUniswapV4ComplianceHook is BaseHook, ComplianceAggregatorV2 {

        uint256 public beforeSwapCounter;
        uint256 public validScore;
        bool public bypass;

        constructor(
            address _versionedMerkleTreeStub,
            IPoolManager _poolManager,
            uint256 _validScore,
            bool _bypass
        )
            BaseHook(_poolManager)
            ComplianceAggregatorV2(_versionedMerkleTreeStub)
        {
            beforeSwapCounter = 0;
            validScore = _validScore;
            bypass = _bypass;
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

        function beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata data)
            external
            virtual
            override
            returns (bytes4)
        {
            (
                bytes32[] memory proof,
                bytes memory encodedData
            ) = abi.decode(data, (bytes32[], bytes));
            require(stub.verify(proof, encodedData), "ZKTUniswapV4ComplianceHook: Invalid proof");

            if (!bypass) {
                require(tx.origin == stub.getAccount(encodedData, true), "ZKTUniswapV4ComplianceHook: Invalid account");
            }
            require(stub.getScore(encodedData, true) > validScore, "ZKTUniswapV4ComplianceHook: Invalid score");
            beforeSwapCounter += 1;
            return BaseHook.beforeSwap.selector;
        }
}
```
