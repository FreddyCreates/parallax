package icp

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/utils"
)

type Client struct {
	Environment string
	Binary      string
	ProjectRoot string
}

type Status struct {
	Canister   string `json:"canister"`
	Status     string `json:"status"`
	Cycles     string `json:"cycles,omitempty"`
	Memory     string `json:"memory,omitempty"`
	ModuleHash string `json:"module_hash,omitempty"`
	Raw        string `json:"raw,omitempty"`
}

var canisterIDPattern = regexp.MustCompile(`^[a-z0-9-]{5,}$`)

func NewClient(projectRoot, environment string) *Client {
	return &Client{ProjectRoot: projectRoot, Environment: environment, Binary: "icp"}
}

func (c *Client) EnsureAvailable(ctx context.Context) error {
	_, err := utils.RunCommand(ctx, c.ProjectRoot, nil, c.Binary, "--help")
	if err != nil {
		return utils.NewSuggestionError("icp-cli is not available", "Install icp-cli and ensure the `icp` binary is on your PATH.")
	}
	return nil
}

func (c *Client) ValidateIdentity(ctx context.Context) (string, error) {
	result, err := utils.RunCommand(ctx, c.ProjectRoot, nil, c.Binary, "identity", "whoami")
	if err != nil {
		return "", utils.NewSuggestionError("unable to resolve ICP identity", "Run `icp identity whoami` to verify your active identity.")
	}
	return strings.TrimSpace(result.Stdout), nil
}

func (c *Client) ResolveCanisterID(ctx context.Context, canister string) (string, error) {
	result, err := utils.RunCommand(ctx, c.ProjectRoot, nil, c.Binary, "canister", "settings", "show", "--environment", c.Environment, "--id-only", canister)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(result.Stdout), nil
}

func (c *Client) ValidateCanisterID(value string) error {
	if strings.TrimSpace(value) == "" {
		return nil
	}
	if !canisterIDPattern.MatchString(value) {
		return fmt.Errorf("invalid canister ID %q", value)
	}
	return nil
}

func (c *Client) Query(ctx context.Context, canisterID, method, args string) (string, error) {
	commandArgs := []string{"canister", "call", "--environment", c.Environment, canisterID, method}
	if strings.TrimSpace(args) != "" {
		commandArgs = append(commandArgs, args)
	}
	result, err := utils.RunCommand(ctx, c.ProjectRoot, nil, c.Binary, commandArgs...)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(result.Stdout), nil
}

func (c *Client) Status(ctx context.Context, canister string) (Status, error) {
	result, err := utils.RunCommand(ctx, c.ProjectRoot, nil, c.Binary, "canister", "status", "--environment", c.Environment, canister)
	if err != nil {
		return Status{Canister: canister, Status: "unknown", Raw: strings.TrimSpace(result.Stderr)}, err
	}
	status := Status{Canister: canister, Raw: strings.TrimSpace(result.Stdout)}
	for _, line := range strings.Split(result.Stdout, "\n") {
		trimmed := strings.TrimSpace(line)
		switch {
		case strings.HasPrefix(strings.ToLower(trimmed), "status:"):
			status.Status = strings.TrimSpace(strings.TrimPrefix(trimmed, "Status:"))
		case strings.HasPrefix(strings.ToLower(trimmed), "balance:"):
			status.Cycles = strings.TrimSpace(strings.TrimPrefix(trimmed, "Balance:"))
		case strings.HasPrefix(strings.ToLower(trimmed), "memory size:"):
			status.Memory = strings.TrimSpace(strings.TrimPrefix(trimmed, "Memory Size:"))
		case strings.HasPrefix(strings.ToLower(trimmed), "module hash:"):
			status.ModuleHash = strings.TrimSpace(strings.TrimPrefix(trimmed, "Module hash:"))
		}
	}
	if status.Status == "" {
		status.Status = "unknown"
	}
	return status, nil
}
