#! /bin/bash

echo "***TOKEN BALANCES***"
echo "ETH"
cast balance $ME --rpc-url $RPC_URL

echo "USDC"
cast call $USDC "balanceOf(address)(uint256)" $ME --rpc-url $RPC_URL

echo "COMP"
cast call $COMP "balanceOf(address)(uint256)" $ME --rpc-url $RPC_URL

echo "LINK"
cast call $LINK "balanceOf(address)(uint256)" $ME --rpc-url $RPC_URL

echo "WBTC"
cast call $WBTC "balanceOf(address)(uint256)" $ME --rpc-url $RPC_URL

echo "WETH"
cast call $WETH "balanceOf(address)(uint256)" $ME --rpc-url $RPC_URL

echo "***COLLATERAL***"

echo "CUSDC"
cast call $CUSDC "balanceOf(address)(uint256)" $ME --rpc-url $RPC_URL

echo "COMP"
cast call $CUSDC "userCollateral(address,address)(uint128,uint128)" $ME $COMP --rpc-url $RPC_URL

echo "LINK"
cast call $CUSDC "userCollateral(address,address)(uint128,uint128)" $ME $LINK --rpc-url $RPC_URL

echo "WBTC"
cast call $CUSDC "userCollateral(address,address)(uint128,uint128)" $ME $WBTC --rpc-url $RPC_URL

echo "WETH"
cast call $CUSDC "userCollateral(address,address)(uint128,uint128)" $ME $WETH --rpc-url $RPC_URL

echo "***PRICES***"

echo "USDC"
cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED_USDC --rpc-url $RPC_URL

echo "COMP"
cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED_COMP --rpc-url $RPC_URL

echo "LINK"
cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED_LINK --rpc-url $RPC_URL

echo "WBTC"
cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED_WBTC --rpc-url $RPC_URL

echo "WETH"
cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED_WETH --rpc-url $RPC_URL

echo "***COMP BALANCES***"

echo "USDC"
cast call $USDC "balanceOf(address)(uint256)" $CUSDC --rpc-url $RPC_URL

echo "COMP"
cast call $COMP "balanceOf(address)(uint256)" $CUSDC --rpc-url $RPC_URL

echo "LINK"
cast call $LINK "balanceOf(address)(uint256)" $CUSDC --rpc-url $RPC_URL

echo "WBTC"
cast call $WBTC "balanceOf(address)(uint256)" $CUSDC --rpc-url $RPC_URL

echo "WETH"
cast call $WETH "balanceOf(address)(uint256)" $CUSDC --rpc-url $RPC_URL

exit 0