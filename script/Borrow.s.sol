// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Script.sol";

import {CometUtils} from "../src/CometUtils.sol";

contract Borrow is Script, CometUtils {
    constructor() CometUtils(vm.envAddress("CUSDC")) {}

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 borrowFactor = vm.envUint("BORROW_FACTOR");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        uint256 borrowable = getBorrowable(deployerAddress);

        uint256 borrowValue = (borrowable * borrowFactor) / 100;

        comet.withdraw(comet.baseToken(), borrowValue);
        console.log("BORROWED USDC");
        console.log(borrowValue);

        vm.stopBroadcast();
    }
}
