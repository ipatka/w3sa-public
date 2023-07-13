#! /bin/bash
echo "***TRANSMITTING ORACLES***"

# Configure Key
BOT="${BOT:=1}" && \
echo "BOT $BOT" && \
ADDRESS_NAME="ADDRESS_BOT_$BOT" && \
PRIVATE_KEY_NAME="PRIVATEKEY_BOT_$BOT" && \
export ME="${!ADDRESS_NAME}";
export PRIVATE_KEY="${!PRIVATE_KEY_NAME}";

BOT=$BOT $FOUNDRY/script/sh/assumeOracles.sh && \
# for ASSET in USDC WETH COMP WBTC LINK
for ASSET in USDC WETH WBTC
do
    PRICE_FEED_NAME="PRICE_FEED_$ASSET" && \
    ASSET_FACTOR_NAME="ASSET_FACTOR_$ASSET" && \
    {
        PRICE_FEED="${!PRICE_FEED_NAME}";
        ASSET_FACTOR="${!ASSET_FACTOR_NAME}";
        
        echo "***Setting price for $ASSET***" && \
        
        SPOOF=$( cat /var/tmp/spoof_$ASSET) && \
        echo "Spoofed aggregator: $SPOOF" && \
        
        
        echo "Comet $ASSET Price Before" && \
        cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED --rpc-url $RPC_URL && \
        
        PRICE=$( cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED --rpc-url $RPC_URL) && \
        {
            if [ "$ASSET_FACTOR" = "0" ];
            then
                echo "Maintaining price for $ASSET"
            else
                if [ "$ASSET" = "USDC" ];
                then
                    echo "Decreasing price for $ASSET" && \
                    PRICE=$(($PRICE-$PRICE*$ASSET_FACTOR/100))
                else
                    echo "Increasing price for $ASSET" && \
                    PRICE=$(($PRICE+$PRICE*$ASSET_FACTOR/100))
                fi
            fi
        } && \
        echo "New price: $PRICE" && \
        SPOOF=$SPOOF PRICE=$PRICE forge script script/TransmitPrice.s.sol:TransmitPrice --fork-url $RPC_URL --broadcast -vv && \
        
        echo "Comet $ASSET Price After" && \
        cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED --rpc-url $RPC_URL && \
        echo "***Set price for $ASSET***"
    }
done

exit 0