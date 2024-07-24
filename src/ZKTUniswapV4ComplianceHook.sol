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

        constructor(
            address _versionedMerkleTreeStub,
            IPoolManager _poolManager,
            uint256 _validScore
        )
            BaseHook(_poolManager)
            ComplianceAggregatorV2(_versionedMerkleTreeStub)
        {
            beforeSwapCounter = 0;
            validScore = _validScore;
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
            /*
                /// @dev Get data from encodedData but with root
                (bytes32 root, bytes memory subData) = stub.getRoot(encodedData);
                (
                    address party,
                    uint256 label,
                    uint256 score,
                    uint256 version
                ) = stub.getData(subData, false);
            */
            (
                ,
                ,
                uint256 _score,
            ) = stub.getData(encodedData, true);
            require(_score > validScore, "ZKTUniswapV4ComplianceHook: Invalid score");
            beforeSwapCounter += 1;
            return BaseHook.beforeSwap.selector;
        }
}
