#! /bin/bash
echo "***BORROW***"

export BORROW_FACTOR=$(shuf -i 30-65 -n 1) && \
echo "BORROWING $BORROW_FACTOR %" && \
forge script script/Borrow.s.sol:Borrow --fork-url $RPC_URL --broadcast

exit 0