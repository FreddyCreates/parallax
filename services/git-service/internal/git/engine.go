package git

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	gogit "github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/config"
	"github.com/go-git/go-git/v5/plumbing"
	"github.com/go-git/go-git/v5/plumbing/object"
	"github.com/sirupsen/logrus"
)

// Engine provides git operations via go-git.
type Engine struct {
	basePath string
	log      *logrus.Logger
}

// NewEngine creates a new git engine rooted at basePath.
func NewEngine(basePath string, log *logrus.Logger) *Engine {
	return &Engine{basePath: basePath, log: log}
}

// RepoPath resolves the filesystem path for a repo.
func (e *Engine) RepoPath(owner, repo string) string {
	return filepath.Join(e.basePath, owner, repo+".git")
}

// InitRepo creates a new bare repository on disk.
func (e *Engine) InitRepo(owner, repo string) error {
	path := e.RepoPath(owner, repo)
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return fmt.Errorf("mkdir: %w", err)
	}
	_, err := gogit.PlainInit(path, true)
	if err != nil {
		return fmt.Errorf("git init: %w", err)
	}
	e.log.WithFields(logrus.Fields{"owner": owner, "repo": repo}).Info("Repository initialized")
	return nil
}

// OpenRepo opens an existing bare repository.
func (e *Engine) OpenRepo(owner, repo string) (*gogit.Repository, error) {
	path := e.RepoPath(owner, repo)
	r, err := gogit.PlainOpen(path)
	if err != nil {
		return nil, fmt.Errorf("open repo %s/%s: %w", owner, repo, err)
	}
	return r, nil
}

// DeleteRepo removes a repository from disk.
func (e *Engine) DeleteRepo(owner, repo string) error {
	path := e.RepoPath(owner, repo)
	return os.RemoveAll(path)
}

// ListBranches returns all branch names.
func (e *Engine) ListBranches(owner, repo string) ([]string, error) {
	r, err := e.OpenRepo(owner, repo)
	if err != nil {
		return nil, err
	}
	refs, err := r.Branches()
	if err != nil {
		return nil, err
	}
	var branches []string
	refs.ForEach(func(ref *plumbing.Reference) error {
		branches = append(branches, ref.Name().Short())
		return nil
	})
	return branches, nil
}

// CreateBranch creates a new branch from a target ref.
func (e *Engine) CreateBranch(owner, repo, branch, target string) error {
	r, err := e.OpenRepo(owner, repo)
	if err != nil {
		return err
	}
	hash, err := r.ResolveRevision(plumbing.Revision(target))
	if err != nil {
		return fmt.Errorf("resolve %s: %w", target, err)
	}
	ref := plumbing.NewHashReference(plumbing.NewBranchReferenceName(branch), *hash)
	return r.Storer.SetReference(ref)
}

// ListTags returns all tag names.
func (e *Engine) ListTags(owner, repo string) ([]string, error) {
	r, err := e.OpenRepo(owner, repo)
	if err != nil {
		return nil, err
	}
	refs, err := r.Tags()
	if err != nil {
		return nil, err
	}
	var tags []string
	refs.ForEach(func(ref *plumbing.Reference) error {
		tags = append(tags, ref.Name().Short())
		return nil
	})
	return tags, nil
}

// CreateTag creates an annotated tag.
func (e *Engine) CreateTag(owner, repo, tag, target, message string) error {
	r, err := e.OpenRepo(owner, repo)
	if err != nil {
		return err
	}
	hash, err := r.ResolveRevision(plumbing.Revision(target))
	if err != nil {
		return fmt.Errorf("resolve %s: %w", target, err)
	}
	_, err = r.CreateTag(tag, *hash, &gogit.CreateTagOptions{
		Tagger: &object.Signature{
			Name:  "PARRALAX System",
			Email: "system@parralax.ai",
			When:  time.Now(),
		},
		Message: message,
	})
	return err
}

// CommitInfo holds metadata about a commit.
type CommitInfo struct {
	SHA     string    `json:"sha"`
	Message string    `json:"message"`
	Author  string    `json:"author"`
	Email   string    `json:"email"`
	Date    time.Time `json:"date"`
}

// ListCommits returns commits for a given ref.
func (e *Engine) ListCommits(owner, repo, ref string, limit int) ([]CommitInfo, error) {
	r, err := e.OpenRepo(owner, repo)
	if err != nil {
		return nil, err
	}
	hash, err := r.ResolveRevision(plumbing.Revision(ref))
	if err != nil {
		return nil, err
	}
	iter, err := r.Log(&gogit.LogOptions{From: *hash})
	if err != nil {
		return nil, err
	}
	var commits []CommitInfo
	count := 0
	iter.ForEach(func(c *object.Commit) error {
		if count >= limit {
			return fmt.Errorf("limit reached")
		}
		commits = append(commits, CommitInfo{
			SHA:     c.Hash.String(),
			Message: c.Message,
			Author:  c.Author.Name,
			Email:   c.Author.Email,
			Date:    c.Author.When,
		})
		count++
		return nil
	})
	return commits, nil
}

// Merge performs a merge of head into base for the given repo.
func (e *Engine) Merge(owner, repo, base, head string) (*config.RemoteConfig, error) {
	// In production this would perform a three-way merge via go-git
	// For now, we validate refs exist
	r, err := e.OpenRepo(owner, repo)
	if err != nil {
		return nil, err
	}
	_, err = r.ResolveRevision(plumbing.Revision(base))
	if err != nil {
		return nil, fmt.Errorf("cannot resolve base %s: %w", base, err)
	}
	_, err = r.ResolveRevision(plumbing.Revision(head))
	if err != nil {
		return nil, fmt.Errorf("cannot resolve head %s: %w", head, err)
	}
	// Merge logic placeholder — full three-way merge in production
	return nil, nil
}
