package cmd

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/config"
	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/utils"
	"github.com/spf13/cobra"
)

func init() {
	var (
		name    string
		project string
		network string
		force   bool
	)
	cmd := &cobra.Command{
		Use:   "init",
		Short: "Initialize a PARALLAX project",
		RunE: func(cmd *cobra.Command, _ []string) error {
			cwd, err := os.Getwd()
			if err != nil {
				return err
			}
			configPath := filepath.Join(cwd, ".parallax.yaml")
			if utils.FileExists(configPath) && !force {
				return utils.NewSuggestionError(".parallax.yaml already exists", "Re-run with --force to overwrite the local project config.")
			}
			defaultName := filepath.Base(cwd)
			if name == "" {
				name, err = utils.PromptString("Project name", defaultName)
				if err != nil {
					return err
				}
			}
			if project == "" {
				project, err = utils.PromptString("Project ID", utils.Slugify(name))
				if err != nil {
					return err
				}
			}
			if network == "" {
				network, err = utils.PromptString("Default network", "local")
				if err != nil {
					return err
				}
			}
			settings := config.DefaultSettings()
			settings.Project.Name = name
			settings.Project.ID = project
			settings.Project.Network = network
			for _, dir := range []string{"scripts", filepath.Join("src", "backend"), filepath.Join("src", "frontend"), "docs"} {
				if err := os.MkdirAll(filepath.Join(cwd, dir), 0o755); err != nil {
					return err
				}
			}
			if err := config.SaveProjectConfig(configPath, settings); err != nil {
				return err
			}
			if utils.JSONOutput() {
				return utils.PrintJSON(map[string]any{"project": settings.Project, "config_path": configPath})
			}
			fmt.Println(utils.Success("Initialized PARALLAX project"))
			fmt.Println(utils.Muted("Config: " + configPath))
			fmt.Println(utils.Muted("Directories: scripts, src/backend, src/frontend, docs"))
			return nil
		},
	}
	cmd.Flags().StringVar(&name, "name", "", "Project name")
	cmd.Flags().StringVar(&project, "id", "", "Project ID")
	cmd.Flags().StringVar(&network, "network", "", "Default network")
	cmd.Flags().BoolVar(&force, "force", false, "Overwrite an existing .parallax.yaml")
	rootCmd.AddCommand(cmd)
}
