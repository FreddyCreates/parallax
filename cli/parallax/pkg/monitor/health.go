package monitor

import (
	"context"
	"time"

	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/icp"
)

type Request struct {
	ProjectRoot string
	Environment string
	Canisters   []string
}

func Collect(ctx context.Context, req Request) ([]icp.Status, error) {
	client := icp.NewClient(req.ProjectRoot, req.Environment)
	statuses := make([]icp.Status, 0, len(req.Canisters))
	for _, canister := range req.Canisters {
		status, err := client.Status(ctx, canister)
		if err != nil {
			status.Raw = err.Error()
		}
		statuses = append(statuses, status)
	}
	return statuses, nil
}

func Every(interval time.Duration, fn func() error) error {
	if err := fn(); err != nil {
		return err
	}
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for range ticker.C {
		if err := fn(); err != nil {
			return err
		}
	}
	return nil
}
