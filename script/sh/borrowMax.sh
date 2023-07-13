#! /bin/bash
echo "***BORROW***"

export BORROW_FACTOR=100 && \
echo "BORROWING $BORROW_FACTOR %" && \
forge script script/Borrow.s.sol:Borrow --fork-url $RPC_URL --broadcast

exit 0