package keeper_test

import (
	"errors"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"

	"github.com/cosmos/cosmos-sdk/crypto/keys/secp256k1"
	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/shido/shido/v2/testutil"

	transfertypes "github.com/cosmos/ibc-go/v7/modules/apps/transfer/types"
	channeltypes "github.com/cosmos/ibc-go/v7/modules/core/04-channel/types"

	"github.com/shido/shido/v2/contracts"
	"github.com/shido/shido/v2/x/erc20/types"
)

var erc20Denom = "erc20/0xdac17f958d2ee523a2206206994597c13d831ec7"

func (suite *KeeperTestSuite) TestConvertCoinToERC20FromPacket() {
	senderAddr := "shido1x2w87cvt5mqjncav4lxy8yfreynn273xn5335v"

	testCases := []struct {
		name     string
		malleate func() transfertypes.FungibleTokenPacketData
		transfer transfertypes.FungibleTokenPacketData
		expPass  bool
	}{
		{
			name: "error - invalid sender",
			malleate: func() transfertypes.FungibleTokenPacketData {
				return transfertypes.NewFungibleTokenPacketData("ashido", "10", "", "", "")
			},
			expPass: false,
		},
		{
			name: "pass - is base denom",
			malleate: func() transfertypes.FungibleTokenPacketData {
				return transfertypes.NewFungibleTokenPacketData("ashido", "10", senderAddr, "", "")
			},
			expPass: true,
		},
		{
			name: "pass - erc20 is disabled",
			malleate: func() transfertypes.FungibleTokenPacketData {
				pair := suite.setupRegisterCoin(metadataIbc)
				suite.Require().NotNil(pair)

				params := suite.app.Erc20Keeper.GetParams(suite.ctx)
				params.EnableErc20 = false
				_ = suite.app.Erc20Keeper.SetParams(suite.ctx, params)
				return transfertypes.NewFungibleTokenPacketData(pair.Denom, "10", senderAddr, "", "")
			},
			expPass: true,
		},
		{
			name: "pass - denom is not registered",
			malleate: func() transfertypes.FungibleTokenPacketData {
				return transfertypes.NewFungibleTokenPacketData(metadataIbc.Base, "10", senderAddr, "", "")
			},
			expPass: true,
		},
		{
			name: "pass - denom is registered and has available balance",
			malleate: func() transfertypes.FungibleTokenPacketData {
				pair := suite.setupRegisterCoin(metadataIbc)
				suite.Require().NotNil(pair)

				sender := sdk.MustAccAddressFromBech32(senderAddr)

				// Mint coins on account to simulate receiving ibc transfer
				coinShido := sdk.NewCoin(pair.Denom, sdk.NewInt(10))
				coins := sdk.NewCoins(coinShido)
				err := suite.app.BankKeeper.MintCoins(suite.ctx, "", coins)
				suite.Require().NoError(err)
				err = suite.app.BankKeeper.SendCoinsFromModuleToAccount(suite.ctx, "", sender, coins)
				suite.Require().NoError(err)

				return transfertypes.NewFungibleTokenPacketData(pair.Denom, "10", senderAddr, "", "")
			},
			expPass: true,
		},
		{
			name: "error - denom is registered but has no available balance",
			malleate: func() transfertypes.FungibleTokenPacketData {
				pair := suite.setupRegisterCoin(metadataIbc)
				suite.Require().NotNil(pair)

				return transfertypes.NewFungibleTokenPacketData(pair.Denom, "10", senderAddr, "", "")
			},
			expPass: false,
		},
	}
	for _, tc := range testCases {
		suite.Run(fmt.Sprintf("Case %s", tc.name), func() {
			suite.mintFeeCollector = true
			suite.SetupTest() // reset

			transfer := tc.malleate()

			err := suite.app.Erc20Keeper.ConvertCoinToERC20FromPacket(suite.ctx, transfer)
			if tc.expPass {
				suite.Require().NoError(err)
			} else {
				suite.Require().Error(err)
			}
		})
	}
}

func (suite *KeeperTestSuite) TestOnAcknowledgementPacket() {
	var (
		data transfertypes.FungibleTokenPacketData
		ack  channeltypes.Acknowledgement
		pair *types.TokenPair
	)

	// secp256k1 account
	senderPk := secp256k1.GenPrivKey()
	sender := sdk.AccAddress(senderPk.PubKey().Address())

	receiverPk := secp256k1.GenPrivKey()
	receiver := sdk.AccAddress(receiverPk.PubKey().Address())
	fmt.Println(receiver)
	testCases := []struct {
		name     string
		malleate func()
		expERC20 *big.Int
		expPass  bool
	}{
		{
			name: "no-op - ack error sender is module account",
			malleate: func() {
				// Register Token Pair for testing
				pair = suite.setupRegisterCoin(metadataCoin)
				suite.Require().NotNil(pair)

				// for testing purposes we can only fund is not allowed to receive funds
				moduleAcc := suite.app.AccountKeeper.GetModuleAccount(suite.ctx, "erc20")
				sender = moduleAcc.GetAddress()
				err := testutil.FundModuleAccount(
					suite.ctx,
					suite.app.BankKeeper,
					moduleAcc.GetName(),
					sdk.NewCoins(
						sdk.NewCoin(pair.Denom, sdk.NewInt(100)),
					),
				)
				suite.Require().NoError(err)

				ack = channeltypes.NewErrorAcknowledgement(errors.New(""))
				data = transfertypes.NewFungibleTokenPacketData("", "", sender.String(), "", "")
			},
			expPass:  true,
			expERC20: big.NewInt(0),
		},
		{
			name: "conversion - convert ibc tokens to erc20 on ack error",
			malleate: func() {
				// Register Token Pair for testing
				pair = suite.setupRegisterCoin(metadataCoin)
				suite.Require().NotNil(pair)

				sender = sdk.AccAddress(senderPk.PubKey().Address())

				// Fund receiver account with SHIDO, ERC20 coins and IBC vouchers
				// We do this since we are interested in the conversion portion w/ OnRecvPacket
				err := testutil.FundAccount(
					suite.ctx,
					suite.app.BankKeeper,
					sender,
					sdk.NewCoins(
						sdk.NewCoin(pair.Denom, sdk.NewInt(100)),
					),
				)
				suite.Require().NoError(err)

				ack = channeltypes.NewErrorAcknowledgement(errors.New(""))
				data = transfertypes.NewFungibleTokenPacketData(pair.Denom, "100", sender.String(), receiver.String(), "")
			},
			expERC20: big.NewInt(100),
			expPass:  true,
		},
		{
			name: "no-op - positive ack",
			malleate: func() {
				// Register Token Pair for testing
				pair = suite.setupRegisterCoin(metadataCoin)
				suite.Require().NotNil(pair)

				sender = sdk.AccAddress(senderPk.PubKey().Address())

				// Fund receiver account with SHIDO, ERC20 coins and IBC vouchers
				// We do this since we are interested in the conversion portion w/ OnRecvPacket
				err := testutil.FundAccount(
					suite.ctx,
					suite.app.BankKeeper,
					sender,
					sdk.NewCoins(
						sdk.NewCoin(pair.Denom, sdk.NewInt(100)),
					),
				)
				suite.Require().NoError(err)

				ack = channeltypes.NewResultAcknowledgement([]byte{1})
			},
			expERC20: big.NewInt(0),
			expPass:  true,
		},
	}
	for _, tc := range testCases {
		suite.Run(fmt.Sprintf("Case %s", tc.name), func() {
			suite.SetupTest() // reset

			tc.malleate()

			err := suite.app.Erc20Keeper.OnAcknowledgementPacket(
				suite.ctx, channeltypes.Packet{}, data, ack,
			)
			suite.Require().NoError(err)

			if tc.expPass {
				suite.Require().NoError(err)
			} else {
				suite.Require().Error(err)
			}

			// check balance is the same as expected
			balance := suite.app.Erc20Keeper.BalanceOf(
				suite.ctx, contracts.ERC20MinterBurnerDecimalsContract.ABI,
				pair.GetERC20Contract(),
				common.BytesToAddress(sender.Bytes()),
			)
			suite.Require().Equal(tc.expERC20.Int64(), balance.Int64())
		})
	}
}

func (suite *KeeperTestSuite) TestOnTimeoutPacket() {
	senderAddr := "shido1x2w87cvt5mqjncav4lxy8yfreynn273xn5335v"

	testCases := []struct {
		name     string
		malleate func() transfertypes.FungibleTokenPacketData
		transfer transfertypes.FungibleTokenPacketData
		expPass  bool
	}{
		{
			name: "no-op - sender is module account",
			malleate: func() transfertypes.FungibleTokenPacketData {
				// any module account can be passed here
				moduleAcc := suite.app.AccountKeeper.GetModuleAccount(suite.ctx, "claims")

				return transfertypes.NewFungibleTokenPacketData("", "10", moduleAcc.GetAddress().String(), "", "")
			},
			expPass: true,
		},
		{
			name: "pass - convert coin to erc20",
			malleate: func() transfertypes.FungibleTokenPacketData {
				pair := suite.setupRegisterCoin(metadataIbc)
				suite.Require().NotNil(pair)

				sender := sdk.MustAccAddressFromBech32(senderAddr)

				// Mint coins on account to simulate receiving ibc transfer
				coinShido := sdk.NewCoin(pair.Denom, sdk.NewInt(10))
				coins := sdk.NewCoins(coinShido)
				err := suite.app.BankKeeper.MintCoins(suite.ctx, "", coins)
				suite.Require().NoError(err)
				err = suite.app.BankKeeper.SendCoinsFromModuleToAccount(suite.ctx, "", sender, coins)
				suite.Require().NoError(err)

				return transfertypes.NewFungibleTokenPacketData(pair.Denom, "10", senderAddr, "", "")
			},
			expPass: true,
		},
	}
	for _, tc := range testCases {
		suite.Run(fmt.Sprintf("Case %s", tc.name), func() {
			suite.SetupTest()

			data := tc.malleate()

			err := suite.app.Erc20Keeper.OnTimeoutPacket(suite.ctx, channeltypes.Packet{}, data)
			if tc.expPass {
				suite.Require().NoError(err)
			} else {
				suite.Require().Error(err)
			}
		})
	}
}
