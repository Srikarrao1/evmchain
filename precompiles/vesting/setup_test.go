package vesting_test

import (
	"testing"

	anrytonapp "github.com/anryton/anryton/v2/app"
	"github.com/anryton/anryton/v2/precompiles/vesting"
	"github.com/anryton/anryton/v2/x/evm/statedb"
	evmtypes "github.com/anryton/anryton/v2/x/evm/types"
	"github.com/cosmos/cosmos-sdk/crypto/keyring"
	cryptotypes "github.com/cosmos/cosmos-sdk/crypto/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	stakingtypes "github.com/cosmos/cosmos-sdk/x/staking/types"
	"github.com/ethereum/go-ethereum/common"
	ethtypes "github.com/ethereum/go-ethereum/core/types"
	"github.com/stretchr/testify/suite"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var s *PrecompileTestSuite

type PrecompileTestSuite struct {
	suite.Suite

	ctx        sdk.Context
	app        *anrytonapp.Anryton
	address    common.Address
	validators []stakingtypes.Validator
	ethSigner  ethtypes.Signer
	privKey    cryptotypes.PrivKey
	signer     keyring.Signer
	bondDenom  string

	precompile *vesting.Precompile
	stateDB    *statedb.StateDB

	queryClientEVM evmtypes.QueryClient
}

func TestPrecompileTestSuite(t *testing.T) {
	s = new(PrecompileTestSuite)
	suite.Run(t, s)

	// Run Ginkgo integration tests
	RegisterFailHandler(Fail)
	RunSpecs(t, "Precompile Test Suite")
}

func (s *PrecompileTestSuite) SetupTest() {
	s.DoSetupTest()
}
