package cmd

import (
	"fmt"
	"os"

	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/config"
	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/utils"
	"github.com/spf13/cobra"
)

type rootOptions struct {
	Verbose     bool
	Output      string
	ConfigFile  string
	ProjectFile string
	NoColor     bool
}

var (
	version  = "dev"
	rootOpts rootOptions
	manager  *config.Manager
	rootCmd  = &cobra.Command{
		Use:           "parallax",
		Short:         "Production CLI for PARALLAX operations",
		Long:          "parallax manages project initialization, builds, deployments, tests, monitoring, and canister queries.",
		SilenceUsage:  true,
		SilenceErrors: true,
		PersistentPreRunE: func(cmd *cobra.Command, _ []string) error {
			utils.SetVerbose(rootOpts.Verbose)
			utils.SetJSONOutput(rootOpts.Output == "json")
			utils.SetNoColor(rootOpts.NoColor)
			if rootOpts.Output != "text" && rootOpts.Output != "json" {
				return fmt.Errorf("unsupported output format %q", rootOpts.Output)
			}
			loaded, err := config.Load(rootOpts.ConfigFile, rootOpts.ProjectFile)
			if err != nil {
				return err
			}
			manager = loaded
			return nil
		},
		RunE: func(cmd *cobra.Command, _ []string) error {
			return cmd.Help()
		},
	}
)

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		utils.PrintCommandError(err)
		os.Exit(1)
	}
}

func SetVersion(v string) {
	version = v
	rootCmd.Version = v
}

func CurrentConfig() *config.Manager {
	return manager
}

func requireProjectConfig() (*config.Manager, error) {
	if manager == nil {
		return nil, fmt.Errorf("configuration is not loaded")
	}
	if err := manager.ValidateProjectConfig(); err != nil {
		return nil, utils.NewSuggestionError(err.Error(), "Run `parallax init` in your project root to create .parallax.yaml.")
	}
	return manager, nil
}

func init() {
	rootCmd.SetVersionTemplate("{{.Name}} version {{.Version}}\n")
	rootCmd.PersistentFlags().BoolVarP(&rootOpts.Verbose, "verbose", "v", false, "Enable verbose logging")
	rootCmd.PersistentFlags().StringVarP(&rootOpts.Output, "output", "o", "text", "Output format: text or json")
	rootCmd.PersistentFlags().StringVar(&rootOpts.ConfigFile, "config", "", "Path to global config file (default: ~/.parallax.yaml)")
	rootCmd.PersistentFlags().StringVar(&rootOpts.ProjectFile, "project-config", "", "Path to a project .parallax.yaml file")
	rootCmd.PersistentFlags().BoolVar(&rootOpts.NoColor, "no-color", false, "Disable ANSI colors")
	rootCmd.AddCommand(newCompletionCommand())
}

func newCompletionCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:       "completion [bash|zsh|fish|powershell]",
		Short:     "Generate shell completion scripts",
		ValidArgs: []string{"bash", "zsh", "fish", "powershell"},
		Args:      cobra.ExactValidArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			shell := args[0]
			switch shell {
			case "bash":
				return rootCmd.GenBashCompletion(os.Stdout)
			case "zsh":
				return rootCmd.GenZshCompletion(os.Stdout)
			case "fish":
				return rootCmd.GenFishCompletion(os.Stdout, true)
			default:
				return rootCmd.GenPowerShellCompletionWithDesc(os.Stdout)
			}
		},
	}
	return cmd
}
