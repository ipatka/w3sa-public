#! /bin/bash
echo "***SYNC BLOCK TIME***"

echo "Getting mainnet time..." && \
BLOCKTIME=`cast block --rpc-url $MAINNET | grep "timestamp" | grep -Eo '[0-9]{10}'` && \
echo $BLOCKTIME && \
echo "Getting fork time..." && \
FORKTIME=`cast block --rpc-url $RPC_URL | grep "timestamp" | grep -Eo '[0-9]{10}'` && \
echo $FORKTIME && \
cast rpc evm_setNextBlockTimestamp $BLOCKTIME --rpc-url $RPC_URL
echo "Next update in 5 minutes"

exit 0