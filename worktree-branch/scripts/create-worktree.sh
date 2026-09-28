#!/bin/bash
# Create a git worktree for a branch and symlink every top-level directory that
# git does not track (untracked or ignored: data/, outputs/, logs/, .venv/, ...)
# from the main working tree into the new worktree.
#
# Usage:
#   create-worktree.sh <branch> [options]
#
# Options:
#   --base <ref>       Start point when <branch> does not exist yet (default: current HEAD of main)
#   --dir <path>       Worktree location (default: <main>/.worktrees/<branch with / -> _>)
#   --exclude <name>   Top-level entry NOT to link (repeatable)
#   --link <relpath>   Extra path to link even if nested / not auto-detected (repeatable)
#   --files            Also link top-level untracked/ignored FILES (e.g. .env)
#   --dry-run          Print what would happen without doing it
set -euo pipefail

usage() { sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

BRANCH=""
BASE=""
WT_DIR=""
EXCLUDES=()
EXTRA_LINKS=()
LINK_FILES=false
DRY_RUN=false

while [ $# -gt 0 ]; do
    case "$1" in
        --base)    BASE="$2"; shift 2 ;;
        --dir)     WT_DIR="$2"; shift 2 ;;
        --exclude) EXCLUDES+=("$2"); shift 2 ;;
        --link)    EXTRA_LINKS+=("$2"); shift 2 ;;
        --files)   LINK_FILES=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage ;;
        -*)        echo "❌ Unknown option: $1"; usage ;;
        *)         if [ -z "$BRANCH" ]; then BRANCH="$1"; shift; else echo "❌ Unexpected argument: $1"; usage; fi ;;
    esac
done
[ -n "$BRANCH" ] || usage

run() {
    if $DRY_RUN; then echo "  [dry-run] $*"; else "$@"; fi
}

# 1. Resolve the MAIN working tree (first entry of `git worktree list`), even when
#    invoked from inside another worktree.
MAIN_ROOT="$(git worktree list --porcelain | head -n1 | sed 's/^worktree //')"
[ -n "$MAIN_ROOT" ] || { echo "❌ Not inside a git repository."; exit 1; }
cd "$MAIN_ROOT"

# 2. Decide the worktree location: always inside the main tree under .worktrees/.
WT_HOME=".worktrees"
if [ -z "$WT_DIR" ]; then
    WT_DIR="$MAIN_ROOT/$WT_HOME/${BRANCH//\//_}"
fi
if [ -e "$WT_DIR" ]; then
    echo "❌ Target already exists: $WT_DIR"; exit 1
fi

# 3. Create the worktree (reuse the branch if it exists, else create it).
echo "📁 Main tree : $MAIN_ROOT"
echo "🌿 Branch    : $BRANCH"
echo "📂 Worktree  : $WT_DIR"
run mkdir -p "$(dirname "$WT_DIR")"
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    run git worktree add "$WT_DIR" "$BRANCH"
else
    run git worktree add -b "$BRANCH" "$WT_DIR" ${BASE:+"$BASE"}
fi

# 4. Collect top-level entries git does not track (untracked + ignored).
#    `--directory` collapses whole untracked/ignored dirs into "name/".
mapfile -t UNTRACKED < <(git ls-files --others --exclude-standard --directory | grep -E '^[^/]+/?$' || true)
mapfile -t IGNORED   < <(git ls-files --others --ignored --exclude-standard --directory | grep -E '^[^/]+/?$' || true)
mapfile -t CANDIDATES < <(printf '%s\n' "${UNTRACKED[@]:-}" "${IGNORED[@]:-}" | grep -v '^$' | sort -u)

is_excluded() {
    local name="$1"
    [ "$name" = ".git" ] && return 0
    for ex in "${EXCLUDES[@]:-}"; do [ -n "$ex" ] && [ "$name" = "$ex" ] && return 0; done
    return 1
}

link_one() {
    local rel="$1"
    local src="$MAIN_ROOT/$rel"
    local dst="$WT_DIR/$rel"
    if [ ! -e "$src" ] && [ ! -L "$src" ]; then
        echo "  ⚠️  skip (missing in main): $rel"; return
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        echo "  ⚠️  skip (already exists in worktree, probably tracked): $rel"; return
    fi
    [ -d "$(dirname "$dst")" ] || run mkdir -p "$(dirname "$dst")"
    run ln -s "$src" "$dst"
    LINKED_PATHS+=("$rel")
    echo "  🔗 $rel -> $src"
}

# 4b. The worktree home must never be linked into a worktree (it would recurse) and
#     must be ignored so it never shows up in `git status` of the main tree.
EXCLUDES+=("$WT_HOME")
if ! $DRY_RUN && ! git -C "$MAIN_ROOT" check-ignore -q "$WT_HOME"; then
    EXCLUDE_FILE="$(git rev-parse --path-format=absolute --git-common-dir)/info/exclude"
    mkdir -p "$(dirname "$EXCLUDE_FILE")"; touch "$EXCLUDE_FILE"
    grep -qxF "/$WT_HOME" "$EXCLUDE_FILE" || echo "/$WT_HOME" >> "$EXCLUDE_FILE"
    echo "  🙈 added /$WT_HOME to info/exclude (not covered by .gitignore)"
fi

echo "🔗 Linking untracked/ignored entries from main:"
LINKED_PATHS=()
for entry in "${CANDIDATES[@]}"; do
    name="${entry%/}"
    [ -n "$name" ] || continue
    is_excluded "$name" && continue
    # "name/" = real directory; a symlink pointing at a directory (e.g. data -> /data/<Project>/data)
    # is listed without the slash, so test the resolved path too.
    if [[ "$entry" == */ ]] || [ -d "$MAIN_ROOT/$name" ]; then
        link_one "$name"
    elif $LINK_FILES; then
        link_one "$name"
    fi
done
for rel in "${EXTRA_LINKS[@]:-}"; do
    [ -n "$rel" ] || continue
    link_one "${rel%/}"
done
[ "${#LINKED_PATHS[@]}" -gt 0 ] || echo "  (nothing to link)"

# 5. A .gitignore pattern with a trailing slash ("outputs/") matches directories only,
#    so the symlink in the worktree would show up as untracked. Register such links in
#    the repo-wide info/exclude (shared by all worktrees; harmless for main, where the
#    real directory is already ignored). Untracked-but-not-ignored entries are left alone.
if ! $DRY_RUN && [ "${#LINKED_PATHS[@]}" -gt 0 ]; then
    EXCLUDE_FILE="$(git rev-parse --path-format=absolute --git-common-dir)/info/exclude"
    mkdir -p "$(dirname "$EXCLUDE_FILE")"; touch "$EXCLUDE_FILE"
    for rel in "${LINKED_PATHS[@]}"; do
        git -C "$MAIN_ROOT" check-ignore -q "$rel" || continue          # not ignored in main -> leave as is
        git -C "$WT_DIR"    check-ignore -q "$rel" && continue          # already ignored in worktree
        grep -qxF "/$rel" "$EXCLUDE_FILE" || echo "/$rel" >> "$EXCLUDE_FILE"
        echo "  🙈 added /$rel to $(basename "$(dirname "$(dirname "$EXCLUDE_FILE")")")/info/exclude"
    done
fi

echo "✅ Done. Next:"
echo "   cd \"$WT_DIR\""
