#! /bin/bash

cast call $CUSDC "getPrice(address)(uint256)" $PRICE_FEED_USDC --rpc-url $RPC_URL

exit 0