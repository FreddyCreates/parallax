package utils

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/briandowns/spinner"
	"github.com/charmbracelet/lipgloss"
	"github.com/olekukonko/tablewriter"
)

type CommandResult struct {
	Stdout   string
	Stderr   string
	Duration time.Duration
	ExitCode int
}

type SuggestionError struct {
	Message    string
	Suggestion string
}

func (e SuggestionError) Error() string {
	if e.Suggestion == "" {
		return e.Message
	}
	return fmt.Sprintf("%s\nSuggestion: %s", e.Message, e.Suggestion)
}

var (
	verbose    bool
	jsonOutput bool
	noColor    bool
)

func SetVerbose(v bool) { verbose = v }
func Verbose() bool     { return verbose }
func SetJSONOutput(v bool) {
	jsonOutput = v
}
func JSONOutput() bool  { return jsonOutput }
func SetNoColor(v bool) { noColor = v }

func style(hex string) lipgloss.Style {
	if noColor {
		return lipgloss.NewStyle()
	}
	return lipgloss.NewStyle().Foreground(lipgloss.Color(hex)).Bold(true)
}

func accent(text string) string  { return style("12").Render(text) }
func success(text string) string { return style("10").Render(text) }
func warning(text string) string { return style("11").Render(text) }
func failure(text string) string { return style("9").Render(text) }
func muted(text string) string {
	if noColor {
		return text
	}
	return lipgloss.NewStyle().Foreground(lipgloss.Color("8")).Render(text)
}

func Info(message string) string    { return accent("→ " + message) }
func Success(message string) string { return success("✓ " + message) }
func Warn(message string) string    { return warning("! " + message) }
func Error(message string) string   { return failure("✗ " + message) }
func Muted(message string) string   { return muted(message) }

func PrintCommandError(err error) {
	if err == nil {
		return
	}
	if jsonOutput {
		_ = PrintJSON(map[string]any{"error": err.Error()})
		return
	}
	fmt.Fprintln(os.Stderr, Error(err.Error()))
}

func PrintJSON(v any) error {
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	return enc.Encode(v)
}

func NewSuggestionError(message, suggestion string) error {
	return SuggestionError{Message: message, Suggestion: suggestion}
}

func PromptString(prompt, defaultValue string) (string, error) {
	info, err := os.Stdin.Stat()
	if err != nil {
		return defaultValue, err
	}
	if info.Mode()&os.ModeCharDevice == 0 {
		return defaultValue, nil
	}
	fmt.Printf("%s [%s]: ", prompt, defaultValue)
	var value string
	if _, err := fmt.Scanln(&value); err != nil {
		if errors.Is(err, io.EOF) || strings.Contains(err.Error(), "unexpected newline") {
			return defaultValue, nil
		}
		return "", err
	}
	value = strings.TrimSpace(value)
	if value == "" {
		return defaultValue, nil
	}
	return value, nil
}

func FileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func EnsureDir(path string) error {
	return os.MkdirAll(path, 0o755)
}

func WriteFile(path, content string, mode os.FileMode) error {
	if err := EnsureDir(filepath.Dir(path)); err != nil {
		return err
	}
	return os.WriteFile(path, []byte(content), mode)
}

func Slugify(input string) string {
	value := strings.ToLower(strings.TrimSpace(input))
	value = strings.ReplaceAll(value, " ", "-")
	var b strings.Builder
	lastDash := false
	for _, r := range value {
		isAlphaNum := (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9')
		if isAlphaNum {
			b.WriteRune(r)
			lastDash = false
			continue
		}
		if !lastDash {
			b.WriteRune('-')
			lastDash = true
		}
	}
	result := strings.Trim(b.String(), "-")
	if result == "" {
		return "parallax-project"
	}
	return result
}

func RunCommand(ctx context.Context, dir string, env []string, name string, args ...string) (CommandResult, error) {
	if verbose {
		fmt.Fprintf(os.Stderr, "%s %s\n", Info("Running"), strings.Join(append([]string{name}, args...), " "))
	}
	cmd := exec.CommandContext(ctx, name, args...)
	cmd.Dir = dir
	cmd.Env = append(os.Environ(), env...)

	var stdoutBuf, stderrBuf bytes.Buffer
	cmd.Stdout = &stdoutBuf
	cmd.Stderr = &stderrBuf

	started := time.Now()
	err := cmd.Run()
	result := CommandResult{
		Stdout:   stdoutBuf.String(),
		Stderr:   stderrBuf.String(),
		Duration: time.Since(started),
	}
	if err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			result.ExitCode = exitErr.ExitCode()
		} else {
			result.ExitCode = -1
		}
		return result, fmt.Errorf("command %q failed: %w\n%s", strings.Join(append([]string{name}, args...), " "), err, strings.TrimSpace(result.Stderr))
	}
	return result, nil
}

func NewSpinner(message string) *spinner.Spinner {
	if jsonOutput {
		return nil
	}
	s := spinner.New(spinner.CharSets[14], 100*time.Millisecond)
	s.Suffix = " " + message
	s.Color("cyan")
	return s
}

func HumanSize(size int64) string {
	const unit = 1024
	if size < unit {
		return fmt.Sprintf("%d B", size)
	}
	div, exp := int64(unit), 0
	for n := size / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %ciB", float64(size)/float64(div), "KMGTPE"[exp])
}

func DirSize(paths ...string) int64 {
	var total int64
	for _, path := range paths {
		info, err := os.Stat(path)
		if err != nil {
			continue
		}
		if !info.IsDir() {
			total += info.Size()
			continue
		}
		_ = filepath.Walk(path, func(_ string, info os.FileInfo, err error) error {
			if err == nil && !info.IsDir() {
				total += info.Size()
			}
			return nil
		})
	}
	return total
}

func ClearScreen() {
	if jsonOutput {
		return
	}
	fmt.Print("\033[H\033[2J")
}

func RenderTable(headers []string, rows [][]string) {
	t := tablewriter.NewWriter(os.Stdout)
	t.SetHeader(headers)
	t.SetBorder(false)
	t.SetAutoWrapText(false)
	t.SetRowLine(false)
	t.SetCenterSeparator("")
	t.SetColumnSeparator("")
	t.SetRowSeparator("")
	t.AppendBulk(rows)
	t.Render()
}

func SortedKeys[V any](m map[string]V) []string {
	keys := make([]string, 0, len(m))
	for key := range m {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func PrettyJSONOrRaw(input string) string {
	var data any
	if err := json.Unmarshal([]byte(input), &data); err != nil {
		return strings.TrimSpace(input)
	}
	buf := &bytes.Buffer{}
	enc := json.NewEncoder(buf)
	enc.SetIndent("", "  ")
	_ = enc.Encode(data)
	return strings.TrimSpace(buf.String())
}
