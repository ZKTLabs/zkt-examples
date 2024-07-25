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