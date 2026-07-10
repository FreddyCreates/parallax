package cmd

import (
	"context"
	"fmt"
	"strings"

	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/deployer"
	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/utils"
	"github.com/spf13/cobra"
)

func init() {
	var (
		environment  string
		backendOnly  bool
		frontendOnly bool
		dryRun       bool
	)
	cmd := &cobra.Command{
		Use:   "deploy",
		Short: "Deploy PARALLAX workloads to a target environment",
		RunE: func(cmd *cobra.Command, _ []string) error {
			cfg, err := requireProjectConfig()
			if err != nil {
				return err
			}
			if environment == "" {
				environment = cfg.Settings.Project.Network
			}
			if backendOnly && frontendOnly {
				return fmt.Errorf("--backend-only and --frontend-only cannot be combined")
			}
			req := deployer.Request{
				ProjectRoot:  cfg.ProjectRoot,
				ScriptsDir:   cfg.ScriptsDir(),
				Environment:  environment,
				BackendOnly:  backendOnly,
				FrontendOnly: frontendOnly,
				DryRun:       dryRun,
				Settings:     cfg.Settings,
			}
			plan := deployer.Plan(req)
			if !utils.JSONOutput() {
				fmt.Println(utils.Info("Deployment plan"))
				for _, step := range plan {
					fmt.Printf("- %s: %s\n", step.Name, strings.Join(step.Command, " "))
				}
			}
			result, runErr := deployer.Run(context.Background(), req)
			if utils.JSONOutput() {
				if err := utils.PrintJSON(result); err != nil {
					return err
				}
				return runErr
			}
			fmt.Println(utils.Success("Deployment finished"))
			fmt.Printf("Environment: %s\nIdentity: %s\nDuration: %s\n", result.Environment, result.Identity, result.Duration.Round(10_000_000))
			if result.RolledBack {
				fmt.Println(utils.Warn("Rollback executed after failure"))
			}
			if strings.TrimSpace(result.Output) != "" {
				fmt.Printf("\n%s\n", result.Output)
			}
			return runErr
		},
	}
	cmd.Flags().StringVar(&environment, "env", "", "Target environment: local, staging, or mainnet")
	cmd.Flags().BoolVar(&backendOnly, "backend-only", false, "Deploy backend only")
	cmd.Flags().BoolVar(&frontendOnly, "frontend-only", false, "Deploy frontend only")
	cmd.Flags().BoolVar(&dryRun, "dry-run", false, "Preview the deployment without executing it")
	rootCmd.AddCommand(cmd)
}
