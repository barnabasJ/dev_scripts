# Development Scripts

This directory contains scripts to help with feature development using git
worktrees with isolated environments.

## Overview

These scripts allow you to work on multiple features simultaneously by creating
separate git worktrees, each with their own:

- Database (PostgreSQL in Docker)
- Phoenix server port
- Isolated configuration

## Scripts

### 🚀 `new_feature_worktree.sh`

Creates a new git worktree for feature development with complete isolation.

**Usage:**

```bash
./scripts/new_feature_worktree.sh <feature-name> [base-port]
```

**Examples:**

```bash
# Auto-calculated port (based on feature name hash)
./scripts/new_feature_worktree.sh user-management

# Custom port
./scripts/new_feature_worktree.sh user-management 4200
```

**What it creates:**

- New git branch: `feature/<feature-name>`
- Worktree directory: `../<project>_<feature-name>`
- Docker PostgreSQL container with unique port
- Custom configuration file (`config/dev.local.exs`)
- Database: `<project>_<feature-name>_dev`

**Port allocation:**

- Phoenix server: `base-port` (default: auto-calculated 4100-4999)
- PostgreSQL: `base-port + 1000` (e.g., 4200 → 5200)

### 🧹 `cleanup_feature_worktree.sh`

Removes a feature worktree and all associated resources.

**Usage:**

```bash
./scripts/cleanup_feature_worktree.sh <feature-name>
```

**Example:**

```bash
./scripts/cleanup_feature_worktree.sh user-management
```

**What it removes:**

- Docker PostgreSQL container
- Worktree directory
- Git branch
- Cleans up git worktree references

### 🛠️ `dev_server.sh`

Development helper that works in both main project and worktree environments.

**Usage:**

```bash
./scripts/dev_server.sh [command]
```

**Commands:**

- `server`, `s` - Start Phoenix server (default)
- `iex`, `i` - Start Phoenix server with IEx
- `test`, `t` - Run tests
- `format`, `f` - Format code
- `setup` - Setup project (deps, db, assets)
- `migrate`, `m` - Run database migrations
- `status` - Show project status and environment info
- `help`, `h` - Show help

**Examples:**

```bash
# Start server (auto-detects environment)
./scripts/dev_server.sh

# Start with IEx
./scripts/dev_server.sh iex

# Check environment status
./scripts/dev_server.sh status

# Run tests
./scripts/dev_server.sh test
```

## Workflow Example

### Starting a new feature:

```bash
# Create worktree for user management feature
./scripts/new_feature_worktree.sh user-management

# Switch to the new worktree
cd ../project_user_management

# Start development server
./scripts/dev_server.sh

# Your app is now running on auto-assigned port (e.g., http://localhost:4156)
```

### Working on the feature:

```bash
# Check status
./scripts/dev_server.sh status

# Run tests
./scripts/dev_server.sh test

# Format code
./scripts/dev_server.sh format
```

### Cleaning up when done:

```bash
# Go back to main project
cd ../project

# Clean up everything
./scripts/cleanup_feature_worktree.sh user-management
```

## Technical Details

### Configuration

- Each worktree gets a `config/dev.local.exs` file with custom settings
- This file is automatically added to `.gitignore`
- Main `config/dev.exs` is modified to import the local config if it exists

### Database Isolation

- Each feature gets its own PostgreSQL Docker container
- Container naming: `postgres_<project>_<feature>`
- Database naming: `<project>_<feature>_dev`
- Automatic port assignment to avoid conflicts

### Port Management

- Phoenix ports are auto-calculated using feature name hash (4100-4999 range)
- Database ports are Phoenix port + 1000
- Consistent ports for the same feature name across sessions

### Prerequisites

- Docker installed and running
- Git worktree support
- PostgreSQL client tools (for setup verification)

## Troubleshooting

### Port conflicts

If you get port conflicts, specify a custom port:

```bash
./scripts/new_feature_worktree.sh my-feature 4300
```

### Docker issues

Check if containers are running:

```bash
docker ps
```

Remove stuck containers:

```bash
docker rm -f postgres_<project>_<feature>
```

### Worktree issues

List all worktrees:

```bash
git worktree list
```

Clean up stale references:

```bash
git worktree prune
```

### Database connection issues

Verify container is running and accepting connections:

```bash
docker exec postgres_<project>_<feature> pg_isready -U postgres
```

## Tips

1. **Multiple features**: You can have multiple worktrees running simultaneously
   with different ports
2. **Status checking**: Use `./scripts/dev_server.sh status` to see your current
   environment
3. **Container management**: Use `docker ps` to see all running PostgreSQL
   containers
4. **Git branches**: Each worktree creates a new branch prefixed with `feature/`
5. **Performance**: File watchers can be disabled in worktrees by uncommenting
   the watcher config in `dev.local.exs`

