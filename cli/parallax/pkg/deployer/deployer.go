package deployer

import (
	"context"
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/config"
	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/icp"
	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/utils"
)

type Request struct {
	ProjectRoot  string
	ScriptsDir   string
	Environment  string
	BackendOnly  bool
	FrontendOnly bool
	DryRun       bool
	Settings     config.Settings
}

type Step struct {
	Name    string   `json:"name"`
	Command []string `json:"command"`
}

type Result struct {
	Environment string        `json:"environment"`
	Identity    string        `json:"identity,omitempty"`
	DryRun      bool          `json:"dry_run"`
	Plan        []Step        `json:"plan"`
	Duration    time.Duration `json:"duration"`
	RolledBack  bool          `json:"rolled_back"`
	Output      string        `json:"output,omitempty"`
}

func Plan(req Request) []Step {
	target := "all"
	if req.BackendOnly {
		target = "backend"
	}
	if req.FrontendOnly {
		target = "frontend"
	}
	script := deployScript(req)
	if script != "" {
		return []Step{{Name: fmt.Sprintf("Run deployment script for %s", req.Environment), Command: append([]string{"bash", script}, target)}}
	}
	command := []string{"icp", "deploy", "--environment", req.Environment}
	switch target {
	case "backend":
		command = append(command, "backend")
	case "frontend":
		command = append(command, "frontend")
	default:
		command = append(command, "backend", "frontend")
	}
	return []Step{{Name: "Run icp deploy", Command: command}}
}

func Validate(ctx context.Context, req Request) (string, error) {
	client := icp.NewClient(req.ProjectRoot, req.Environment)
	if err := client.EnsureAvailable(ctx); err != nil {
		return "", err
	}
	identity, err := client.ValidateIdentity(ctx)
	if err != nil {
		return "", err
	}
	env := req.Settings.Environments[req.Environment]
	for _, id := range []string{env.BackendCanisterID, env.FrontendCanisterID} {
		if err := client.ValidateCanisterID(id); err != nil {
			return identity, err
		}
	}
	return identity, nil
}

func Run(ctx context.Context, req Request) (Result, error) {
	result := Result{Environment: req.Environment, DryRun: req.DryRun, Plan: Plan(req)}
	started := time.Now()
	identity, err := Validate(ctx, req)
	if err != nil {
		return result, err
	}
	result.Identity = identity
	if req.DryRun {
		result.Duration = time.Since(started)
		return result, nil
	}
	spinner := utils.NewSpinner("Deploying to " + req.Environment)
	if spinner != nil {
		spinner.Start()
		defer spinner.Stop()
	}
	step := result.Plan[0]
	cmdResult, err := utils.RunCommand(ctx, req.ProjectRoot, nil, step.Command[0], step.Command[1:]...)
	result.Output = strings.TrimSpace(strings.Join([]string{cmdResult.Stdout, cmdResult.Stderr}, "\n"))
	if err != nil {
		if rollback := rollbackScript(req); rollback != "" {
			_, rollbackErr := utils.RunCommand(ctx, req.ProjectRoot, nil, "bash", rollback)
			result.RolledBack = rollbackErr == nil
		}
		result.Duration = time.Since(started)
		return result, err
	}
	result.Duration = time.Since(started)
	return result, nil
}

func deployScript(req Request) string {
	candidates := []string{
		filepath.Join(req.ScriptsDir, fmt.Sprintf("deploy-%s.sh", req.Environment)),
		filepath.Join(req.ProjectRoot, fmt.Sprintf("deploy-%s.sh", req.Environment)),
	}
	if req.Environment == "local" {
		candidates = append(candidates, filepath.Join(req.ProjectRoot, "deploy.sh"))
	}
	if req.Environment == "mainnet" {
		candidates = append(candidates, filepath.Join(req.ProjectRoot, "deploy-mainnet.sh"))
	}
	for _, candidate := range candidates {
		if utils.FileExists(candidate) {
			return candidate
		}
	}
	return ""
}

func rollbackScript(req Request) string {
	for _, candidate := range []string{
		filepath.Join(req.ScriptsDir, fmt.Sprintf("rollback-%s.sh", req.Environment)),
		filepath.Join(req.ProjectRoot, fmt.Sprintf("rollback-%s.sh", req.Environment)),
	} {
		if utils.FileExists(candidate) {
			return candidate
		}
	}
	return ""
}
