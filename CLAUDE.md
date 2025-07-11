# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains development scripts for managing Phoenix/Elixir projects using git worktrees with isolated environments. The scripts enable parallel feature development by creating separate worktrees, each with their own database container and port allocation.

## Core Architecture

The system consists of three main bash scripts that work together:

1. **new_feature_worktree.sh** - Creates isolated development environments
2. **cleanup_feature_worktree.sh** - Removes worktrees and associated resources  
3. **dev_server.sh** - Universal development helper that adapts to environment

### Key Components

- **Project Detection**: Scripts extract project name from `mix.exs` using: `grep -E '^\s*app:\s*:' mix.exs`
- **Port Management**: Auto-calculates ports using feature name hash (4100-4999 range for Phoenix, +1000 for PostgreSQL)
- **Database Isolation**: Each worktree gets its own PostgreSQL Docker container
- **Configuration**: Uses `config/dev.local.exs` for worktree-specific settings

## Common Development Commands

```bash
# Create new feature worktree
./scripts/new_feature_worktree.sh <feature-name> [base-port]

# Start development server (auto-detects environment)
./scripts/dev_server.sh

# Available dev_server.sh commands:
./scripts/dev_server.sh server    # Start Phoenix server
./scripts/dev_server.sh iex       # Start with IEx
./scripts/dev_server.sh test      # Run tests
./scripts/dev_server.sh format    # Format code
./scripts/dev_server.sh setup     # Setup project
./scripts/dev_server.sh migrate   # Run migrations (ash.migrate)
./scripts/dev_server.sh status    # Show environment info

# Clean up feature worktree
./scripts/cleanup_feature_worktree.sh <feature-name>
```

## Environment Detection

The scripts automatically detect the development environment:
- **Main project**: No `config/dev.local.exs` file, uses port 4000
- **Worktree**: Has `config/dev.local.exs` file, uses auto-assigned port

## Database Commands

The project uses Ash framework migrations:
- `mix ash.migrate` - Run standard migrations
- `mix ash.migrate --tenants` - Run tenant migrations

## Prerequisites

- Docker (for PostgreSQL containers)
- Git worktree support
- Phoenix/Elixir development environment
- PostgreSQL client tools

## Naming Conventions

- Worktree directories: `../<project>_<feature-name>`
- Git branches: `feature/<feature-name>`
- Docker containers: `postgres_<project>_<feature-name>`
- Databases: `<project>_<feature-name>_dev`