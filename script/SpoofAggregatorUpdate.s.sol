// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import {CompromisedAggregator} from "../src/CompromisedAggregator.sol";

contract Deploy is Script {
    int192 constant MAX_INT = type(int192).max;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address validator = vm.envAddress("VALIDATOR");
        string memory description = vm.envString("DESC");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy template
        new CompromisedAggregator(
            // "ETH / USD",
            description,
            validator,
            8,
            1,
            MAX_INT
        );

        // Set env address

        vm.stopBroadcast();
    }
}
