// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("MockUSDC", "mUSDC") {
        _mint(msg.sender, 100000000 ether);
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}