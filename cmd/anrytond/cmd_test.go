package main_test

import (
	"fmt"
	"testing"

	"github.com/anryton/anryton/v2/app"
	anrytond "github.com/anryton/anryton/v2/cmd/anrytond"
	"github.com/anryton/anryton/v2/utils"
	"github.com/cosmos/cosmos-sdk/client/flags"
	svrcmd "github.com/cosmos/cosmos-sdk/server/cmd"
	"github.com/cosmos/cosmos-sdk/x/genutil/client/cli"
	"github.com/stretchr/testify/require"
)

func TestInitCmd(t *testing.T) {
	rootCmd, _ := anrytond.NewRootCmd()
	rootCmd.SetArgs([]string{
		"init",         // Test the init cmd
		"anryton-test", // Moniker
		fmt.Sprintf("--%s=%s", cli.FlagOverwrite, "true"), // Overwrite genesis.json, in case it already exists
		fmt.Sprintf("--%s=%s", flags.FlagChainID, utils.TestnetChainID+"-1"),
	})

	err := svrcmd.Execute(rootCmd, "anrytond", app.DefaultNodeHome)
	require.NoError(t, err)
}

func TestAddKeyLedgerCmd(t *testing.T) {
	rootCmd, _ := anrytond.NewRootCmd()
	rootCmd.SetArgs([]string{
		"keys",
		"add",
		"dev0",
		fmt.Sprintf("--%s", flags.FlagUseLedger),
	})

	err := svrcmd.Execute(rootCmd, "ANRYTOND", app.DefaultNodeHome)
	require.Error(t, err)
}
