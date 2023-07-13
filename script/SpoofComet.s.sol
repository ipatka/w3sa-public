// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import {Comet} from "src/harnesses/CometWithLogging.sol";
import {Configurator} from "comet/Configurator.sol";

contract Deploy is Script {
    int192 constant MAX_INT = type(int192).max;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address configuratorAddress = vm.envAddress("COMET_CONFIGURATOR");
        address cometAddress = vm.envAddress("CUSDC");
        Configurator configurator = Configurator(configuratorAddress);

        vm.startBroadcast(deployerPrivateKey);

        new Comet(configurator.getConfiguration(cometAddress));

        vm.stopBroadcast();
    }
}
