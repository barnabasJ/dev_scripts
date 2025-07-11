#!/usr/bin/env bash

# Script to create a new git worktree for feature development with isolated ports and database
# Usage: ./scripts/new_feature_worktree.sh <feature-name> [base-port]

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <feature-name> [base-port]"
    echo "Example: $0 user-management 4100"
    echo "  This will create:"
    echo "  - Worktree: ../<project>_<feature-name>"
    echo "  - Database: <project>_<feature-name>_dev (in Docker)"
    echo "  - Phoenix port: <base-port> (default: auto-calculated)"
    echo "  - Database port: auto-calculated to avoid conflicts"
    exit 1
fi

FEATURE_NAME="$1"
BASE_PORT="${2:-}"

# Get project name from mix.exs
PROJECT_NAME=$(grep -E '^\s*app:\s*:' mix.exs | sed 's/.*app: :\([^,]*\).*/\1/')
if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Error: Could not extract project name from mix.exs"
    exit 1
fi

# Sanitize feature name (replace hyphens/underscores, lowercase)
SAFE_FEATURE_NAME=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]' | tr '-' '_')

# Auto-calculate ports if not provided
if [ -z "$BASE_PORT" ]; then
    # Use a hash of the feature name to get consistent ports
    HASH=$(echo "$SAFE_FEATURE_NAME" | shasum | cut -c1-3)
    BASE_PORT=$((16#$HASH % 900 + 4100))
fi


WORKTREE_DIR="../${PROJECT_NAME}_${SAFE_FEATURE_NAME}"
DB_NAME_DEV="${PROJECT_NAME}_${SAFE_FEATURE_NAME}_dev"
DB_NAME_TEST="${PROJECT_NAME}_${SAFE_FEATURE_NAME}_test"
BRANCH_NAME="feature/${SAFE_FEATURE_NAME}"

echo "🚀 Setting up new feature worktree:"
echo "  Project: $PROJECT_NAME"
echo "  Feature: $FEATURE_NAME"
echo "  Branch: $BRANCH_NAME"
echo "  Directory: $WORKTREE_DIR"
echo "  Dev Database: $DB_NAME_DEV"
echo "  Test Database: $DB_NAME_TEST"
echo "  Phoenix port: $BASE_PORT"
echo ""

# Check if worktree already exists
if [ -d "$WORKTREE_DIR" ]; then
    echo "❌ Error: Worktree directory $WORKTREE_DIR already exists"
    exit 1
fi

# Check if branch already exists locally
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    echo "❌ Error: Branch $BRANCH_NAME already exists locally"
    echo "   Use: git branch -D $BRANCH_NAME (to delete)"
    echo "   Or:  git worktree add $WORKTREE_DIR $BRANCH_NAME (to use existing)"
    exit 1
fi

# PostgreSQL is assumed to be running on localhost:5432

# Create new branch and worktree
echo "📁 Creating worktree and branch..."
git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR"


# Create custom config files for the worktree
echo "⚙️  Creating custom configuration..."

# Create config/dev.local.exs for port overrides
cat > "$WORKTREE_DIR/config/dev.local.exs" << EOF
import Config

# Custom configuration for worktree: $SAFE_FEATURE_NAME
# This file is gitignored and contains worktree-specific overrides

# Use custom database
config :${PROJECT_NAME}, ${PROJECT_NAME^}.Repo,
  database: "$DB_NAME_DEV"

# Use custom port to avoid conflicts
config :${PROJECT_NAME}, ${PROJECT_NAME^}Web.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: $BASE_PORT]

# Optional: Disable file watchers for better performance in worktrees
# config :${PROJECT_NAME}, ${PROJECT_NAME^}Web.Endpoint,
#   watchers: []
EOF

# Create config/test.local.exs for test environment
cat > "$WORKTREE_DIR/config/test.local.exs" << EOF
import Config

# Custom test configuration for worktree: $SAFE_FEATURE_NAME
# This file is gitignored and contains worktree-specific test overrides

# Use custom test database
config :${PROJECT_NAME}, ${PROJECT_NAME^}.Repo,
  database: "$DB_NAME_TEST"
EOF

# Update .gitignore to include local config files if not already there
if ! grep -q "config/dev.local.exs" "$WORKTREE_DIR/.gitignore" 2>/dev/null; then
    echo "config/dev.local.exs" >> "$WORKTREE_DIR/.gitignore"
fi
if ! grep -q "config/test.local.exs" "$WORKTREE_DIR/.gitignore" 2>/dev/null; then
    echo "config/test.local.exs" >> "$WORKTREE_DIR/.gitignore"
fi

# Modify dev.exs to import dev.local.exs
if ! grep -q "dev.local.exs" "$WORKTREE_DIR/config/dev.exs"; then
    echo "" >> "$WORKTREE_DIR/config/dev.exs"
    echo "# Import worktree-specific configuration if it exists" >> "$WORKTREE_DIR/config/dev.exs"
    echo 'if File.exists?("config/dev.local.exs"), do: import_config("dev.local.exs")' >> "$WORKTREE_DIR/config/dev.exs"
fi

# Modify test.exs to import test.local.exs
if ! grep -q "test.local.exs" "$WORKTREE_DIR/config/test.exs"; then
    echo "" >> "$WORKTREE_DIR/config/test.exs"
    echo "# Import worktree-specific test configuration if it exists" >> "$WORKTREE_DIR/config/test.exs"
    echo 'if File.exists?("config/test.local.exs"), do: import_config("test.local.exs")' >> "$WORKTREE_DIR/config/test.exs"
fi

# Setup the project
echo "📦 Setting up project dependencies..."
cd "$WORKTREE_DIR"
mix deps.get

# Run database setup
echo "🔧 Setting up databases..."
mix ecto.create
MIX_ENV=test mix ecto.create
mix ash.setup
MIX_ENV=test mix ash.setup

echo ""
echo "✅ Worktree setup complete!"
echo ""
echo "🔥 To start working:"
echo "   cd $WORKTREE_DIR"
echo "   mix phx.server"
echo ""
echo "🌐 Your app will be available at: http://localhost:$BASE_PORT"
echo ""
echo "🧹 To clean up later:"
echo "   ./scripts/cleanup_feature_worktree.sh $SAFE_FEATURE_NAME"
echo ""
echo "💡 Tips:"
echo "   - Use 'git worktree list' to see all active worktrees"
echo "   - Dev database: $DB_NAME_DEV"
echo "   - Test database: $DB_NAME_TEST"
