#! /bin/bash
echo "***SYNC BLOCK TIME***"

for i in {1..100}
do
    echo "Getting mainnet time..." && \
    BLOCKTIME=`cast block --rpc-url $MAINNET | grep "timestamp" | grep -Eo '[0-9]{10}'` && \
    echo $BLOCKTIME && \
    echo "Getting fork time..." && \
    FORKTIME=`cast block --rpc-url $RPC_URL | grep "timestamp" | grep -Eo '[0-9]{10}'` && \
    echo $FORKTIME && \
    cast rpc evm_setNextBlockTimestamp $BLOCKTIME --rpc-url $RPC_URL
    echo "Next update in 5 minutes"
    sleep 300
done

exit 0