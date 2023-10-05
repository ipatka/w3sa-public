// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public returns (uint) {
        return storedData;
    }
}
