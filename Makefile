.PHONY: test test-all test-verbose coverage clean install-deps install-luaunit help lint

# Default target
help:
	@echo "Available targets:"
	@echo "  test            - Run all tests (or specific tests with PATTERN=...)"
	@echo "  coverage        - Run tests with luacov and enforce 100% line coverage"
	@echo "  clean           - Clean test cache files"
	@echo "  install-deps    - Download all test dependencies"
	@echo "  install-luaunit - Download luaunit test framework"
	@echo ""
	@echo "Examples:"
	@echo "  make test                               # Run all tests"
	@echo "  make test PATTERN=util                  # Match test/**/*util*_spec.lua"
	@echo "  make test PATTERN=config                # Match test/**/*config*_spec.lua"
	@echo "  make test PATTERN=test/util_spec.lua    # Full path"
	@echo "  make coverage                           # Run tests and check coverage"

# Install all test dependencies (cross-platform, uses Lua)
install-deps:
	@nvim --headless -u test/minimal_init.lua -c "lua dofile('test/install_deps.lua')" -c "qa!"

# Alias for individual dependency install (same cross-platform Lua script)
install-luaunit: install-deps

# Run tests with nvim headless
# Supports PATTERN parameter to run specific test file(s)
# Examples:
#   make test PATTERN=test/util_spec.lua
#   make test PATTERN=util  (shorthand for test/**/*util*_spec.lua)
test: install-deps
	@echo "Running tests with nvim --headless..."
	@nvim --headless -u test/minimal_init.lua \
		-c "lua _G.TEST_PATTERN = '$(PATTERN)'" \
		-c "lua dofile('test/run.lua')" \
		-c "qa!"

# Run tests with line coverage (luacov) and enforce the threshold.
# COVERAGE=1 enables luacov in test/minimal_init.lua; the report step
# parses luacov.stats.out and fails below the threshold (default 100%,
# override with COV_THRESHOLD=<n>).
coverage: install-deps
	@echo "Running tests with coverage..."
	@rm -f luacov.stats.out luacov.report.out coverage.log
	@COVERAGE=1 nvim --headless -u test/minimal_init.lua \
		-c "lua _G.TEST_PATTERN = '$(PATTERN)'" \
		-c "lua dofile('test/run.lua')" \
		-c "qa!"
	@nvim --headless -u test/minimal_init.lua \
		-c "lua dofile('test/coverage_report.lua')" \
		-c "qa!" > coverage.log 2>&1 \
		|| { cat coverage.log; exit 1; }
	@cat coverage.log

# Clean generated files
clean:
	@echo "Cleaning up..."
	@rm -rf test/*.lua~
	@rm -rf test/*.out
	@rm -rf luacov.stats.out luacov.report.out coverage.log
	@rm -rf *.swp
	@rm -rf /tmp/rooter_nvim_test_* 2>/dev/null || true

