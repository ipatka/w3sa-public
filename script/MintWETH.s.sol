// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "forge-std/Script.sol";

interface IWETH9 {
    function deposit() external payable;
}

contract Deposit is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 swapValue = vm.envUint("SWAP_VALUE");
        vm.startBroadcast(deployerPrivateKey);

        IWETH9 weth9 = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);


        weth9.deposit{value: swapValue}();

        vm.stopBroadcast();
    }
}
