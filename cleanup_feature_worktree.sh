#!/usr/bin/env bash

# Script to cleanup a feature worktree and its associated resources
# Usage: ./scripts/cleanup_feature_worktree.sh <feature-name>

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <feature-name>"
    echo "Example: $0 user-management"
    echo "  This will remove:"
    echo "  - Worktree: ../<project>_<feature-name>"
    echo "  - Docker container: postgres_<project>_<feature-name>"
    echo "  - Git branch: feature/<feature-name>"
    exit 1
fi

FEATURE_NAME="$1"

# Get project name from mix.exs
PROJECT_NAME=$(grep -E '^\s*app:\s*:' mix.exs | sed 's/.*app: :\([^,]*\).*/\1/')
if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Error: Could not extract project name from mix.exs"
    exit 1
fi

# Sanitize feature name (replace hyphens/underscores, lowercase)
SAFE_FEATURE_NAME=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]' | tr '-' '_')

WORKTREE_DIR="../${PROJECT_NAME}_${SAFE_FEATURE_NAME}"
BRANCH_NAME="feature/${SAFE_FEATURE_NAME}"
CONTAINER_NAME="postgres_${PROJECT_NAME}_${SAFE_FEATURE_NAME}"

echo "🧹 Cleaning up feature worktree:"
echo "  Project: $PROJECT_NAME"
echo "  Feature: $FEATURE_NAME"
echo "  Branch: $BRANCH_NAME"
echo "  Directory: $WORKTREE_DIR"
echo "  Container: $CONTAINER_NAME"
echo ""

# Ask for confirmation
read -p "Are you sure you want to delete everything? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

# Stop and remove Docker container
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "🐳 Stopping and removing Docker container..."
    docker rm -f "$CONTAINER_NAME"
else
    echo "ℹ️  Docker container $CONTAINER_NAME not found"
fi

# Remove worktree
if [ -d "$WORKTREE_DIR" ]; then
    echo "📁 Removing worktree..."
    git worktree remove "$WORKTREE_DIR" --force
else
    echo "ℹ️  Worktree directory $WORKTREE_DIR not found"
fi

# Delete branch
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    echo "🌿 Deleting branch..."
    git branch -D "$BRANCH_NAME"
else
    echo "ℹ️  Branch $BRANCH_NAME not found"
fi

# Clean up any remaining worktree references
git worktree prune

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "💡 Tip: Use 'git worktree list' to see remaining worktrees"