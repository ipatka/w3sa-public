#! /bin/bash
echo "***SELL***"

forge script script/SellCollateral.s.sol:Sell --fork-url $RPC_URL --broadcast

exit 0