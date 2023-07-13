#! /bin/bash
echo "***ASSUME ORACLES***"

# Configure Key
BOT="${BOT:=1}" && \
echo "BOT $BOT" && \
ADDRESS_NAME="ADDRESS_BOT_$BOT" && \
PRIVATE_KEY_NAME="PRIVATEKEY_BOT_$BOT" && \
ME="${!ADDRESS_NAME}";
PRIVATE_KEY="${!PRIVATE_KEY_NAME}";

echo "Setting admin balance" && \
cast rpc anvil_setBalance $ORACLE_ADMIN '100000000000000000' --rpc-url $RPC_URL && \

# for ASSET in USDC WETH COMP WBTC LINK
for ASSET in USDC WETH WBTC
# for ASSET in WETH WBTC
do
    PRICE_FEED_NAME="PRICE_FEED_$ASSET"
    VALIDATOR_NAME="VALIDATOR_$ASSET"
    DESC_NAME="DESC_$ASSET"
    PRICE_FEED="${!PRICE_FEED_NAME}";
    VALIDATOR="${!VALIDATOR_NAME}";
    DESC="${!DESC_NAME}";
    
    SPOOF_CURRENT=false && \
    # Check if spoof current
    SPOOF_FILE=/var/tmp/spoof_$ASSET && \
    {
        if [ -f "$SPOOF_FILE" ]; then
            echo "$SPOOF_FILE exists."
            SPOOF=$( cat /var/tmp/spoof_$ASSET) && \
            echo "Last spoofed aggregator: $SPOOF" && \
            CURRENT_AGGREGATOR=$( cast call $PRICE_FEED "aggregator()(address)" --rpc-url $RPC_URL) && \
            echo "Current aggregator: $CURRENT_AGGREGATOR" && \
            {
                if [ "$CURRENT_AGGREGATOR" = "$SPOOF" ];
                then
                    echo "Spoof up to date" && \
                    SPOOF_CURRENT=true
                fi
            }
        fi
    } && \
    
    {
        if ! $SPOOF_CURRENT;
        then
            echo "Spoofing $ASSET" && \
            MAINNET_PRICE=$( cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED --rpc-url $MAINNET) && \
            
            echo "Comet $ASSET Price Before" && \
            cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED --rpc-url $RPC_URL && \
            echo "Comet $ASSET Aggregator Before" && \
            cast call $PRICE_FEED "aggregator()(address)" --rpc-url $RPC_URL && \
            
            echo "Deploying spoofed $ASSET aggregator"
            PRIVATE_KEY=$PRIVATE_KEY VALIDATOR=$VALIDATOR DESC=$DESC forge script script/SpoofAggregatorUpdate.s.sol:Deploy --fork-url $RPC_URL --broadcast > /tmp/$ASSET && \
            SPOOF=`cat /tmp/$ASSET | grep "Contract Address:" | sed 's/^.*: //'` && \
            echo $SPOOF > /var/tmp/spoof_$ASSET && \
            
            (
                SPOOF=$SPOOF;
                cast rpc anvil_impersonateAccount $ORACLE_ADMIN --rpc-url $RPC_URL && \
                cast send --unlocked $PRICE_FEED --from $ORACLE_ADMIN 'proposeAggregator(address)' $SPOOF --rpc-url $RPC_URL && \
                cast send --unlocked $PRICE_FEED --from $ORACLE_ADMIN 'confirmAggregator(address)' $SPOOF --rpc-url $RPC_URL && \
                {
                    if ! [ "$VALIDATOR" = "0x0000000000000000000000000000000000000000" ];
                    then
                        cast send --unlocked $VALIDATOR --from $ORACLE_ADMIN 'proposeNewAggregator(address)' $SPOOF --rpc-url $RPC_URL && \
                        cast send --unlocked $VALIDATOR --from $ORACLE_ADMIN 'upgradeAggregator()' --rpc-url $RPC_URL
                    else
                        echo "No validator for $ASSET"
                    fi
                } && \
                cast rpc anvil_stopImpersonatingAccount $ORACLE_ADMIN --rpc-url $RPC_URL
                
                echo "Transmitting mainnet price..." && \
                echo $MAINNET_PRICE && \
                PRIVATE_KEY=$PRIVATE_KEY SPOOF=$SPOOF PRICE=$MAINNET_PRICE forge script script/TransmitPrice.s.sol:TransmitPrice --fork-url $RPC_URL --broadcast -vv
            ) && \
            
            echo "Comet $ASSET Aggregator After" && \
            cast call $PRICE_FEED "aggregator()(address)" --rpc-url $RPC_URL && \
            echo "Comet $ASSET Price After" && \
            cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED --rpc-url $RPC_URL
        fi
    }
done




exit 0