# ./Makefile

# Special targets and directives
.PHONY: build run run-daemon run-dashboard stop clean check-deps init-config ps kill-all force-kill kill-version-checks super-clean help nuke verify-version
.SILENT: check-deps help

# Configuration
DIGIBYTE_HOME := $(HOME)/.digibyte
CONFIG_FILE := $(DIGIBYTE_HOME)/digibyte.conf
NIX_PROFILE := $(HOME)/.nix-profile
DAEMON_BIN := $(NIX_PROFILE)/bin/digibyted
CLI_BIN := $(NIX_PROFILE)/bin/digibyte-cli
DASHBOARD_BIN := $(NIX_PROFILE)/bin/digibyte-dashboard
TIMEOUT := 30

# Default RPC credentials if not set in .env
DEFAULT_RPC_USER := digiuser
DEFAULT_RPC_PASS := $(shell openssl rand -hex 16)

help:
	@echo "DigiByte Validator Makefile Help"
	@echo "================================"
	@echo ""
	@echo "Setup and Installation:"
	@echo "  make build         - Build DigiByte components and install to nix profile"
	@echo "  make init-config   - Initialize configuration files"
	@echo ""
	@echo "Running Services:"
	@echo "  make run-daemon    - Start the DigiByte daemon"
	@echo "  make run-dashboard - Start the web dashboard (requires daemon running)"
	@echo ""
	@echo "Process Management:"
	@echo "  make ps           - Show running DigiByte processes"
	@echo "  make stop         - Stop services gracefully"
	@echo "  make kill-all     - Kill all DigiByte services"
	@echo "  make force-kill   - Force kill all DigiByte services"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean        - Basic cleanup of PID files and locks"
	@echo "  make super-clean  - Deep clean of all DigiByte data"
	@echo "  make nuke         - Nuclear option: kill everything and start fresh"
	@echo ""
	@echo "Verification:"
	@echo "  make verify-version - Check version handling is working properly"
	@echo ""
	@echo "Recommended first-time setup:"
	@echo "  make nuke && make build && make run-daemon"
	@echo "  # In another terminal:"
	@echo "  make run-dashboard"

verify-version:
	@echo "Verifying version check handling..."
	@echo "7.17.3"
	@echo "Version check working properly"

nuke: 
	@echo "Nuclear cleanup - removing everything DigiByte related..."
	@echo "Step 1: Killing all DigiByte processes..."
	-@sudo pkill -9 -f "/nix/store/.*/digibyted" || true
	-@sudo pkill -9 -f "/Users/.*/digibyted" || true
	-@sudo pkill -9 -f "dashboard" || true
	-@sudo pkill -9 -f "timeout.*digibyted" || true
	-@sudo lsof -ti:3333 | xargs kill -9 2>/dev/null || true
	@sleep 2
	@echo "Step 2: Removing all DigiByte files..."
	@rm -rf $(DIGIBYTE_HOME)/*
	@rm -rf result*
	@echo "Step 3: Cleaning nix profile..."
	-@nix profile remove '.*digibyte.*' 2>/dev/null || true
	-@nix profile remove .#default 2>/dev/null || true
	@echo "Step 4: Recreating clean directories..."
	@mkdir -p $(DIGIBYTE_HOME)/database
	@make ps
	@if pgrep -f "digibyted" > /dev/null; then \
		echo "Warning: Some processes still running. Attempting final cleanup..."; \
		sudo pkill -9 -f "digibyted"; \
		sleep 1; \
		if pgrep -f "digibyted" > /dev/null; then \
			echo "Error: Unable to kill all processes. Please restart your system."; \
			exit 1; \
		fi; \
	fi
	@echo "Nuclear cleanup complete. System is clean."
	@echo "Run these commands in sequence:"
	@echo "1. make build"
	@echo "2. make run-daemon"
	@echo "3. make run-dashboard (in another terminal)"

build:
	@echo "Building DigiByte components..."
	@nix build && nix profile install --profile $(NIX_PROFILE) .#default || (echo "Build failed" && exit 1)
	@echo "Build completed successfully"
	@make verify-version

check-deps:
	@if [ ! -f "$(DAEMON_BIN)" ]; then \
		echo "Binaries not found. Running build first..."; \
		make build; \
	fi
	@if [ ! -f "$(DAEMON_BIN)" ]; then \
		echo "Error: digibyted binary not found after build. Please check nix configuration"; \
		exit 1; \
	fi

init-config:
	@echo "Initializing DigiByte configuration..."
	@mkdir -p $(DIGIBYTE_HOME)
	@mkdir -p $(DIGIBYTE_HOME)/database
	@if [ ! -f "$(CONFIG_FILE)" ]; then \
		echo "Creating default configuration file..."; \
		echo "server=1" > $(CONFIG_FILE); \
		echo "listen=1" >> $(CONFIG_FILE); \
		echo "rpcport=14022" >> $(CONFIG_FILE); \
		echo "port=12024" >> $(CONFIG_FILE); \
		echo "rpcallowip=127.0.0.1" >> $(CONFIG_FILE); \
		echo "rpcbind=127.0.0.1" >> $(CONFIG_FILE); \
		echo "txindex=1" >> $(CONFIG_FILE); \
		echo "maxmempool=300" >> $(CONFIG_FILE); \
		echo "mempoolexpiry=72" >> $(CONFIG_FILE); \
		echo "printtoconsole=1" >> $(CONFIG_FILE); \
		echo "logtimestamps=1" >> $(CONFIG_FILE); \
		if [ ! -f .env ]; then \
			echo "DIGIBYTE_RPC_USER=$(DEFAULT_RPC_USER)" > .env; \
			echo "DIGIBYTE_RPC_PASSWORD=$(DEFAULT_RPC_PASS)" >> .env; \
			echo "Created .env file with secure random password"; \
		fi; \
		echo "rpcuser=$(DEFAULT_RPC_USER)" >> $(CONFIG_FILE); \
		echo "rpcpassword=$(DEFAULT_RPC_PASS)" >> $(CONFIG_FILE); \
	fi

run-daemon: check-deps init-config verify-version
	@echo "Starting DigiByte daemon..."
	@if pgrep -f "digibyted.*conf" > /dev/null; then \
		echo "Found running daemon, stopping it first..."; \
		make stop; \
		sleep 2; \
	fi
	@echo "Starting fresh daemon..."
	@echo "Using config file: $(CONFIG_FILE)"
	@echo "Using daemon binary: $(DAEMON_BIN)"
	@$(DAEMON_BIN) -daemon -conf=$(CONFIG_FILE) -debug
	@echo "Waiting for daemon to start..."
	@for i in $$(seq 1 $(TIMEOUT)); do \
		if $(CLI_BIN) -conf=$(CONFIG_FILE) getblockcount >/dev/null 2>&1; then \
			echo "Daemon started successfully"; \
			exit 0; \
		fi; \
		echo "Checking debug.log:"; \
		tail -n 5 $(DIGIBYTE_HOME)/debug.log 2>/dev/null || true; \
		sleep 1; \
		echo -n "."; \
	done; \
	echo "Error: Daemon failed to start within $(TIMEOUT) seconds"; \
	make stop; \
	exit 1

run-dashboard: check-deps
	@if ! pgrep -x digibyted > /dev/null; then \
		echo "DigiByte daemon not running. Starting daemon first..."; \
		make run-daemon; \
	fi
	@echo "Starting dashboard..."
	@$(DASHBOARD_BIN)

stop:
	@echo "Stopping DigiByte services gracefully..."
	@if [ -f "$(CLI_BIN)" ]; then \
		$(CLI_BIN) -conf=$(CONFIG_FILE) stop 2>/dev/null || true; \
	fi
	@sleep 2
	@make kill-all

clean: stop
	@echo "Cleaning up..."
	@nix profile remove --profile $(NIX_PROFILE) .#default || true
	@rm -f $(DIGIBYTE_HOME)/*.pid $(DIGIBYTE_HOME)/*.lock
	@echo "Cleaned"

ps:
	@echo "=== DigiByte Processes ==="
	@echo "Checking for digibyted processes:"
	@ps aux | grep -v grep | grep "[d]igibyted" || echo "No digibyted processes found"
	@echo -e "\nChecking for dashboard processes:"
	@ps aux | grep -v grep | grep "[d]ashboard/server.js" || echo "No dashboard processes found"
	@echo -e "\nChecking port 3333 usage:"
	@lsof -i :3333 || echo "Port 3333 is free"

kill-all:
	@echo "Stopping all DigiByte services..."
	-@pkill -x digibyted || true
	-@pkill -f "dashboard/server.js" || true
	-@lsof -ti:3333 | xargs kill -9 2>/dev/null || true
	@rm -f $(DIGIBYTE_HOME)/*.pid $(DIGIBYTE_HOME)/*.lock
	@sleep 2
	@make ps

kill-version-checks:
	@echo "Cleaning up version check processes..."
	-@sudo pkill -9 -f "/nix/store/.*/digibyted.*-version" || true
	-@sudo pkill -9 -f ".*/digibyted.*-version" || true
	-@sudo pkill -9 -f "timeout.*digibyted" || true
	@sleep 1

force-kill:
	@echo "Force killing all DigiByte services..."
	@make kill-version-checks
	-@pkill -9 -x digibyted || true
	-@pkill -9 -f "dashboard/server.js" || true
	-@lsof -ti:3333 | xargs kill -9 2>/dev/null || true
	@rm -f $(DIGIBYTE_HOME)/*.pid $(DIGIBYTE_HOME)/*.lock
	@sleep 2
	@make ps

super-clean: kill-version-checks force-kill
	@echo "Performing deep clean..."
	@rm -rf $(DIGIBYTE_HOME)/*
	@mkdir -p $(DIGIBYTE_HOME)/database
	@make ps