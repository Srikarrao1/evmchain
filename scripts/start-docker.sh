#!/bin/bash

KEY="dev0"
CHAINID="shido_9000-1"
MONIKER="mymoniker"
DATA_DIR=$(mktemp -d -t shido-datadir.XXXXX)

echo "create and add new keys"
./shidod keys add $KEY --home $DATA_DIR --no-backup --chain-id $CHAINID --algo "eth_secp256k1" --keyring-backend test
echo "init Shido with moniker=$MONIKER and chain-id=$CHAINID"
./shidod init $MONIKER --chain-id $CHAINID --home $DATA_DIR
echo "prepare genesis: Allocate genesis accounts"
./shidod add-genesis-account \
"$(./shidod keys show $KEY -a --home $DATA_DIR --keyring-backend test)" 1000000000000000000ashido,1000000000000000000stake \
--home $DATA_DIR --keyring-backend test
echo "prepare genesis: Sign genesis transaction"
./shidod gentx $KEY 1000000000000000000stake --keyring-backend test --home $DATA_DIR --keyring-backend test --chain-id $CHAINID
echo "prepare genesis: Collect genesis tx"
./shidod collect-gentxs --home $DATA_DIR
echo "prepare genesis: Run validate-genesis to ensure everything worked and that the genesis file is setup correctly"
./shidod validate-genesis --home $DATA_DIR

echo "starting shido node $i in background ..."
./shidod start --pruning=nothing --rpc.unsafe \
--keyring-backend test --home $DATA_DIR \
>$DATA_DIR/node.log 2>&1 & disown

echo "started shido node"
tail -f /dev/null