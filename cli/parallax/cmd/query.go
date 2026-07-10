package cmd

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/icp"
	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/utils"
	"github.com/spf13/cobra"
)

func init() {
	var (
		environment string
		canisterID  string
		method      string
		args        string
		output      string
	)
	cmd := &cobra.Command{
		Use:   "query",
		Short: "Query canister state via icp-cli",
		RunE: func(cmd *cobra.Command, _ []string) error {
			cfg, err := requireProjectConfig()
			if err != nil {
				return err
			}
			if environment == "" {
				environment = cfg.Settings.Project.Network
			}
			if canisterID == "" || method == "" {
				return fmt.Errorf("--canister-id and --method are required")
			}
			client := icp.NewClient(cfg.ProjectRoot, environment)
			response, err := client.Query(context.Background(), canisterID, method, args)
			if err != nil {
				return err
			}
			if output == "json" || utils.JSONOutput() {
				pretty := utils.PrettyJSONOrRaw(response)
				if json.Valid([]byte(pretty)) {
					fmt.Println(pretty)
					return nil
				}
				return utils.PrintJSON(map[string]any{"response": strings.TrimSpace(response)})
			}
			if json.Valid([]byte(response)) {
				var payload any
				_ = json.Unmarshal([]byte(response), &payload)
				switch value := payload.(type) {
				case map[string]any:
					rows := make([][]string, 0, len(value))
					for key, item := range value {
						rows = append(rows, []string{key, fmt.Sprintf("%v", item)})
					}
					utils.RenderTable([]string{"Field", "Value"}, rows)
					return nil
				case []any:
					rows := make([][]string, 0, len(value))
					for index, item := range value {
						rows = append(rows, []string{fmt.Sprintf("%d", index), fmt.Sprintf("%v", item)})
					}
					utils.RenderTable([]string{"Index", "Value"}, rows)
					return nil
				}
			}
			fmt.Println(response)
			return nil
		},
	}
	cmd.Flags().StringVar(&environment, "env", "", "Target environment")
	cmd.Flags().StringVar(&canisterID, "canister-id", "", "Canister ID to query")
	cmd.Flags().StringVar(&method, "method", "", "Canister method name")
	cmd.Flags().StringVar(&args, "args", "", "Raw argument payload passed to icp-cli")
	cmd.Flags().StringVar(&output, "output", "table", "Output format: table or json")
	rootCmd.AddCommand(cmd)
}
