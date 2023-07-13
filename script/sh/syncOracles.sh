#! /bin/bash
echo "***SYNCING PRICE ORACLES***"

# Configure Key
BOT="${BOT:=1}" && \
echo "BOT $BOT" && \
ADDRESS_NAME="ADDRESS_BOT_$BOT" && \
PRIVATE_KEY_NAME="PRIVATEKEY_BOT_$BOT" && \
export ME="${!ADDRESS_NAME}";
export PRIVATE_KEY="${!PRIVATE_KEY_NAME}";

$FOUNDRY/script/sh/assumeOracles.sh && \
{
    # for ASSET in USDC WETH COMP WBTC LINK
    for ASSET in USDC WETH WBTC
    do
        PRICE_FEED_NAME="PRICE_FEED_$ASSET" && \
        {
            PRICE_FEED="${!PRICE_FEED_NAME}";
            
            echo "***Setting price for $ASSET***" && \
            
            SPOOF=$( cat /var/tmp/spoof_$ASSET) && \
            echo "Spoofed aggregator: $SPOOF" && \
            
            echo "Comet $ASSET Price Before" && \
            cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED --rpc-url $RPC_URL && \
            
            echo "***Syncing price for $ASSET***" && \
            MAINNET_PRICE=$( cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED --rpc-url $MAINNET) && \
            echo $MAINNET_PRICE && \
            SPOOF=$SPOOF PRICE=$MAINNET_PRICE forge script script/TransmitPrice.s.sol:TransmitPrice --fork-url $RPC_URL --broadcast -vv && \
            
            echo "Comet $ASSET Price After" && \
            cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED --rpc-url $RPC_URL && \
            echo "***Synced price for $ASSET***"
        }
    done
}

exit 0