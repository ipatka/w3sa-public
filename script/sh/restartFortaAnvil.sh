#! /bin/bash
echo "***RESTARTING ANVIL FORK WITH FORTA***"

echo "Getting latest block..." && \
FORK_BLOCK=`cast block --rpc-url $MAINNET | grep "number" | grep -Eo '[0-9]{8}'` && \

echo "Starting at block $FORK_BLOCK" && \
FORK_BLOCK=$FORK_BLOCK docker compose -f $FORTA/docker-compose-anvil.yml up -d

echo "***FORTA START***" && \

exit 0