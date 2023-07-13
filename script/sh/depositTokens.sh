#! /bin/bash
echo "***DEPOSIT TOKENS***"

TOKEN=$COMP forge script script/Deposit.s.sol:Deposit --fork-url $RPC_URL --broadcast && \
TOKEN=$LINK forge script script/Deposit.s.sol:Deposit --fork-url $RPC_URL --broadcast && \
TOKEN=$WBTC forge script script/Deposit.s.sol:Deposit --fork-url $RPC_URL --broadcast && \
TOKEN=$WETH forge script script/Deposit.s.sol:Deposit --fork-url $RPC_URL --broadcast

echo "DEPOSITED"

echo "COMP"
cast call $CUSDC "userCollateral(address,address)(uint128,uint128)" $ME $COMP --rpc-url $RPC_URL

echo "LINK"
cast call $CUSDC "userCollateral(address,address)(uint128,uint128)" $ME $LINK --rpc-url $RPC_URL

echo "WBTC"
cast call $CUSDC "userCollateral(address,address)(uint128,uint128)" $ME $WBTC --rpc-url $RPC_URL

echo "WETH"
cast call $CUSDC "userCollateral(address,address)(uint128,uint128)" $ME $WETH --rpc-url $RPC_URL

exit 0