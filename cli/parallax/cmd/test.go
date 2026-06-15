package cmd

import (
	"context"
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/utils"
	"github.com/spf13/cobra"
)

type testSuiteResult struct {
	Suite    string        `json:"suite"`
	Success  bool          `json:"success"`
	Duration time.Duration `json:"duration"`
	Output   string        `json:"output,omitempty"`
	Error    string        `json:"error,omitempty"`
}

func init() {
	var (
		unit        bool
		integration bool
		e2e         bool
		coverage    bool
		watch       bool
	)
	cmd := &cobra.Command{
		Use:   "test",
		Short: "Run PARALLAX test suites",
		RunE: func(cmd *cobra.Command, _ []string) error {
			cfg, err := requireProjectConfig()
			if err != nil {
				return err
			}
			runSuites := func() ([]testSuiteResult, error) {
				suites := selectedSuites(unit, integration, e2e)
				results := make([]testSuiteResult, 0, len(suites))
				var suiteErr error
				for _, suite := range suites {
					start := time.Now()
					script := filepath.Join(cfg.ScriptsDir(), fmt.Sprintf("test-%s.sh", suite))
					if !utils.FileExists(script) {
						results = append(results, testSuiteResult{Suite: suite, Success: false, Error: fmt.Sprintf("missing script %s", script)})
						suiteErr = fmt.Errorf("one or more test suites failed")
						continue
					}
					env := []string{fmt.Sprintf("PARALLAX_COVERAGE=%t", coverage)}
					output, runErr := utils.RunCommand(context.Background(), cfg.ProjectRoot, env, "bash", script)
					item := testSuiteResult{Suite: suite, Success: runErr == nil, Duration: time.Since(start), Output: strings.TrimSpace(strings.Join([]string{output.Stdout, output.Stderr}, "\n"))}
					if runErr != nil {
						item.Error = runErr.Error()
						suiteErr = fmt.Errorf("one or more test suites failed")
					}
					results = append(results, item)
				}
				return results, suiteErr
			}
			render := func(results []testSuiteResult) {
				if utils.JSONOutput() {
					_ = utils.PrintJSON(results)
					return
				}
				rows := make([][]string, 0, len(results))
				for _, result := range results {
					status := utils.Success("ok")
					if !result.Success {
						status = utils.Error("failed")
					}
					rows = append(rows, []string{result.Suite, status, result.Duration.Round(10_000_000).String()})
				}
				fmt.Println(utils.Info("Test results"))
				utils.RenderTable([]string{"Suite", "Status", "Duration"}, rows)
			}
			for {
				results, runErr := runSuites()
				render(results)
				if !watch {
					return runErr
				}
				time.Sleep(2 * time.Second)
			}
		},
	}
	cmd.Flags().BoolVar(&unit, "unit", false, "Run unit tests")
	cmd.Flags().BoolVar(&integration, "integration", false, "Run integration tests")
	cmd.Flags().BoolVar(&e2e, "e2e", false, "Run end-to-end tests")
	cmd.Flags().BoolVar(&coverage, "coverage", false, "Enable coverage reporting")
	cmd.Flags().BoolVar(&watch, "watch", false, "Re-run tests continuously")
	rootCmd.AddCommand(cmd)
}

func selectedSuites(unit, integration, e2e bool) []string {
	suites := make([]string, 0, 3)
	if !unit && !integration && !e2e {
		return []string{"unit", "integration", "e2e"}
	}
	if unit {
		suites = append(suites, "unit")
	}
	if integration {
		suites = append(suites, "integration")
	}
	if e2e {
		suites = append(suites, "e2e")
	}
	return suites
}
