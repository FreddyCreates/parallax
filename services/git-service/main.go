package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/mux"
	"github.com/sirupsen/logrus"

	"github.com/ItsNotAILABS/parralax-aihftfund/services/git-service/internal/git"
	"github.com/ItsNotAILABS/parralax-aihftfund/services/git-service/internal/handlers"
	"github.com/ItsNotAILABS/parralax-aihftfund/services/git-service/internal/middleware"
)

func main() {
	log := logrus.New()
	log.SetFormatter(&logrus.JSONFormatter{})
	log.SetLevel(logrus.InfoLevel)

	port := os.Getenv("GIT_SERVICE_PORT")
	if port == "" {
		port = "8082"
	}

	repoBasePath := os.Getenv("GIT_REPO_BASE_PATH")
	if repoBasePath == "" {
		repoBasePath = "/var/lib/parralax/repos"
	}

	gitEngine := git.NewEngine(repoBasePath, log)
	handler := handlers.New(gitEngine, log)

	r := mux.NewRouter()

	// Health
	r.HandleFunc("/health", handler.Health).Methods("GET")
	r.HandleFunc("/metrics", handler.Metrics).Methods("GET")

	// Repository operations
	api := r.PathPrefix("/api/v1").Subrouter()
	api.Use(middleware.Auth)
	api.Use(middleware.RequestID)
	api.Use(middleware.Logging(log))

	// Repos
	api.HandleFunc("/repos", handler.ListRepos).Methods("GET")
	api.HandleFunc("/repos", handler.CreateRepo).Methods("POST")
	api.HandleFunc("/repos/{owner}/{repo}", handler.GetRepo).Methods("GET")
	api.HandleFunc("/repos/{owner}/{repo}", handler.DeleteRepo).Methods("DELETE")

	// Tree & Blobs
	api.HandleFunc("/repos/{owner}/{repo}/tree/{ref}", handler.GetTree).Methods("GET")
	api.HandleFunc("/repos/{owner}/{repo}/blob/{ref}/{path:.*}", handler.GetBlob).Methods("GET")

	// Commits
	api.HandleFunc("/repos/{owner}/{repo}/commits", handler.ListCommits).Methods("GET")
	api.HandleFunc("/repos/{owner}/{repo}/commits/{sha}", handler.GetCommit).Methods("GET")

	// Branches
	api.HandleFunc("/repos/{owner}/{repo}/branches", handler.ListBranches).Methods("GET")
	api.HandleFunc("/repos/{owner}/{repo}/branches", handler.CreateBranch).Methods("POST")
	api.HandleFunc("/repos/{owner}/{repo}/branches/{branch}", handler.DeleteBranch).Methods("DELETE")

	// Tags
	api.HandleFunc("/repos/{owner}/{repo}/tags", handler.ListTags).Methods("GET")
	api.HandleFunc("/repos/{owner}/{repo}/tags", handler.CreateTag).Methods("POST")

	// Compare & Merge
	api.HandleFunc("/repos/{owner}/{repo}/compare/{base}...{head}", handler.Compare).Methods("GET")
	api.HandleFunc("/repos/{owner}/{repo}/merge", handler.Merge).Methods("POST")

	// Smart HTTP Git Protocol
	r.HandleFunc("/{owner}/{repo}.git/info/refs", handler.InfoRefs).Methods("GET")
	r.HandleFunc("/{owner}/{repo}.git/git-upload-pack", handler.UploadPack).Methods("POST")
	r.HandleFunc("/{owner}/{repo}.git/git-receive-pack", handler.ReceivePack).Methods("POST")

	srv := &http.Server{
		Addr:         fmt.Sprintf(":%s", port),
		Handler:      r,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 60 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	go func() {
		log.WithField("port", port).Info("Git service starting")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.WithError(err).Fatal("Server failed")
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info("Shutting down git service...")
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.WithError(err).Fatal("Forced shutdown")
	}
	log.Info("Git service stopped")
}
