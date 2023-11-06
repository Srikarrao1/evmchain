package utils

import (
	"math/big"

	sdk "github.com/cosmos/cosmos-sdk/types"
	stakingtypes "github.com/cosmos/cosmos-sdk/x/staking/types"
    evmtypes "github.com/shido/shido/v2/x/evm/types"
	"github.com/ethereum/go-ethereum/params"
)

// BankKeeper defines the exposed interface for using functionality of the bank keeper
// in the context of the AnteHandler utils package.
type BankKeeper interface {
	GetBalance(ctx sdk.Context, addr sdk.AccAddress, denom string) sdk.Coin
}

// DistributionKeeper defines the exposed interface for using functionality of the distribution
// keeper in the context of the AnteHandler utils package.
type DistributionKeeper interface {
	WithdrawDelegationRewards(ctx sdk.Context, delAddr sdk.AccAddress, valAddr sdk.ValAddress) (sdk.Coins, error)
}

// StakingKeeper defines the exposed interface for using functionality of the staking keeper
// in the context of the AnteHandler utils package.
type StakingKeeper interface {
	BondDenom(ctx sdk.Context) string
	IterateDelegations(ctx sdk.Context, delegator sdk.AccAddress, fn func(index int64, delegation stakingtypes.DelegationI) (stop bool))
	GetValidator(ctx sdk.Context, valAddr sdk.ValAddress) (stakingtypes.Validator, bool)
	GetDelegatorDelegations(ctx sdk.Context, delegator sdk.AccAddress, maxRetrieve uint16) []stakingtypes.Delegation
	
}
type DynamicFeeEVMKeeper interface {
	ChainID() *big.Int
	GetParams(ctx sdk.Context) evmtypes.Params
	GetBaseFee(ctx sdk.Context, ethCfg *params.ChainConfig) *big.Int
}