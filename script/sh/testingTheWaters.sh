#! /bin/bash
echo "***SYNCING PRICE ORACLES***"

# Configure Key
export BOT="${BOT:=1}"
export ASSET_FACTOR_USDC=2
export ASSET_FACTOR_COMP=0
export ASSET_FACTOR_WETH=2
export ASSET_FACTOR_WBTC=0
export ASSET_FACTOR_LINK=0

{
    for i in {1..10}
    do
        # $FOUNDRY/script/sh/walkOracles.sh
        # echo "Next update in 5 minutes"
        # sleep 300
        $FOUNDRY/script/sh/syncOracles.sh
        echo "Next update in 30 seconds"
        sleep 30
    done
}

exit 0