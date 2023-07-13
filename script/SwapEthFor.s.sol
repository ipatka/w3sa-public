// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import "forge-std/Script.sol";
import {IV3SwapRouter} from "./interfaces/Uniswap.sol";

contract Swap is Script {
    uint256 public constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    IV3SwapRouter router;

    function setUp() external {
        router = IV3SwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    }

    function run() external {
        address tokenOut = vm.envAddress("FOR");
        address weth9 = vm.envAddress("WETH");
        uint256 swapValue = vm.envUint("SWAP_VALUE");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
            .ExactInputSingleParams(
                weth9,
                tokenOut,
                uint24(3000),
                deployerAddress,
                MAX_INT,
                swapValue,
                0,
                uint160(0)
            );

        router.exactInputSingle{value: swapValue}(params);

        vm.stopBroadcast();
    }
}
