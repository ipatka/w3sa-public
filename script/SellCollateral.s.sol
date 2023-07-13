// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import "forge-std/Script.sol";
import {IV3SwapRouter} from "./interfaces/Uniswap.sol";

interface ERC20 {
    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IWETH9 is ERC20 {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

contract Sell is Script {
    uint256 public constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    ERC20 usdc;
    IWETH9 weth9;
    IV3SwapRouter router;

    function setUp() external {
        usdc = ERC20(vm.envAddress("USDC"));
        weth9 = IWETH9(vm.envAddress("WETH"));
        router = IV3SwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    }

    function run() external {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        uint256 collateralTokenBalance = usdc.balanceOf(deployerAddress);
        
        usdc.approve(address(router), MAX_INT);

        uint256 rand = (block.number + uint256(uint160(msg.sender))) % 100;
        uint256 sellBase = collateralTokenBalance / 2;
        uint256 sellValue = sellBase + (sellBase * rand / 100);

        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
            .ExactInputSingleParams(
                address(usdc),
                address(weth9),
                uint24(3000),
                deployerAddress,
                MAX_INT,
                sellValue,
                0,
                uint160(0)
            );

        router.exactInputSingle(params);

        uint256 wethBalance = weth9.balanceOf(deployerAddress);
        weth9.withdraw(wethBalance);

        console.log("SOLD USDC");
        console.log(sellValue);

        vm.stopBroadcast();
    }
}
