package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/viper"
	"gopkg.in/yaml.v3"
)

type ProjectConfig struct {
	Name    string `mapstructure:"name" yaml:"name"`
	ID      string `mapstructure:"id" yaml:"id"`
	Network string `mapstructure:"network" yaml:"network"`
}

type ScriptsConfig struct {
	Dir            string `mapstructure:"dir" yaml:"dir"`
	BuildPrefix    string `mapstructure:"build_prefix" yaml:"build_prefix"`
	TestPrefix     string `mapstructure:"test_prefix" yaml:"test_prefix"`
	DeployPrefix   string `mapstructure:"deploy_prefix" yaml:"deploy_prefix"`
	RollbackPrefix string `mapstructure:"rollback_prefix" yaml:"rollback_prefix"`
}

type EnvironmentConfig struct {
	Network            string `mapstructure:"network" yaml:"network"`
	Identity           string `mapstructure:"identity" yaml:"identity"`
	BackendCanisterID  string `mapstructure:"backend_canister_id" yaml:"backend_canister_id"`
	FrontendCanisterID string `mapstructure:"frontend_canister_id" yaml:"frontend_canister_id"`
}

type MonitorConfig struct {
	DefaultInterval string   `mapstructure:"default_interval" yaml:"default_interval"`
	Canisters       []string `mapstructure:"canisters" yaml:"canisters"`
}

type Settings struct {
	Project      ProjectConfig                `mapstructure:"project" yaml:"project"`
	Scripts      ScriptsConfig                `mapstructure:"scripts" yaml:"scripts"`
	Environments map[string]EnvironmentConfig `mapstructure:"environments" yaml:"environments"`
	Monitor      MonitorConfig                `mapstructure:"monitor" yaml:"monitor"`
}

type Manager struct {
	Settings    Settings
	GlobalPath  string
	ProjectPath string
	ProjectRoot string
	HasProject  bool
	HasGlobal   bool
	configViper *viper.Viper
}

func DefaultSettings() Settings {
	return Settings{
		Scripts: ScriptsConfig{
			Dir:            "scripts",
			BuildPrefix:    "build-",
			TestPrefix:     "test-",
			DeployPrefix:   "deploy-",
			RollbackPrefix: "rollback-",
		},
		Monitor: MonitorConfig{
			DefaultInterval: "5s",
			Canisters:       []string{"backend", "frontend"},
		},
		Environments: map[string]EnvironmentConfig{
			"local": {
				Network:  "local",
				Identity: "default",
			},
			"staging": {
				Network:  "staging",
				Identity: "default",
			},
			"mainnet": {
				Network:  "mainnet",
				Identity: "default",
			},
		},
	}
}

func setDefaults(v *viper.Viper) {
	defaults := DefaultSettings()
	v.SetDefault("scripts.dir", defaults.Scripts.Dir)
	v.SetDefault("scripts.build_prefix", defaults.Scripts.BuildPrefix)
	v.SetDefault("scripts.test_prefix", defaults.Scripts.TestPrefix)
	v.SetDefault("scripts.deploy_prefix", defaults.Scripts.DeployPrefix)
	v.SetDefault("scripts.rollback_prefix", defaults.Scripts.RollbackPrefix)
	v.SetDefault("monitor.default_interval", defaults.Monitor.DefaultInterval)
	v.SetDefault("monitor.canisters", defaults.Monitor.Canisters)
	for name, env := range defaults.Environments {
		v.SetDefault("environments."+name+".network", env.Network)
		v.SetDefault("environments."+name+".identity", env.Identity)
	}
	v.SetEnvPrefix("PARALLAX")
	v.SetEnvKeyReplacer(strings.NewReplacer(".", "_", "-", "_"))
	v.AutomaticEnv()
	for _, key := range []string{
		"project.name",
		"project.id",
		"project.network",
		"scripts.dir",
		"monitor.default_interval",
		"environments.local.backend_canister_id",
		"environments.local.frontend_canister_id",
		"environments.staging.backend_canister_id",
		"environments.staging.frontend_canister_id",
		"environments.mainnet.backend_canister_id",
		"environments.mainnet.frontend_canister_id",
	} {
		_ = v.BindEnv(key)
	}
}

func Load(globalPath, projectPath string) (*Manager, error) {
	v := viper.New()
	setDefaults(v)
	manager := &Manager{configViper: v}

	if globalPath == "" {
		home, err := os.UserHomeDir()
		if err == nil {
			globalPath = filepath.Join(home, ".parallax.yaml")
		}
	}
	manager.GlobalPath = globalPath
	if globalPath != "" {
		if _, err := os.Stat(globalPath); err == nil {
			gv := viper.New()
			gv.SetConfigFile(globalPath)
			if err := gv.ReadInConfig(); err != nil {
				return nil, fmt.Errorf("reading global config: %w", err)
			}
			if err := v.MergeConfigMap(gv.AllSettings()); err != nil {
				return nil, fmt.Errorf("merging global config: %w", err)
			}
			manager.HasGlobal = true
		}
	}

	resolvedProject, projectRoot, err := ResolveProjectFile(projectPath)
	if err != nil {
		return nil, err
	}
	manager.ProjectPath = resolvedProject
	manager.ProjectRoot = projectRoot
	if resolvedProject != "" {
		pv := viper.New()
		pv.SetConfigFile(resolvedProject)
		if err := pv.ReadInConfig(); err != nil {
			return nil, fmt.Errorf("reading project config: %w", err)
		}
		if err := v.MergeConfigMap(pv.AllSettings()); err != nil {
			return nil, fmt.Errorf("merging project config: %w", err)
		}
		manager.HasProject = true
	}
	if manager.ProjectRoot == "" {
		cwd, _ := os.Getwd()
		manager.ProjectRoot = cwd
	}
	if err := v.Unmarshal(&manager.Settings); err != nil {
		return nil, fmt.Errorf("decoding config: %w", err)
	}
	return manager, nil
}

func ResolveProjectFile(explicit string) (string, string, error) {
	if explicit != "" {
		abs, err := filepath.Abs(explicit)
		if err != nil {
			return "", "", err
		}
		return abs, filepath.Dir(abs), nil
	}
	cwd, err := os.Getwd()
	if err != nil {
		return "", "", err
	}
	current := cwd
	for {
		candidate := filepath.Join(current, ".parallax.yaml")
		if _, err := os.Stat(candidate); err == nil {
			return candidate, current, nil
		}
		parent := filepath.Dir(current)
		if parent == current {
			return "", cwd, nil
		}
		current = parent
	}
}

func (m *Manager) ValidateProjectConfig() error {
	if !m.HasProject {
		return fmt.Errorf("no project configuration found")
	}
	if strings.TrimSpace(m.Settings.Project.Name) == "" {
		return fmt.Errorf("project.name is required")
	}
	if strings.TrimSpace(m.Settings.Project.ID) == "" {
		return fmt.Errorf("project.id is required")
	}
	if strings.TrimSpace(m.Settings.Project.Network) == "" {
		return fmt.Errorf("project.network is required")
	}
	return nil
}

func (m *Manager) Environment(name string) EnvironmentConfig {
	if env, ok := m.Settings.Environments[name]; ok {
		return env
	}
	return EnvironmentConfig{Network: name}
}

func (m *Manager) ScriptsDir() string {
	return filepath.Join(m.ProjectRoot, m.Settings.Scripts.Dir)
}

func SaveProjectConfig(path string, settings Settings) error {
	payload, err := yaml.Marshal(settings)
	if err != nil {
		return err
	}
	return os.WriteFile(path, payload, 0o644)
}
