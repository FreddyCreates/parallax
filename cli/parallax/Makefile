BINARY ?= parallax
VERSION ?= dev
LDFLAGS := -s -w -X main.version=$(VERSION)

.PHONY: build install test fmt tidy completion

build:
go build -ldflags "$(LDFLAGS)" -o bin/$(BINARY) .

install:
go install -ldflags "$(LDFLAGS)" .

test:
go test ./...

fmt:
gofmt -w $$(find . -name '*.go' -type f)

tidy:
go mod tidy

completion:
mkdir -p completions
go run . completion bash > completions/parallax.bash
go run . completion zsh > completions/_parallax
