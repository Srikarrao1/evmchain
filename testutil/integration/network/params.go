package network

import (
	evmtypes "github.com/anryton/anryton/v2/x/evm/types"
)

func (n *IntegrationNetwork) UpdateEvmParams(params evmtypes.Params) error {
	return n.app.EvmKeeper.SetParams(n.ctx, params)
}
