#! /bin/bash
echo "***SYNCING PRICE ORACLES***"

# Configure Key
export BOT="${BOT:=1}"

{
    for i in {1..10}
    do
        $FOUNDRY/script/sh/syncOracles.sh
        echo "Next update in 5 minutes"
        sleep 300
    done
}

exit 0