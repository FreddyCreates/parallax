package cmd

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	pmonitor "github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/monitor"
	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/utils"
	"github.com/spf13/cobra"
)

func init() {
	var (
		environment string
		interval    time.Duration
		metrics     []string
	)
	cmd := &cobra.Command{
		Use:   "monitor",
		Short: "Monitor canister health in real time",
		RunE: func(cmd *cobra.Command, _ []string) error {
			cfg, err := requireProjectConfig()
			if err != nil {
				return err
			}
			if environment == "" {
				environment = cfg.Settings.Project.Network
			}
			if interval <= 0 {
				interval, _ = time.ParseDuration(cfg.Settings.Monitor.DefaultInterval)
				if interval <= 0 {
					interval = 5 * time.Second
				}
			}
			canisters := cfg.Settings.Monitor.Canisters
			ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
			defer stop()
			render := func() error {
				statuses, err := pmonitor.Collect(ctx, pmonitor.Request{ProjectRoot: cfg.ProjectRoot, Environment: environment, Canisters: canisters})
				if err != nil {
					return err
				}
				if utils.JSONOutput() {
					return utils.PrintJSON(statuses)
				}
				utils.ClearScreen()
				rows := make([][]string, 0, len(statuses))
				for _, status := range statuses {
					rows = append(rows, []string{status.Canister, colorizeHealth(status.Status), pickMetric("cycles", metrics, status.Cycles), pickMetric("memory", metrics, status.Memory), pickMetric("hash", metrics, status.ModuleHash)})
				}
				fmt.Printf("%s %s (%s)\n\n", utils.Info("PARALLAX monitor"), environment, time.Now().Format(time.RFC3339))
				utils.RenderTable([]string{"Canister", "Status", "Cycles", "Memory", "Module Hash"}, rows)
				fmt.Println(utils.Muted("Press Ctrl+C to stop."))
				return nil
			}
			go func() {
				<-ctx.Done()
				os.Exit(0)
			}()
			return pmonitor.Every(interval, render)
		},
	}
	cmd.Flags().StringVar(&environment, "env", "", "Target environment")
	cmd.Flags().DurationVar(&interval, "interval", 0, "Refresh interval (for example 5s)")
	cmd.Flags().StringSliceVar(&metrics, "metrics", nil, "Metrics to show: cycles,memory,hash")
	rootCmd.AddCommand(cmd)
}

func colorizeHealth(status string) string {
	switch strings.ToLower(status) {
	case "running", "healthy":
		return utils.Success(status)
	case "stopping", "degraded":
		return utils.Warn(status)
	default:
		return utils.Error(status)
	}
}

func pickMetric(name string, selected []string, value string) string {
	if len(selected) == 0 {
		return value
	}
	for _, metric := range selected {
		if metric == name {
			return value
		}
	}
	return "-"
}
