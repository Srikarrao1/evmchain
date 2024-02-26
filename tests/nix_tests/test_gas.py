from .utils import (
    ADDRS,
    CONTRACTS,
    KEYS,
    deploy_contract,
    send_transaction,
    w3_wait_for_new_blocks,
)


def test_gas_eth_tx(geth, anryton):
    tx_value = 10

    # send a transaction with geth
    geth_gas_price = geth.w3.eth.gas_price
    tx = {"to": ADDRS["community"], "value": tx_value, "gasPrice": geth_gas_price}
    geth_receipt = send_transaction(geth.w3, tx, KEYS["validator"])

    # send an equivalent transaction with anryton
    anryton_gas_price = anryton.w3.eth.gas_price
    tx = {"to": ADDRS["community"], "value": tx_value, "gasPrice": anryton_gas_price}
    anryton_receipt = send_transaction(anryton.w3, tx, KEYS["validator"])

    # ensure that the gasUsed is equivalent
    assert geth_receipt.gasUsed == anryton_receipt.gasUsed


def test_gas_deployment(geth, anryton):
    # deploy an identical contract on geth and anryton
    # ensure that the gasUsed is equivalent
    _, geth_contract_receipt = deploy_contract(geth.w3, CONTRACTS["TestERC20A"])
    _, anryton_contract_receipt = deploy_contract(anryton.w3, CONTRACTS["TestERC20A"])
    assert geth_contract_receipt.gasUsed == anryton_contract_receipt.gasUsed


def test_gas_call(geth, anryton):
    function_input = 10

    # deploy an identical contract on geth and anryton
    # ensure that the contract has a function which consumes non-trivial gas
    geth_contract, _ = deploy_contract(geth.w3, CONTRACTS["BurnGas"])
    anryton_contract, _ = deploy_contract(anryton.w3, CONTRACTS["BurnGas"])

    # call the contract and get tx receipt for geth
    geth_gas_price = geth.w3.eth.gas_price
    geth_txhash = geth_contract.functions.burnGas(function_input).transact(
        {"from": ADDRS["validator"], "gasPrice": geth_gas_price}
    )
    geth_call_receipt = geth.w3.eth.wait_for_transaction_receipt(geth_txhash)

    # repeat the above for anryton
    anryton_gas_price = anryton.w3.eth.gas_price
    anryton_txhash = anryton_contract.functions.burnGas(function_input).transact(
        {"from": ADDRS["validator"], "gasPrice": anryton_gas_price}
    )
    anryton_call_receipt = anryton.w3.eth.wait_for_transaction_receipt(anryton_txhash)

    # ensure that the gasUsed is equivalent
    assert geth_call_receipt.gasUsed == anryton_call_receipt.gasUsed


def test_block_gas_limit(anryton):
    tx_value = 10

    # get the block gas limit from the latest block
    w3_wait_for_new_blocks(anryton.w3, 5)
    block = anryton.w3.eth.get_block("latest")
    exceeded_gas_limit = block.gasLimit + 100

    # send a transaction exceeding the block gas limit
    anryton_gas_price = anryton.w3.eth.gas_price
    tx = {
        "to": ADDRS["community"],
        "value": tx_value,
        "gas": exceeded_gas_limit,
        "gasPrice": anryton_gas_price,
    }

    # expect an error due to the block gas limit
    try:
        send_transaction(anryton.w3, tx, KEYS["validator"])
    except Exception as error:
        assert "exceeds block gas limit" in error.args[0]["message"]

    # deploy a contract on anryton
    anryton_contract, _ = deploy_contract(anryton.w3, CONTRACTS["BurnGas"])

    # expect an error on contract call due to block gas limit
    try:
        anryton_txhash = anryton_contract.functions.burnGas(exceeded_gas_limit).transact(
            {
                "from": ADDRS["validator"],
                "gas": exceeded_gas_limit,
                "gasPrice": anryton_gas_price,
            }
        )
        (anryton.w3.eth.wait_for_transaction_receipt(anryton_txhash))
    except Exception as error:
        assert "exceeds block gas limit" in error.args[0]["message"]

    return
