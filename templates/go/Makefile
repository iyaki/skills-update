# Makefile for Go AI Harness projects

.PHONY: help verify quality format lint test test-race test-coverage coverage mutation security arch doctor tools run

GO ?= go
COVERAGE_MIN ?= 99
APP_BIN ?= bin/app

help:
	@printf "%s\n" \
	"Common targets:" \
	"  make verify        Run lint + unit tests" \
	"  make quality       Run extended checks (race, coverage, security, arch)" \
	"  make format        Run gofmt on tracked Go files" \
	"  make lint          Run golangci-lint" \
	"  make test          Run unit tests" \
	"  make test-race     Run tests with race detection" \
	"  make test-coverage Enforce minimum coverage gate" \
	"  make mutation      Run mutation testing (gremlins)" \
	"  make security      Run govulncheck and gosec" \
	"  make arch          Run go-arch-lint" \
	"  make doctor        Print local tooling diagnostics" \
	"  make tools         Install required CLI tooling" \
	"  make run           Execute cmd/app"

verify: lint test

quality: verify test-race test-coverage security arch

format:
	@gofmt -w $$(git ls-files '*.go')

lint:
	@golangci-lint run

test:
	@$(GO) test -v ./...

test-race:
	@$(GO) test -race ./...

coverage: test-coverage

test-coverage:
	@coverprofile="$$(mktemp -t go-harness-cover.XXXXXX)"; \
	$(GO) test -coverprofile="$$coverprofile" -covermode=atomic ./...; \
	total="$$($(GO) tool cover -func="$$coverprofile" | awk '/^total:/{gsub(/%/,"",$$3); print $$3}')"; \
	rm -f "$$coverprofile"; \
	if ! awk -v total="$$total" -v minimum="$(COVERAGE_MIN)" 'BEGIN {exit !(total >= minimum)}'; then \
		echo "Coverage $${total}% is below required $(COVERAGE_MIN)%." >&2; \
		exit 1; \
	fi

mutation:
	@gremlins unleash

security:
	@govulncheck ./...
	@gosec ./...

arch:
	@go-arch-lint check

tools:
	@$(GO) install github.com/evilmartians/lefthook@latest
	@$(GO) install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@$(GO) install golang.org/x/vuln/cmd/govulncheck@latest
	@$(GO) install github.com/securego/gosec/v2/cmd/gosec@latest
	@$(GO) install github.com/fe3dback/go-arch-lint@latest
	@$(GO) install github.com/go-gremlins/gremlins/cmd/gremlins@latest

run:
	@$(GO) run ./cmd/app
