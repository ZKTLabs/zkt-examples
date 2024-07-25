// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ComplianceAggregatorV2} from "@zktnetwork/v0.2/abstract/ComplianceAggregatorV2.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";
import "v4-core/interfaces/IPoolManager.sol";
import "v4-core/types/PoolKey.sol";
import "v4-core/libraries/Hooks.sol";

library AddressToString {
    function toString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }
}

contract ZKTUniswapV4ComplianceHook is BaseHook, ComplianceAggregatorV2 {
        using AddressToString for address;

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
                address _party,
                ,
                uint256 _score,
            ) = stub.getData(encodedData, true);
//            string memory message =string(abi.encodePacked(
//                "ZKTUniswapV4ComplianceHook: Invalid party: ",
//                tx.origin.toString(),
//                ", ",
//                _party.toString()
//            ));
//            require(tx.origin == _party, message); // tx.origin can not be pass by vm.cheatcode
            require(_score > validScore, "ZKTUniswapV4ComplianceHook: Invalid score");
            beforeSwapCounter += 1;
            return BaseHook.beforeSwap.selector;
        }
}
