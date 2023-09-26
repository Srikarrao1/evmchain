package network

import (
	evmtypes "github.com/shido/shido/v2/x/evm/types"
	infltypes "github.com/shido/shido/v2/x/inflation/types"
	revtypes "github.com/shido/shido/v2/x/revenue/v1/types"
)

func (n *IntegrationNetwork) UpdateEvmParams(params evmtypes.Params) error {
	return n.app.EvmKeeper.SetParams(n.ctx, params)
}

func (n *IntegrationNetwork) UpdateRevenueParams(params revtypes.Params) error {
	return n.app.RevenueKeeper.SetParams(n.ctx, params)
}

func (n *IntegrationNetwork) UpdateInflationParams(params infltypes.Params) error {
	return n.app.InflationKeeper.SetParams(n.ctx, params)
}
