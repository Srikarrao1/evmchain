#!/bin/bash

current_path=$(pwd)
bash  $current_path/install-go.sh 
bash install-go.sh
source ~/.bashrc
ulimit -n 16384

# Get OS and version
OS=$(awk -F '=' '/^NAME/{print $2}' /etc/os-release | awk '{print $1}' | tr -d '"')
VERSION=$(awk -F '=' '/^VERSION_ID/{print $2}' /etc/os-release | awk '{print $1}' | tr -d '"')

# Define the binary and installation paths
BINARY="anrytond"
INSTALL_PATH="/usr/local/bin/"

# Check if the OS is Ubuntu and the version is either 20.04 or 22.04
if [ "$OS" == "Ubuntu" ] && [ "$VERSION" == "20.04" -o "$VERSION" == "22.04" ]; then
  # Copy and set executable permissions
  current_path=$(pwd)
  
  # Update package lists and install necessary packages
  sudo  apt-get update
  sudo apt-get install -y build-essential jq wget unzip
  
  # Check if the installation path exists
  if [ -d "$INSTALL_PATH" ]; then
  sudo  cp "$current_path/ubuntu${VERSION}build/$BINARY" "$INSTALL_PATH" && sudo chmod +x "${INSTALL_PATH}${BINARY}"
    echo "$BINARY installed or updated successfully!"
  else
    echo "Installation path $INSTALL_PATH does not exist. Please create it."
    exit 1
  fi
else
  echo "Please check the OS version support; at this time, only Ubuntu 20.04 and 22.04 are supported."
  exit 1
fi
# wget https://testnet-blockchain-anryton.s3.us-west-2.amazonaws.com/anryton_snapshot_12122023.zip
#==========================================================================================================================================
KEYS="alice"
KEYS2="bob"
CHAINID="anryton_9007-1"
MONIKER="anrytonnode"
MONIKER2="anrytonnode2"
KEYRING="test"
KEYALGO="eth_secp256k1"
LOGLEVEL="info"

# Set dedicated home directory for the anrytond instance
HOMEDIR="$HOME/.tmp-anrytond"
HOMEDIR2="$HOME/.tmp-anrytond2"

# Path variables
CONFIG=$HOMEDIR/config/config.toml
APP_TOML=$HOMEDIR/config/app.toml
CLIENT=$HOMEDIR/config/client.toml
GENESIS=$HOMEDIR/config/genesis.json
TMP_GENESIS=$HOMEDIR/config/tmp_genesis.json

CONFIG2=$HOMEDIR2/config/config.toml
APP_TOML2=$HOMEDIR2/config/app.toml
CLIENT2=$HOMEDIR2/config/client.toml


# validate dependencies are installed
command -v jq >/dev/null 2>&1 || {
	echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"
	exit 1
}

# used to exit on first error
set -e

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
    sudo systemctl stop anryton1.service
	sudo rm -rf "$HOMEDIR"
   

	# Set client config
	anrytond config keyring-backend $KEYRING --home "$HOMEDIR"
	anrytond config chain-id $CHAINID --home "$HOMEDIR"
	anrytond keys add $KEYS --keyring-backend $KEYRING --algo $KEYALGO --home "$HOMEDIR"
	anrytond init $MONIKER -o --chain-id $CHAINID --home "$HOMEDIR"


    # Change parameter token denominations to anryton
	jq '.app_state["staking"]["params"]["bond_denom"]="anryton"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["crisis"]["constant_fee"]["denom"]="anryton"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="anryton"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["evm"]["params"]["evm_denom"]="anryton"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    jq '.app_state["mint"]["params"]["mint_denom"]="anryton"' >"$TMP_GENESIS" "$GENESIS" && mv "$TMP_GENESIS" "$GENESIS"


    # jq '.app_state["feemarket"]["params"]["no_base_fee"]=true' >"$TMP_GENESIS" "$GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    # jq '.app_state["feemarket"]["params"]["base_fee"]="0"' >"$TMP_GENESIS" "$GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    # jq '.app_state["feemarket"]["params"]["min_gas_price"]="0"' >"$TMP_GENESIS" "$GENESIS" && mv "$TMP_GENESIS" "$GENESIS"


	# Set gas limit in genesis
	jq '.consensus_params["block"]["max_gas"]="10000000"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["gov"]["deposit_params"]["max_deposit_period"]="200s"' >"$TMP_GENESIS" "$GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["gov"]["voting_params"]["voting_period"]="200s"' >"$TMP_GENESIS" "$GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["staking"]["params"]["unbonding_time"]="200s"' >"$TMP_GENESIS" "$GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	

	#changes status in app,config files
    sed -i 's/timeout_commit = "3s"/timeout_commit = "1s"/g' "$CONFIG"
    sed -i 's/seeds = ""/seeds = ""/g' "$CONFIG"
    sed -i 's/prometheus = false/prometheus = true/' "$CONFIG"
    sed -i 's/prometheus-retention-time  = "0"/prometheus-retention-time  = "1000000000000"/g' "$APP_TOML"
    sed -i 's/enabled = false/enabled = true/g' "$APP_TOML"
    sed -i 's/enable = false/enable = true/g' "$APP_TOML"
    sed -i 's/swagger = false/swagger = true/g' "$APP_TOML"
	sed -i 's/localhost/0.0.0.0/g' "$APP_TOML"
    sed -i 's/localhost/0.0.0.0/g' "$CONFIG"
    sed -i 's/localhost/0.0.0.0/g' "$CLIENT"
    sed -i 's/127.0.0.1/0.0.0.0/g' "$APP_TOML"
    sed -i 's/127.0.0.1/0.0.0.0/g' "$CONFIG"
    sed -i 's/127.0.0.1/0.0.0.0/g' "$CLIENT"


	# Allocate genesis accounts (cosmos formatted addresses)
	anrytond add-genesis-account $KEYS 100000000000000000000000000000anryton --keyring-backend $KEYRING --home "$HOMEDIR"

	# Sign genesis transaction
	anrytond gentx ${KEYS} 10000000000000000000000anryton --keyring-backend $KEYRING --chain-id $CHAINID --home "$HOMEDIR"
	
	# Collect genesis tx
	anrytond collect-gentxs --home "$HOMEDIR"

	# Run this to ensure everything worked and that the genesis file is setup correctly
	anrytond validate-genesis --home "$HOMEDIR"

	ADDRESS=$(anrytond keys list --home $HOMEDIR --keyring-backend $KEYRING | grep "address" | cut -c12-)
	WALLETADDRESS=$(anrytond debug addr $ADDRESS --home $HOMEDIR --keyring-backend $KEYRING | grep "Address (EIP-55)" | cut -c12-)
	TENDERMINTPUBKEY=$(anrytond tendermint show-validator --home $HOMEDIR | grep "key" | cut -c12-)
	BECH32ADDRESS=$(anrytond keys show ${KEYS} --home $HOMEDIR | grep "address" | cut -c12-)
	NODID=$(anrytond tendermint show-node-id --home $HOMEDIR)
	echo "========================================================================================================================"
	echo "anryton Eth Hex Address==== "$WALLETADDRESS
	echo "tendermint Key==== "$TENDERMINTPUBKEY
	echo "BECH32Address==== "$BECH32ADDRESS
	echo "========================================================================================================================"

# ========================================= Node 2=========================================================================================
    sudo systemctl stop anryton1.service
    sudo rm -rf "$HOMEDIR2"

	# Set client config
	anrytond config keyring-backend $KEYRING --home "$HOMEDIR2"
	anrytond config chain-id $CHAINID --home "$HOMEDIR2"
	anrytond keys add $KEYS2 --keyring-backend $KEYRING --algo $KEYALGO --home "$HOMEDIR2"
	anrytond init $MONIKER2 -o --chain-id $CHAINID --home "$HOMEDIR2"


	#changes status in app,config files
    sed -i 's/timeout_commit = "3s"/timeout_commit = "1s"/g' "$CONFIG2"
    sed -i 's/seeds = ""/seeds = ""/g' "$CONFIG2"
    sed -i 's/prometheus = false/prometheus = true/' "$CONFIG2"
    sed -i 's/prometheus-retention-time  = "0"/prometheus-retention-time  = "1000000000000"/g' "$APP_TOML2"
    sed -i 's/enabled = false/enabled = true/g' "$APP_TOML2"
    sed -i 's/enable = false/enable = true/g' "$APP_TOML2"
    sed -i 's/swagger = false/swagger = true/g' "$APP_TOML2"
	sed -i 's/localhost/0.0.0.0/g' "$APP_TOML2"
    sed -i 's/localhost/0.0.0.0/g' "$CONFIG2"
    sed -i 's/localhost/0.0.0.0/g' "$CLIENT2"
    sed -i 's/127.0.0.1/0.0.0.0/g' "$APP_TOML2"
    sed -i 's/127.0.0.1/0.0.0.0/g' "$CONFIG2"
    sed -i 's/127.0.0.1/0.0.0.0/g' "$CLIENT2"



    sed -i 's/1317/1318/g' "$APP_TOML2"
    sed -i 's/9090/9092/g' "$APP_TOML2"
    sed -i 's/9091/9093/g' "$APP_TOML2"
    sed -i 's/8545/8547/g' "$APP_TOML2"
    sed -i 's/8546/8548/g' "$APP_TOML2"
    sed -i 's/26658/26661/g' "$CONFIG2"
    sed -i 's/26657/26659/g' "$CLIENT2"
    sed -i 's/26657/26659/g' "$CONFIG2"
    sed -i 's/26656/26655/g' "$CONFIG2"
    sed -i 's/6060/6061/g' "$CONFIG2"


	# Allocate genesis accounts (cosmos formatted addresses)
	anrytond add-genesis-account $KEYS2 100000000000000000000000000000anryton --keyring-backend $KEYRING --home "$HOMEDIR2"

	# Sign genesis transaction
	anrytond gentx ${KEYS2} 10000000000000000000000anryton --keyring-backend $KEYRING --chain-id $CHAINID --home "$HOMEDIR2"
	
	# Collect genesis tx
	anrytond collect-gentxs --home "$HOMEDIR2"

	# these are some of the node ids help to sync the node with p2p connections
	sed -i 's/persistent_peers \s*=\s* ""/persistent_peers = "'${NODID}'@localhost:26656"/g' "$CONFIG2"

	# remove the genesis file from binary
	rm -rf $HOMEDIR2/config/genesis.json

	# paste the genesis file
	cp $HOMEDIR/config/genesis.json $HOMEDIR2/config

	# Run this to ensure everything worked and that the genesis file is setup correctly
	anrytond validate-genesis --home "$HOMEDIR2"

	ADDRESS2=$(anrytond keys list --home $HOMEDIR2 --keyring-backend $KEYRING | grep "address" | cut -c12-)
	WALLETADDRESS2=$(anrytond debug addr $ADDRESS2 --home $HOMEDIR2 --keyring-backend $KEYRING | grep "Address (EIP-55)" | cut -c12-)
	TENDERMINTPUBKEY2=$(anrytond tendermint show-validator --home $HOMEDIR2 | grep "key" | cut -c12-)
	BECH32ADDRESS2=$(anrytond keys show ${KEYS2} --home $HOMEDIR2 | grep "address" | cut -c12-)
	NODID2=$(anrytond tendermint show-node-id --home $HOMEDIR2)
	echo "========================================================================================================================"
	echo "anryton Eth Hex Address==== "$WALLETADDRESS2
	echo "tendermint Key==== "$TENDERMINTPUBKEY2
	echo "BECH32Address==== "$BECH32ADDRESS2
	echo "========================================================================================================================"

fi
# echo "BECH32Address==== "$BECH32ADDRESS
# echo "NODEID==== "$NODID

echo "BECH32Address==== "$BECH32ADDRESS2
# # echo "BECH32Address==== "$NODID2
#========================================================================================================================================================
# Start the node
# anrytond start --home "$HOMEDIR"


sudo su -c  "echo '[Unit]
Description=anrytond Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/anrytond start --home $HOMEDIR
Restart=always

Environment=HOME=$HOMEDIR

[Install]
WantedBy=multi-user.target'> /etc/systemd/system/anryton1.service"


sudo systemctl daemon-reload
sudo systemctl enable anryton1.service
sudo systemctl start anryton1.service

# ============= node 2 script ===============================================================
sudo su -c  "echo '[Unit]
Description=anrytondnode2 Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/anrytond start --home $HOMEDIR2
Restart=always

Environment=HOME=$HOMEDIR2

[Install]
WantedBy=multi-user.target'> /etc/systemd/system/anryton2.service"


sudo systemctl daemon-reload
sudo systemctl enable anryton2.service
sudo systemctl start anryton2.service



# ================================================= balance Transfer ==============================================================

sendMoney="anrytond tx bank send ${BECH32ADDRESS} ${BECH32ADDRESS2} 210000000000000000000000anryton --keyring-backend $KEYRING --chain-id $CHAINID --home \"$HOMEDIR\" -y
"
queryBalance="anrytond query bank balances $BECH32ADDRESS2 --keyring-backend $KEYRING --chain-id $CHAINID --home \"$HOMEDIR2\""

keycommand="anrytond debug addr  $BECH32ADDRESS2 --keyring-backend $KEYRING --chain-id $CHAINID --home \"$HOMEDIR2\""

# Set the timeout in seconds
timeout_duration=50  # 5 seconds, change as needed
timeout_duration2=5  # 5 seconds, change as needed
sleep $timeout_duration
# Execute your command
eval "$sendMoney"
sleep $timeout_duration2
eval "$queryBalance"
echo "==============================================================================================================================================="
eval "$keycommand"
echo "tendermint Key==== "$TENDERMINTPUBKEY2
echo "BECH32Address==== "$BECH32ADDRESS2










