import pytest

from .network import setup_shido, setup_geth


@pytest.fixture(scope="session")
def shido(tmp_path_factory):
    path = tmp_path_factory.mktemp("shido")
    yield from setup_shido(path, 26650)


@pytest.fixture(scope="session")
def geth(tmp_path_factory):
    path = tmp_path_factory.mktemp("geth")
    yield from setup_geth(path, 8545)


@pytest.fixture(scope="session", params=["shido", "shido-ws"])
def shido_rpc_ws(request, shido):
    """
    run on both shido and shido websocket
    """
    provider = request.param
    if provider == "shido":
        yield shido
    elif provider == "shido-ws":
        shido_ws = shido.copy()
        shido_ws.use_websocket()
        yield shido_ws
    else:
        raise NotImplementedError


@pytest.fixture(scope="module", params=["shido", "shido-ws", "geth"])
def cluster(request, shido, geth):
    """
    run on shido, shido websocket and geth
    """
    provider = request.param
    if provider == "shido":
        yield shido
    elif provider == "shido-ws":
        shido_ws = shido.copy()
        shido_ws.use_websocket()
        yield shido_ws
    elif provider == "geth":
        yield geth
    else:
        raise NotImplementedError
