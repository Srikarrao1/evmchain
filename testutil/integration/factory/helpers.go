package factory

import (
	evmtypes "github.com/anryton/anryton/v2/x/evm/types"
	"github.com/ethereum/go-ethereum/common"

	errorsmod "cosmossdk.io/errors"
	enccodec "github.com/anryton/anryton/v2/encoding/codec"
	"github.com/anryton/anryton/v2/testutil/tx"
	anrytontypes "github.com/anryton/anryton/v2/types"
	amino "github.com/cosmos/cosmos-sdk/codec"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	cryptotypes "github.com/cosmos/cosmos-sdk/crypto/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	testutiltypes "github.com/cosmos/cosmos-sdk/types/module/testutil"
	authtx "github.com/cosmos/cosmos-sdk/x/auth/tx"
	ethtypes "github.com/ethereum/go-ethereum/core/types"
)

// buildMsgEthereumTx builds an Ethereum transaction from the given arguments and populates the From field.
func buildMsgEthereumTx(txArgs evmtypes.EvmTxArgs, fromAddr common.Address) (evmtypes.MsgEthereumTx, error) {
	msgEthereumTx := evmtypes.NewTx(&txArgs)
	msgEthereumTx.From = fromAddr.String()

	// Validate the transaction to avoid unrealistic behavior
	err := msgEthereumTx.ValidateBasic()
	if err != nil {
		return evmtypes.MsgEthereumTx{}, errorsmod.Wrap(err, "failed to validate transaction")
	}
	return *msgEthereumTx, nil
}

// signMsgEthereumTx signs a MsgEthereumTx with the provided private key and chainID.
func signMsgEthereumTx(msgEthereumTx evmtypes.MsgEthereumTx, privKey cryptotypes.PrivKey, chainID string) (evmtypes.MsgEthereumTx, error) {
	ethChainID, err := anrytontypes.ParseChainID(chainID)
	if err != nil {
		return evmtypes.MsgEthereumTx{}, errorsmod.Wrapf(err, "failed to parse chainID: %v", chainID)
	}

	signer := ethtypes.LatestSignerForChainID(ethChainID)
	err = msgEthereumTx.Sign(signer, tx.NewSigner(privKey))
	if err != nil {
		return evmtypes.MsgEthereumTx{}, errorsmod.Wrap(err, "failed to sign transaction")
	}
	return msgEthereumTx, nil
}

// makeConfig creates an EncodingConfig for testing
func makeConfig(mb module.BasicManager) testutiltypes.TestEncodingConfig {
	cdc := amino.NewLegacyAmino()
	interfaceRegistry := codectypes.NewInterfaceRegistry()
	codec := amino.NewProtoCodec(interfaceRegistry)

	encodingConfig := testutiltypes.TestEncodingConfig{
		InterfaceRegistry: interfaceRegistry,
		Codec:             codec,
		TxConfig:          authtx.NewTxConfig(codec, authtx.DefaultSignModes),
		Amino:             cdc,
	}

	enccodec.RegisterLegacyAminoCodec(encodingConfig.Amino)
	mb.RegisterLegacyAminoCodec(encodingConfig.Amino)
	enccodec.RegisterInterfaces(encodingConfig.InterfaceRegistry)
	mb.RegisterInterfaces(encodingConfig.InterfaceRegistry)
	return encodingConfig
}
