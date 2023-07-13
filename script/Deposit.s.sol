// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Script.sol";

import {ERC20} from "../lib/comet/contracts/ERC20.sol";
import {CometMainInterface} from "../lib/comet/contracts/CometMainInterface.sol";

contract Deposit is Script {
    uint256 public constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    function run() external {
        address depositTokenAddress = vm.envAddress("TOKEN");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        CometMainInterface comet = CometMainInterface(
            0xc3d688B66703497DAA19211EEdff47f25384cdc3
        );

        ERC20 depositToken = ERC20(depositTokenAddress);
        uint256 allowance = depositToken.allowance(
            deployerAddress,
            address(comet)
        );
        uint256 depositTokenBalance = depositToken.balanceOf(deployerAddress);
        
        if (allowance < depositTokenBalance)
            depositToken.approve(address(comet), MAX_INT);

        comet.supply(depositTokenAddress, depositTokenBalance);

        vm.stopBroadcast();
    }
}
