package types

import (
	"math/big"

	sdkmath "cosmossdk.io/math"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

const (
	// AttoShido defines the default coin denomination used in Shido in:
	//
	// - Staking parameters: denomination used as stake in the dPoS chain
	// - Mint parameters: denomination minted due to fee distribution rewards
	// - Governance parameters: denomination used for spam prevention in proposal deposits
	// - Crisis parameters: constant fee denomination used for spam prevention to check broken invariant
	// - EVM parameters: denomination used for running EVM state transitions in Shido.
	AttoShido string = "ashido"

	// BaseDenomUnit defines the base denomination unit for Shido.
	// 1 shido = 1x10^{BaseDenomUnit} ashido
	BaseDenomUnit = 18

	// DefaultGasPrice is default gas price for evm transactions
	DefaultGasPrice = 20
)

// PowerReduction defines the default power reduction value for staking
var PowerReduction = sdkmath.NewIntFromBigInt(new(big.Int).Exp(big.NewInt(10), big.NewInt(BaseDenomUnit), nil))

// NewShidoCoin is a utility function that returns an "ashido" coin with the given sdkmath.Int amount.
// The function will panic if the provided amount is negative.
func NewShidoCoin(amount sdkmath.Int) sdk.Coin {
	return sdk.NewCoin(AttoShido, amount)
}

// NewShidoDecCoin is a utility function that returns an "ashido" decimal coin with the given sdkmath.Int amount.
// The function will panic if the provided amount is negative.
func NewShidoDecCoin(amount sdkmath.Int) sdk.DecCoin {
	return sdk.NewDecCoin(AttoShido, amount)
}

// NewShidoCoinInt64 is a utility function that returns an "ashido" coin with the given int64 amount.
// The function will panic if the provided amount is negative.
func NewShidoCoinInt64(amount int64) sdk.Coin {
	return sdk.NewInt64Coin(AttoShido, amount)
}
