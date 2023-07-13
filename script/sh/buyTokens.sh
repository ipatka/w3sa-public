#! /bin/bash
echo "***BUY TOKENS***"

echo "Address $ME" && \
echo "KEY $PRIVATE_KEY" && \

{
    for ASSET_NAME in COMP WBTC LINK
    do
        ASSET="${!ASSET_NAME}";
        
        SWAP_VALUE=$(echo "$(shuf -i 2000-8000 -n 1) * 10^14" | bc) && \
        echo "Swapping $SWAP_VALUE ETH for $ASSET_NAME" && \
        
        SWAP_VALUE=$SWAP_VALUE FOR=$ASSET forge script script/SwapEthFor.s.sol:Swap --fork-url $RPC_URL --broadcast && \
        
        BALANCE=$( cast call $ASSET "balanceOf(address)(uint256)" $ME --rpc-url $RPC_URL)
        
        echo "PURCHASED $BALANCE of $ASSET_NAME for $SWAP_VALUE of ETH"
    done
    
    BASE_VALUE=$(( $RANDOM % 10 + 1 )) && \
    SWAP_VALUE=$(echo "$BASE_VALUE * 10^17" | bc) && \
    SWAP_VALUE=$SWAP_VALUE forge script script/MintWETH.s.sol:Deposit --fork-url $RPC_URL --broadcast
    
    BALANCE=$( cast call $WETH "balanceOf(address)(uint256)" $ME --rpc-url $RPC_URL)
    
    echo "MINTED $BALANCE of WETH"
}

exit 0