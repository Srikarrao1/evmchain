import pytest

from .network import setup_anryton, setup_geth


@pytest.fixture(scope="session")
def anryton(tmp_path_factory):
    path = tmp_path_factory.mktemp("anryton")
    yield from setup_anryton(path, 26650)


@pytest.fixture(scope="session")
def geth(tmp_path_factory):
    path = tmp_path_factory.mktemp("geth")
    yield from setup_geth(path, 8545)


@pytest.fixture(scope="session", params=["anryton", "anryton-ws"])
def anryton_rpc_ws(request, anryton):
    """
    run on both anryton and anryton websocket
    """
    provider = request.param
    if provider == "anryton":
        yield anryton
    elif provider == "anryton-ws":
        anryton_ws = anryton.copy()
        anryton_ws.use_websocket()
        yield anryton_ws
    else:
        raise NotImplementedError


@pytest.fixture(scope="module", params=["anryton", "anryton-ws", "geth"])
def cluster(request, anryton, geth):
    """
    run on anryton, anryton websocket and geth
    """
    provider = request.param
    if provider == "anryton":
        yield anryton
    elif provider == "anryton-ws":
        anryton_ws = anryton.copy()
        anryton_ws.use_websocket()
        yield anryton_ws
    elif provider == "geth":
        yield geth
    else:
        raise NotImplementedError
