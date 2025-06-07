#!/usr/bin/env bash

# Development server helper script
# Usage: ./scripts/dev_server.sh [command]

set -euo pipefail

# Get project name from mix.exs
PROJECT_NAME=$(grep -E '^\s*app:\s*:' mix.exs | sed 's/.*app: :\([^,]*\).*/\1/')

# Detect if we're in a worktree by checking for dev.local.exs
if [ -f "config/dev.local.exs" ]; then
    # Extract port from dev.local.exs
    PORT=$(grep -E 'port:\s*[0-9]+' config/dev.local.exs | sed 's/.*port: \([0-9]*\).*/\1/' || echo "unknown")
    echo "🔧 Detected worktree environment (port: $PORT)"
else
    PORT="4000"
    echo "🏠 Using main development environment (port: $PORT)"
fi

COMMAND="${1:-server}"

case "$COMMAND" in
    "server"|"s")
        echo "🚀 Starting Phoenix server..."
        mix phx.server
        ;;
    "iex"|"i")
        echo "🚀 Starting Phoenix server with IEx..."
        iex -S mix phx.server
        ;;
    "test"|"t")
        echo "🧪 Running tests..."
        mix test
        ;;
    "format"|"f")
        echo "📝 Formatting code..."
        mix format
        ;;
    "setup")
        echo "📦 Setting up project..."
        mix setup
        ;;
    "migrate"|"m")
        echo "🗄️  Running migrations..."
        mix ash.migrate
        mix ash.migrate --tenants
        ;;
    "status")
        echo "📊 Project status:"
        echo "  Project: $PROJECT_NAME"
        echo "  Port: $PORT"
        echo "  Environment: $(if [ -f "config/dev.local.exs" ]; then echo "worktree"; else echo "main"; fi)"
        if [ -f "config/dev.local.exs" ]; then
            echo "  Database port: $(grep -E 'port:\s*[0-9]+' config/dev.local.exs | tail -n1 | sed 's/.*port: \([0-9]*\).*/\1/' || echo "unknown")"
            CONTAINER=$(grep -E 'database:\s*"' config/dev.local.exs | sed 's/.*database: "\([^"]*\)".*/postgres_\1/' | sed 's/_dev$//' || echo "unknown")
            echo "  Container: $CONTAINER"
            if command -v docker >/dev/null 2>&1; then
                if docker ps --format '{{.Names}}' | grep -q "$CONTAINER"; then
                    echo "  Container status: running ✅"
                else
                    echo "  Container status: stopped ❌"
                fi
            fi
        fi
        echo "  URL: http://localhost:$PORT"
        ;;
    "help"|"h")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  server, s    Start Phoenix server (default)"
        echo "  iex, i       Start Phoenix server with IEx"
        echo "  test, t      Run tests"
        echo "  format, f    Format code"
        echo "  setup        Setup project (deps, db, assets)"
        echo "  migrate, m   Run database migrations"
        echo "  status       Show project status"
        echo "  help, h      Show this help"
        ;;
    *)
        echo "❌ Unknown command: $COMMAND"
        echo "Use './scripts/dev_server.sh help' for available commands"
        exit 1
        ;;
esac