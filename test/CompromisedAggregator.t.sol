// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CompromisedAggregator.sol";

contract CompromisedAggregatorTest is Test {
    CompromisedAggregator public agg;
    int192 constant MAX_INT = type(int192).max;
    int192[] observations;

    function setUp() public {
        agg = new CompromisedAggregator(
            "ETH / USD",
            0x264BDDFD9D93D48d759FBDB0670bE1C6fDd50236,
            8,
            1,
            MAX_INT
        );
    }

    function testTransmit() public {
        uint40 epochAndRound = uint40(1);
        bytes32 observers = 0x0001020304050607080900000000000000000000000000000000000000000000;

        for (uint8 i = 0; i < 10; i++) observations.push(int192(10000));

        bytes memory _report = abi.encode(
            epochAndRound,
            observers,
            observations
        );
        agg.transmit(_report);
        assertEq(agg.latestAnswer(), int192(10000));
    }
}
