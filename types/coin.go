package types

import (
	"math/big"

	sdkmath "cosmossdk.io/math"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

const (
	// AttoAnryton defines the default coin denomination used in Anryton in:
	//
	// - Staking parameters: denomination used as stake in the dPoS chain
	// - Mint parameters: denomination minted due to fee distribution rewards
	// - Governance parameters: denomination used for spam prevention in proposal deposits
	// - Crisis parameters: constant fee denomination used for spam prevention to check broken invariant
	// - EVM parameters: denomination used for running EVM state transitions in Anryton.
	AttoAnryton string = "anryton"

	// BaseDenomUnit defines the base denomination unit for Anryton.
	// 1 anryton = 1x10^{BaseDenomUnit} anryton
	BaseDenomUnit = 18

	// DefaultGasPrice is default gas price for evm transactions
	DefaultGasPrice = 20
)

// PowerReduction defines the default power reduction value for staking
var PowerReduction = sdkmath.NewIntFromBigInt(new(big.Int).Exp(big.NewInt(10), big.NewInt(BaseDenomUnit), nil))

// NewAnrytonCoin is a utility function that returns an "anryton" coin with the given sdkmath.Int amount.
// The function will panic if the provided amount is negative.
func NewAnrytonCoin(amount sdkmath.Int) sdk.Coin {
	return sdk.NewCoin(AttoAnryton, amount)
}

// NewAnrytonDecCoin is a utility function that returns an "anryton" decimal coin with the given sdkmath.Int amount.
// The function will panic if the provided amount is negative.
func NewAnrytonDecCoin(amount sdkmath.Int) sdk.DecCoin {
	return sdk.NewDecCoin(AttoAnryton, amount)
}

// NewAnrytonCoinInt64 is a utility function that returns an "anryton" coin with the given int64 amount.
// The function will panic if the provided amount is negative.
func NewAnrytonCoinInt64(amount int64) sdk.Coin {
	return sdk.NewInt64Coin(AttoAnryton, amount)
}
