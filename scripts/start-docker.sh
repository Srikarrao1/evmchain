#!/bin/bash

KEY="dev0"
CHAINID="anryton_9000-1"
MONIKER="mymoniker"
DATA_DIR=$(mktemp -d -t anryton-datadir.XXXXX)

echo "create and add new keys"
./anrytond keys add $KEY --home $DATA_DIR --no-backup --chain-id $CHAINID --algo "eth_secp256k1" --keyring-backend test
echo "init Anryton with moniker=$MONIKER and chain-id=$CHAINID"
./anrytond init $MONIKER --chain-id $CHAINID --home $DATA_DIR
echo "prepare genesis: Allocate genesis accounts"
./anrytond add-genesis-account \
"$(./anrytond keys show $KEY -a --home $DATA_DIR --keyring-backend test)" 1000000000000000000anryton,1000000000000000000stake \
--home $DATA_DIR --keyring-backend test
echo "prepare genesis: Sign genesis transaction"
./anrytond gentx $KEY 1000000000000000000stake --keyring-backend test --home $DATA_DIR --keyring-backend test --chain-id $CHAINID
echo "prepare genesis: Collect genesis tx"
./anrytond collect-gentxs --home $DATA_DIR
echo "prepare genesis: Run validate-genesis to ensure everything worked and that the genesis file is setup correctly"
./anrytond validate-genesis --home $DATA_DIR

echo "starting anryton node $i in background ..."
./anrytond start --pruning=nothing --rpc.unsafe \
--keyring-backend test --home $DATA_DIR \
>$DATA_DIR/node.log 2>&1 & disown

echo "started anryton node"
tail -f /dev/null