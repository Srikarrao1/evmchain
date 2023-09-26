import pytest
from web3 import Web3

from .network import setup_shido
from .utils import ADDRS, derive_new_account, w3_wait_for_new_blocks


@pytest.fixture(scope="module")
def custom_shido(tmp_path_factory):
    path = tmp_path_factory.mktemp("account")
    yield from setup_shido(path, 26700, long_timeout_commit=True)


@pytest.fixture(scope="module", params=["shido", "shido-ws", "geth"])
def cluster(request, custom_shido, geth):
    """
    run on shido, shido websocket and geth
    """
    provider = request.param
    if provider == "shido":
        yield custom_shido
    elif provider == "shido-ws":
        shido_ws = custom_shido.copy()
        shido_ws.use_websocket()
        yield shido_ws
    elif provider == "geth":
        yield geth
    else:
        raise NotImplementedError


def test_get_transaction_count(cluster):
    w3: Web3 = cluster.w3
    blk = hex(w3.eth.block_number)
    sender = ADDRS["validator"]

    receiver = derive_new_account().address
    n0 = w3.eth.get_transaction_count(receiver, blk)
    # ensure transaction send in new block
    w3_wait_for_new_blocks(w3, 1, sleep=0.1)
    txhash = w3.eth.send_transaction(
        {
            "from": sender,
            "to": receiver,
            "value": 1000,
        }
    )
    receipt = w3.eth.wait_for_transaction_receipt(txhash)
    assert receipt.status == 1
    [n1, n2] = [w3.eth.get_transaction_count(receiver, b) for b in [blk, "latest"]]
    assert n0 == n1
    assert n0 == n2


def test_query_future_blk(cluster):
    w3: Web3 = cluster.w3
    acc = derive_new_account(2).address
    current = w3.eth.block_number
    future = current + 1000
    with pytest.raises(ValueError) as exc:
        w3.eth.get_transaction_count(acc, hex(future))
    print(acc, str(exc))
    assert "-32000" in str(exc)
