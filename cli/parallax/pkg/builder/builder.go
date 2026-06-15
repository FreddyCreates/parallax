package builder

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/pkg/utils"
)

type Request struct {
	ProjectRoot string
	ScriptsDir  string
	Backend     bool
	Frontend    bool
	Services    []string
	Clean       bool
	NoCache     bool
}

type Task struct {
	Target      string   `json:"target"`
	ScriptPath  string   `json:"script_path,omitempty"`
	Command     []string `json:"command,omitempty"`
	OutputPaths []string `json:"output_paths,omitempty"`
}

type TargetResult struct {
	Target   string        `json:"target"`
	Mode     string        `json:"mode"`
	Success  bool          `json:"success"`
	Duration time.Duration `json:"duration"`
	Size     int64         `json:"size_bytes"`
	Output   string        `json:"output,omitempty"`
	Error    string        `json:"error,omitempty"`
}

type Result struct {
	Results   []TargetResult `json:"results"`
	StartedAt time.Time      `json:"started_at"`
	EndedAt   time.Time      `json:"ended_at"`
	Duration  time.Duration  `json:"duration"`
}

func Plan(req Request) ([]Task, error) {
	tasks := make([]Task, 0)
	if !req.Backend && !req.Frontend && len(req.Services) == 0 {
		req.Backend = true
		req.Frontend = true
	}
	if req.Backend {
		tasks = append(tasks, resolveBackendTask(req))
	}
	if req.Frontend {
		tasks = append(tasks, resolveFrontendTask(req))
	}
	for _, service := range req.Services {
		service = strings.TrimSpace(service)
		if service == "" {
			continue
		}
		tasks = append(tasks, resolveServiceTask(req, service))
	}
	if len(tasks) == 0 {
		return nil, fmt.Errorf("no build targets selected")
	}
	return tasks, nil
}

func resolveBackendTask(req Request) Task {
	script := firstExisting(
		filepath.Join(req.ScriptsDir, "build-backend.sh"),
		filepath.Join(req.ProjectRoot, "build-backend.sh"),
	)
	cmd := []string{"sh", "-c", "cd src/backend && mops build"}
	if !dirExists(filepath.Join(req.ProjectRoot, "src", "backend")) {
		cmd = []string{"sh", "-c", "mops build"}
	}
	return Task{Target: "backend", ScriptPath: script, Command: cmd, OutputPaths: []string{filepath.Join(req.ProjectRoot, "src", "backend", "dist")}}
}

func resolveFrontendTask(req Request) Task {
	script := firstExisting(
		filepath.Join(req.ScriptsDir, "build-frontend.sh"),
		filepath.Join(req.ProjectRoot, "build-frontend.sh"),
	)
	frontendDir := filepath.Join(req.ProjectRoot, "src", "frontend")
	if !dirExists(frontendDir) {
		frontendDir = filepath.Join(req.ProjectRoot, "frontend")
	}
	cmd := []string{"sh", "-c", fmt.Sprintf("cd %s && pnpm build", shellQuote(frontendDir))}
	return Task{Target: "frontend", ScriptPath: script, Command: cmd, OutputPaths: []string{filepath.Join(frontendDir, "dist"), filepath.Join(frontendDir, "build")}}
}

func resolveServiceTask(req Request, service string) Task {
	script := firstExisting(
		filepath.Join(req.ScriptsDir, fmt.Sprintf("build-%s.sh", service)),
		filepath.Join(req.ProjectRoot, fmt.Sprintf("build-%s.sh", service)),
	)
	serviceDir := filepath.Join(req.ProjectRoot, "services", service)
	command := []string{"sh", "-c", fmt.Sprintf("cd %s && go build ./...", shellQuote(serviceDir))}
	if utils.FileExists(filepath.Join(serviceDir, "package.json")) {
		command = []string{"sh", "-c", fmt.Sprintf("cd %s && pnpm build", shellQuote(serviceDir))}
	}
	return Task{Target: "service:" + service, ScriptPath: script, Command: command, OutputPaths: []string{filepath.Join(serviceDir, "dist"), filepath.Join(serviceDir, service)}}
}

func Run(ctx context.Context, req Request) (Result, error) {
	tasks, err := Plan(req)
	if err != nil {
		return Result{}, err
	}
	if req.Clean {
		for _, task := range tasks {
			for _, outputPath := range task.OutputPaths {
				_ = os.RemoveAll(outputPath)
			}
		}
	}
	result := Result{StartedAt: time.Now()}
	spinner := utils.NewSpinner("Building selected targets")
	if spinner != nil {
		spinner.Start()
		defer spinner.Stop()
	}

	results := make([]TargetResult, len(tasks))
	var wg sync.WaitGroup
	var runErr error
	var errMu sync.Mutex
	for i, task := range tasks {
		wg.Add(1)
		go func(index int, task Task) {
			defer wg.Done()
			results[index] = runTask(ctx, req, task)
			if !results[index].Success {
				errMu.Lock()
				if runErr == nil {
					runErr = fmt.Errorf("one or more build targets failed")
				}
				errMu.Unlock()
			}
		}(i, task)
	}
	wg.Wait()
	result.Results = results
	result.EndedAt = time.Now()
	result.Duration = result.EndedAt.Sub(result.StartedAt)
	return result, runErr
}

func runTask(ctx context.Context, req Request, task Task) TargetResult {
	started := time.Now()
	env := []string{
		fmt.Sprintf("PARALLAX_CLEAN=%t", req.Clean),
		fmt.Sprintf("PARALLAX_NO_CACHE=%t", req.NoCache),
	}
	var execErr error
	var cmdResult utils.CommandResult
	mode := "fallback"
	if task.ScriptPath != "" {
		mode = "script"
		cmdResult, execErr = utils.RunCommand(ctx, req.ProjectRoot, env, "bash", task.ScriptPath)
	} else {
		if len(task.Command) < 2 {
			return TargetResult{Target: task.Target, Mode: mode, Duration: time.Since(started), Error: "no script or fallback command available"}
		}
		cmdResult, execErr = utils.RunCommand(ctx, req.ProjectRoot, env, task.Command[0], task.Command[1:]...)
	}
	output := strings.TrimSpace(strings.Join([]string{cmdResult.Stdout, cmdResult.Stderr}, "\n"))
	return TargetResult{
		Target:   task.Target,
		Mode:     mode,
		Success:  execErr == nil,
		Duration: time.Since(started),
		Size:     utils.DirSize(task.OutputPaths...),
		Output:   output,
		Error:    errorString(execErr),
	}
}

func firstExisting(paths ...string) string {
	for _, path := range paths {
		if utils.FileExists(path) {
			return path
		}
	}
	return ""
}

func dirExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}

func errorString(err error) string {
	if err == nil {
		return ""
	}
	return err.Error()
}

func shellQuote(value string) string {
	return "'" + strings.ReplaceAll(value, "'", "'\\''") + "'"
}
