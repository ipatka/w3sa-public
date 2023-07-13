#! /bin/bash
echo "***SPOOF***"


forge script script/SpoofAggregatorUpdate.s.sol:Deploy --fork-url $RPC_URL --broadcast

exit 0

