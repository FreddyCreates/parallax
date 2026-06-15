package cmd

import (
	"context"
	"fmt"
	"strings"

	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/builder"
	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/utils"
	"github.com/spf13/cobra"
)

func init() {
	var (
		backend  bool
		frontend bool
		services []string
		clean    bool
		noCache  bool
	)
	cmd := &cobra.Command{
		Use:   "build",
		Short: "Build backend, frontend, or selected services",
		RunE: func(cmd *cobra.Command, _ []string) error {
			cfg, err := requireProjectConfig()
			if err != nil {
				return err
			}
			result, runErr := builder.Run(context.Background(), builder.Request{
				ProjectRoot: cfg.ProjectRoot,
				ScriptsDir:  cfg.ScriptsDir(),
				Backend:     backend,
				Frontend:    frontend,
				Services:    services,
				Clean:       clean,
				NoCache:     noCache,
			})
			if utils.JSONOutput() {
				if err := utils.PrintJSON(result); err != nil {
					return err
				}
				return runErr
			}
			rows := make([][]string, 0, len(result.Results))
			for _, item := range result.Results {
				status := utils.Success("ok")
				if !item.Success {
					status = utils.Error("failed")
				}
				rows = append(rows, []string{item.Target, status, item.Mode, item.Duration.Round(10_000_000).String(), utils.HumanSize(item.Size)})
			}
			fmt.Println(utils.Info("Build summary"))
			utils.RenderTable([]string{"Target", "Status", "Mode", "Duration", "Size"}, rows)
			for _, item := range result.Results {
				if item.Error != "" {
					fmt.Printf("\n%s\n%s\n", utils.Warn(strings.ToUpper(item.Target)+" output"), item.Output)
				}
			}
			return runErr
		},
	}
	cmd.Flags().BoolVar(&backend, "backend", false, "Build backend only")
	cmd.Flags().BoolVar(&frontend, "frontend", false, "Build frontend only")
	cmd.Flags().StringSliceVar(&services, "services", nil, "Comma-separated service names to build")
	cmd.Flags().BoolVar(&clean, "clean", false, "Clean output directories before building")
	cmd.Flags().BoolVar(&noCache, "no-cache", false, "Disable build caches when supported")
	rootCmd.AddCommand(cmd)
}
