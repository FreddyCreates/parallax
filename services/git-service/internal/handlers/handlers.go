package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/sirupsen/logrus"

	"github.com/ItsNotAILABS/parralax-aihftfund/services/git-service/internal/git"
)

// Handler holds dependencies for HTTP handlers.
type Handler struct {
	engine *git.Engine
	log    *logrus.Logger
}

// New creates a new Handler.
func New(engine *git.Engine, log *logrus.Logger) *Handler {
	return &Handler{engine: engine, log: log}
}

func (h *Handler) respond(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func (h *Handler) error(w http.ResponseWriter, status int, msg string) {
	h.respond(w, status, map[string]string{"error": msg})
}

// Health returns service health status.
func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
	h.respond(w, http.StatusOK, map[string]string{
		"status":  "healthy",
		"service": "parralax-git-service",
		"version": "1.0.0",
	})
}

// Metrics exposes prometheus metrics (placeholder).
func (h *Handler) Metrics(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain")
	w.Write([]byte("# HELP git_service_requests_total Total requests\n"))
}

// ListRepos lists repositories (placeholder).
func (h *Handler) ListRepos(w http.ResponseWriter, r *http.Request) {
	h.respond(w, http.StatusOK, map[string]interface{}{"repos": []string{}})
}

// CreateRepo initializes a new bare repository.
func (h *Handler) CreateRepo(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Owner string `json:"owner"`
		Name  string `json:"name"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.error(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if err := h.engine.InitRepo(req.Owner, req.Name); err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}
	h.respond(w, http.StatusCreated, map[string]string{
		"status": "created",
		"owner":  req.Owner,
		"repo":   req.Name,
	})
}

// GetRepo returns repository metadata.
func (h *Handler) GetRepo(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	owner, repo := vars["owner"], vars["repo"]
	_, err := h.engine.OpenRepo(owner, repo)
	if err != nil {
		h.error(w, http.StatusNotFound, "repository not found")
		return
	}
	h.respond(w, http.StatusOK, map[string]string{"owner": owner, "repo": repo, "status": "active"})
}

// DeleteRepo removes a repository.
func (h *Handler) DeleteRepo(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	owner, repo := vars["owner"], vars["repo"]
	if err := h.engine.DeleteRepo(owner, repo); err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}
	h.respond(w, http.StatusOK, map[string]string{"status": "deleted"})
}

// GetTree returns the tree for a given ref.
func (h *Handler) GetTree(w http.ResponseWriter, r *http.Request) {
	h.respond(w, http.StatusOK, map[string]string{"status": "tree"})
}

// GetBlob returns blob content.
func (h *Handler) GetBlob(w http.ResponseWriter, r *http.Request) {
	h.respond(w, http.StatusOK, map[string]string{"status": "blob"})
}

// ListCommits returns commit history.
func (h *Handler) ListCommits(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	owner, repo := vars["owner"], vars["repo"]
	ref := r.URL.Query().Get("ref")
	if ref == "" {
		ref = "main"
	}
	limitStr := r.URL.Query().Get("limit")
	limit := 50
	if limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			limit = l
		}
	}
	commits, err := h.engine.ListCommits(owner, repo, ref, limit)
	if err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}
	h.respond(w, http.StatusOK, map[string]interface{}{"commits": commits})
}

// GetCommit returns a single commit.
func (h *Handler) GetCommit(w http.ResponseWriter, r *http.Request) {
	h.respond(w, http.StatusOK, map[string]string{"status": "commit"})
}

// ListBranches returns all branches.
func (h *Handler) ListBranches(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	owner, repo := vars["owner"], vars["repo"]
	branches, err := h.engine.ListBranches(owner, repo)
	if err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}
	h.respond(w, http.StatusOK, map[string]interface{}{"branches": branches})
}

// CreateBranch creates a new branch.
func (h *Handler) CreateBranch(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	owner, repo := vars["owner"], vars["repo"]
	var req struct {
		Name   string `json:"name"`
		Target string `json:"target"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.error(w, http.StatusBadRequest, "invalid body")
		return
	}
	if err := h.engine.CreateBranch(owner, repo, req.Name, req.Target); err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}
	h.respond(w, http.StatusCreated, map[string]string{"status": "created", "branch": req.Name})
}

// DeleteBranch deletes a branch.
func (h *Handler) DeleteBranch(w http.ResponseWriter, r *http.Request) {
	h.respond(w, http.StatusOK, map[string]string{"status": "deleted"})
}

// ListTags returns all tags.
func (h *Handler) ListTags(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	owner, repo := vars["owner"], vars["repo"]
	tags, err := h.engine.ListTags(owner, repo)
	if err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}
	h.respond(w, http.StatusOK, map[string]interface{}{"tags": tags})
}

// CreateTag creates an annotated tag.
func (h *Handler) CreateTag(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	owner, repo := vars["owner"], vars["repo"]
	var req struct {
		Name    string `json:"name"`
		Target  string `json:"target"`
		Message string `json:"message"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.error(w, http.StatusBadRequest, "invalid body")
		return
	}
	if err := h.engine.CreateTag(owner, repo, req.Name, req.Target, req.Message); err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}
	h.respond(w, http.StatusCreated, map[string]string{"status": "created", "tag": req.Name})
}

// Compare shows diff between base and head.
func (h *Handler) Compare(w http.ResponseWriter, r *http.Request) {
	h.respond(w, http.StatusOK, map[string]string{"status": "compare"})
}

// Merge merges head into base.
func (h *Handler) Merge(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	owner, repo := vars["owner"], vars["repo"]
	var req struct {
		Base string `json:"base"`
		Head string `json:"head"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.error(w, http.StatusBadRequest, "invalid body")
		return
	}
	_, err := h.engine.Merge(owner, repo, req.Base, req.Head)
	if err != nil {
		h.error(w, http.StatusConflict, err.Error())
		return
	}
	h.respond(w, http.StatusOK, map[string]string{"status": "merged"})
}

// InfoRefs handles git smart HTTP info/refs.
func (h *Handler) InfoRefs(w http.ResponseWriter, r *http.Request) {
	service := r.URL.Query().Get("service")
	w.Header().Set("Content-Type", "application/x-"+service+"-advertisement")
	w.WriteHeader(http.StatusOK)
}

// UploadPack handles git-upload-pack (fetch/clone).
func (h *Handler) UploadPack(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/x-git-upload-pack-result")
	w.WriteHeader(http.StatusOK)
}

// ReceivePack handles git-receive-pack (push).
func (h *Handler) ReceivePack(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/x-git-receive-pack-result")
	w.WriteHeader(http.StatusOK)
}
