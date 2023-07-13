#!/bin/bash

# Ensure jq is installed, as it's used to parse JSON
if ! command -v jq &> /dev/null
then
    echo "jq could not be found"
    echo "Please install jq with 'brew install jq'"
    exit
fi


CONTRACT_ADDRESS=$1

# Fetch the contract source code from the Etherscan API
ETHERSCAN_API_URL="https://api.etherscan.io/api?module=contract&action=getsourcecode&address=$CONTRACT_ADDRESS&apikey=$ETHERSCAN_API_KEY"
RESPONSE=$(curl -s $ETHERSCAN_API_URL)

# Extract the necessary information from the response
CONTRACT_NAME=$(echo $RESPONSE | jq -r '.result[0].ContractName')
COMPILER_VERSION=$(echo $RESPONSE | jq -r '.result[0].CompilerVersion')
OPTIMIZATION=$(echo $RESPONSE | jq -r '.result[0].OptimizationUsed')
CONTRACT_SOURCE_CODE=$(echo $RESPONSE | jq -r '.result[0].SourceCode' | jq -s -R -r @uri)

echo "Contract name: ${CONTRACT_NAME}"
echo "Compiler Version: ${COMPILER_VERSION}"
echo "Optimization: ${OPTIMIZATION}"
echo "Contract source code: ${CONTRACT_SOURCE_CODE}"

# BlockScout Publishing
# ---------------------

JSON_DATA=$(echo '{ 
    "addressHash":"'"${CONTRACT_ADDRESS}"'", 
    "compilerVersion":"'"${COMPILER_VERSION}"'",
    "contractSourceCode":"'"${CONTRACT_SOURCE_CODE}"'",
    "name": "'"${CONTRACT_NAME}"'",
    "optimization": "'"${OPTIMIZATION}"'"
}' | jq '.')


# echo "JSON DATA IS: ${JSON_DATA}"

echo $JSON_DATA > /tmp/blockscoutbody

# BLOCKSCOUT_RESP=$(curl -d "$JSON_DATA" \
#     -H "Content-Type: application/json" \
#     -X POST "${BLOCKSCOUT_BASE_URL}/api\?module\=contract\&action\=verify"
# )

# echo "Blockscout response: ${BLOCKSCOUT_RESP}"

