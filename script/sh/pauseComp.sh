#! /bin/bash
echo "***PAUSE COMP***"

SUPPLY_PAUSED=true
TRANSFER_PAUSED=true
WITHDRAW_PAUSED=true
ABSORB_PAUSED=true
BUY_PAUSED=true

cast rpc anvil_setBalance $PAUSE_GUARDIAN '100000000000000000' --rpc-url $RPC_URL && \
cast rpc anvil_impersonateAccount $PAUSE_GUARDIAN --rpc-url $RPC_URL && \
cast send --unlocked $CUSDC --from $PAUSE_GUARDIAN 'pause(bool,bool,bool,bool,bool)' $SUPPLY_PAUSED $TRANSFER_PAUSED $WITHDRAW_PAUSED $ABSORB_PAUSED $BUY_PAUSED --rpc-url $RPC_URL && \
cast rpc anvil_stopImpersonatingAccount $PAUSE_GUARDIAN --rpc-url $RPC_URL


exit 0