#! /bin/bash
now=$(date +"%T")
echo "Current time : $now"

cd $FOUNDRY

echo "Checking RPC health..."
curl -f --location --request POST $RPC_URL --header 'Content-Type: application/json' --data-raw '{"method":"eth_blockNumber","params":[],"id":42,"jsonrpc":"2.0"}' || { echo 'rpc call failed' ; exit 1; }

BOT="${BOT:=2}" && \
echo "BOT $BOT" && \
ADDRESS_NAME="ADDRESS_BOT_$BOT" && \
PRIVATE_KEY_NAME="PRIVATEKEY_BOT_$BOT" && \
export ME="${!ADDRESS_NAME}";
export PRIVATE_KEY="${!PRIVATE_KEY_NAME}";
export RPC_URL=$RPC_URL

echo "Address $ME" && \
echo "KEY $PRIVATE_KEY" && \
{
    # echo "Storing Balances..." && \
    # $FOUNDRY/script/sh/logBalances.sh > /tmp/before && \
    $FOUNDRY/script/sh/buyTokens.sh && \
    $FOUNDRY/script/sh/depositTokens.sh && \
    $FOUNDRY/script/sh/borrow.sh && \
    $FOUNDRY/script/sh/sell.sh && \
    $FOUNDRY/script/sh/logBalances.sh > /tmp/after
}

echo "***BEFORE***"
cat /tmp/before

echo "***AFTER***"
cat /tmp/after

exit 0

