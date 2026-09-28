#!/bin/bash
# Remove a worktree created by create-worktree.sh.
# Symlinks are unlinked first (never followed), so the shared data in the main
# tree is untouched. The branch itself is kept unless --delete-branch is given.
#
# Usage:
#   remove-worktree.sh <worktree-path> [--delete-branch]
set -euo pipefail

WT_DIR=""
DELETE_BRANCH=false
while [ $# -gt 0 ]; do
    case "$1" in
        --delete-branch) DELETE_BRANCH=true; shift ;;
        -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
        *) WT_DIR="$1"; shift ;;
    esac
done
[ -n "$WT_DIR" ] && [ -d "$WT_DIR" ] || { echo "❌ Worktree path not found: $WT_DIR"; exit 1; }
WT_DIR="$(cd "$WT_DIR" && pwd)"

BRANCH="$(git -C "$WT_DIR" rev-parse --abbrev-ref HEAD)"
MAIN_ROOT="$(git -C "$WT_DIR" worktree list --porcelain | head -n1 | sed 's/^worktree //')"
[ "$WT_DIR" != "$MAIN_ROOT" ] || { echo "❌ Refusing to remove the main working tree."; exit 1; }

# Refuse if there are real (non-symlink) uncommitted changes.
if [ -n "$(git -C "$WT_DIR" status --porcelain --untracked-files=all | grep -v '^?? ' || true)" ]; then
    echo "❌ Worktree has uncommitted changes. Commit or stash them first:"
    git -C "$WT_DIR" status --short
    exit 1
fi

echo "🧹 Unlinking symlinks in $WT_DIR"
find "$WT_DIR" -mindepth 1 -maxdepth 1 -type l -print -delete | sed 's/^/  🔗 /'

echo "🗑  Removing worktree"
git -C "$MAIN_ROOT" worktree remove --force "$WT_DIR"
if $DELETE_BRANCH; then
    git -C "$MAIN_ROOT" branch -D "$BRANCH"
    echo "🌿 Deleted branch $BRANCH"
fi
echo "✅ Done."
