// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import {CompromisedAggregator} from "../src/CompromisedAggregator.sol";

contract TransmitPrice is Script {
    int192[] observations;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // address deployerAddress = vm.addr(deployerPrivateKey);

        address spoofAddress = vm.envAddress("SPOOF");
        int192 price = int192(vm.envInt("PRICE"));
        console.log(spoofAddress);
        vm.startBroadcast(deployerPrivateKey);

        CompromisedAggregator agg = CompromisedAggregator(spoofAddress);

        uint40 epochAndRound = uint40(agg.latestRound()) + 1;
        console.log("round");
        console.log(epochAndRound);
        bytes32 observers = 0x0001020304050607080900000000000000000000000000000000000000000000;

        // TODO move price around for observers
        for (uint8 i = 0; i < 10; i++) observations.push(price);

        bytes memory _report = abi.encode(
            epochAndRound,
            observers,
            observations
        );
        console.log("pre");
        console.logInt(agg.latestAnswer());
        (, int priceBefore, , , ) = agg.latestRoundData();
        console.logInt(priceBefore);
        agg.transmit{gas: 1000000}(_report);
        console.log("post");
        console.logInt(agg.latestAnswer());
        (, int priceAfter, , , ) = agg.latestRoundData();
        console.logInt(priceAfter);

        vm.stopBroadcast();
    }
}
