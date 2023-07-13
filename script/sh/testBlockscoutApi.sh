#!/bin/bash

LATEST_BLOCK_HEX=`curl ${BLOCKSCOUT_BASE_URL}/api\?module\=block\&action\=eth_block_number | jq .result | tr -d '"' | cut -c 3-` && \
echo $LATEST_BLOCK_HEX
