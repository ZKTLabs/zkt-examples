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