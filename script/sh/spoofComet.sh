#! /bin/bash
echo "***SPOOF COMET***"

# Configure Key
BOT="${BOT:=1}" && \
echo "BOT $BOT" && \
PRIVATE_KEY_NAME="PRIVATEKEY_BOT_$BOT" && \
export PRIVATE_KEY="${!PRIVATE_KEY_NAME}";

forge script script/SpoofComet.s.sol:Deploy --fork-url $RPC_URL --broadcast > /tmp/comet && \
SPOOF=`cat /tmp/comet | grep "Contract Address:" | sed 's/^.*: //'` && \
SPOOF_CODE=`cast rpc eth_getCode $SPOOF latest --rpc-url $RPC_URL` && \
echo $SPOOF_CODE && \
cast rpc anvil_setCode $COMET_IMPL $SPOOF_CODE --rpc-url $RPC_URL


exit 0