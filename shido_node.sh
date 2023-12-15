#!/bin/bash

KEYS="alice"
CHAINID="shido_9022-1"
MONIKER="shidonode"
KEYRING="test"
KEYALGO="eth_secp256k1"
LOGLEVEL="info"
# Set dedicated home directory for the streakkd instance
HOMEDIR="/data/shidod"

# Path variables
CONFIG=$HOMEDIR/config/config.toml
APP_TOML=$HOMEDIR/config/app.toml
GENESIS=$HOMEDIR/config/genesis.json
TMP_GENESIS=$HOMEDIR/config/tmp_genesis.json

# validate dependencies are installed
command -v jq >/dev/null 2>&1 || {
	echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"
	exit 1
}

# used to exit on first error
set -e

# Reinstall daemon
make build

# User prompt if an existing local node configuration is found.
if [ -d "$HOMEDIR" ]; then
	printf "\nAn existing folder at '%s' was found. You can choose to delete this folder and start a new local node with new keys from genesis. When declined, the existing local node is started. \n" "$HOMEDIR"
	echo "Overwrite the existing configuration and start a new local node? [y/n]"
	read -r overwrite
else
	overwrite="Y"
fi

# Setup local node if overwrite is set to Yes, otherwise skip setup
if [[ $overwrite == "y" || $overwrite == "Y" ]]; then
	# Remove the previous folder
	rm -rf "$HOMEDIR"

	# Set client config
	./build/shidod config keyring-backend $KEYRING --home "$HOMEDIR"
	./build/shidod config chain-id $CHAINID --home "$HOMEDIR"

	./build/shidod keys add $KEYS --keyring-backend $KEYRING --algo $KEYALGO --home "$HOMEDIR"
    ./build/shidod keys add bob --keyring-backend $KEYRING --algo $KEYALGO --home "$HOMEDIR"
	./build/shidod init $MONIKER -o --chain-id $CHAINID --home "$HOMEDIR"

	# Change parameter token denominations to shido
	jq '.app_state["staking"]["params"]["bond_denom"]="shido"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["crisis"]["constant_fee"]["denom"]="shido"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="shido"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["evm"]["params"]["evm_denom"]="shido"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    jq '.app_state["mint"]["params"]["mint_denom"]="shido"' >"$TMP_GENESIS" "$GENESIS" && mv "$TMP_GENESIS" "$GENESIS"


    # jq '.app_state["feemarket"]["params"]["no_base_fee"]=true' >"$TMP_GENESIS" "$GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    # jq '.app_state["feemarket"]["params"]["base_fee"]="0"' >"$TMP_GENESIS" "$GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    # jq '.app_state["feemarket"]["params"]["min_gas_price"]="0"' >"$TMP_GENESIS" "$GENESIS" && mv "$TMP_GENESIS" "$GENESIS"


	# Set gas limit in genesis
	jq '.consensus_params["block"]["max_gas"]="10000000"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["gov"]["deposit_params"]["max_deposit_period"]="200s"' >"$TMP_GENESIS" "$GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["gov"]["voting_params"]["voting_period"]="200s"' >"$TMP_GENESIS" "$GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["staking"]["params"]["unbonding_time"]="200s"' >"$TMP_GENESIS" "$GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	

	#changes status in app,config files
        sed -i 's/timeout_propose = "3s"/timeout_propose = "3s"/g' "$CONFIG"
        sed -i 's/timeout_commit = "5s"/timeout_commit = "2s"/g' "$CONFIG"
        sed -i 's/seeds = ""/seeds = ""/g' "$CONFIG"
        sed -i 's/prometheus = false/prometheus = true/' "$CONFIG"
        sed -i 's/prometheus-retention-time  = "0"/prometheus-retention-time  = "1000000000000"/g' "$APP_TOML"
        sed -i 's/enabled = false/enabled = true/g' "$APP_TOML"
        sed -i 's/enable = false/enable = true/g' "$APP_TOML"
        sed -i 's/swagger = false/swagger = true/g' "$APP_TOML"


	# Allocate genesis accounts (cosmos formatted addresses)
	./build/shidod add-genesis-account $KEYS 10000000000000000000000000000000000000000000000shido --keyring-backend $KEYRING --home "$HOMEDIR"

	# Sign genesis transaction
	./build/shidod gentx ${KEYS} 1000000000000000000000shido --keyring-backend $KEYRING --chain-id $CHAINID --home "$HOMEDIR"
	
	# Collect genesis tx
	./build/shidod collect-gentxs --home "$HOMEDIR"

	# Run this to ensure everything worked and that the genesis file is setup correctly
	./build/shidod validate-genesis --home "$HOMEDIR"

fi

# Start the node
./build/shidod start --home "$HOMEDIR"


