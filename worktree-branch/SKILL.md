---
name: worktree-branch
description: Create a git worktree for a feature branch and symlink the I/O and non-tracked directories (data/, outputs/, logs/, checkpoints/, .venv/, and anything else untracked or gitignored at the repo root) from the main working tree into it, so the branch shares datasets, results, weights and the environment instead of re-downloading or re-generating them. Use when the user wants to "branch and work in a worktree", "ブランチを切ってworktreeで作業", "worktreeを作って", or to run two branches of an experiment side by side; also for cleaning such a worktree up.
---

# Worktree Branch (worktree + shared I/O symlinks)

## Purpose
Working on a branch in a separate `git worktree` gives an isolated checkout, but a
fresh checkout has **none** of the heavy, non-tracked state a research repo depends on:
datasets, outputs, logs, checkpoints, `.venv`, `.env`. Re-creating them per branch is
slow, wastes disk, and splits results across copies.

This skill creates the worktree and then **symlinks every top-level entry that git does
not track** from the main working tree into the new one. Code is per-branch; I/O and
environment are shared.

```
<repo>/                           # main working tree (branch main)
├── src/  configs/  ...           # tracked
├── outputs/  logs/  .venv/       # gitignored -> real directories live here
├── data -> /data/<Project>/data  # setup-model-weights style link
└── .worktrees/                   # gitignored; every worktree lives here
    └── feat_x/                   # worktree for branch feat/x
        ├── src/  configs/  ...   # own checkout
        ├── outputs -> <repo>/outputs
        ├── logs    -> <repo>/logs
        ├── .venv   -> <repo>/.venv
        └── data    -> <repo>/data              # links the link; resolves through
```

Worktrees always go under `<repo>/.worktrees/` — never as a sibling directory or under
`/tmp`. `.worktrees` itself is never linked into a worktree and is ignored via
`.git/info/exclude` if the repo's `.gitignore` does not already cover it.

## Core Principles (NON-NEGOTIABLE)

1. **Tracked files are never linked.** Only entries that are *untracked or gitignored in
   the main tree* are candidates. A tracked directory already exists in the worktree and
   is skipped with a warning.
2. **Link to the main tree's path, not to its target.** If main has
   `data -> /data/<Project>/data`, the worktree gets `data -> <main>/data`. Re-pointing
   main later re-points every worktree.
3. **Removing a worktree never touches shared data.** Links are unlinked, not followed.
4. **The main tree stays clean.** Nothing is written into the main checkout except
   the `.worktrees/` directory (gitignored) and `.git/info/exclude` entries (see
   *Why info/exclude*), which are no-ops for main.

## Scripts

| Script | What it does |
|--------|--------------|
| `scripts/create-worktree.sh <branch> [opts]` | `git worktree add` (creates the branch if needed) + symlinks |
| `scripts/remove-worktree.sh <path> [--delete-branch]` | unlink symlinks, `git worktree remove`, optionally delete branch |

### create-worktree.sh options

| Option | Meaning |
|--------|---------|
| `--base <ref>` | start point for a *new* branch (default: main tree's HEAD) |
| `--dir <path>` | worktree location (default `<repo>/.worktrees/<branch with / → _>`) |
| `--exclude <name>` | do **not** link this top-level entry (repeatable) |
| `--link <relpath>` | additionally link a nested / undetected path, e.g. `src/data/raw` (repeatable) |
| `--files` | also link top-level untracked/ignored **files** (e.g. `.env`) — dirs only by default |
| `--dry-run` | show the plan without changing anything |

It may be run from the main tree *or* from inside another worktree; it always resolves
the main tree via `git worktree list`.

## Procedure

1. **Inspect first.** From the repo, run `git status --short --ignored` and `ls -la` to see
   what is untracked/ignored at the root and which entries are already symlinks into
   `/data` (setup-model-weights convention). Decide what must *not* be shared
   (e.g. a scratch dir the branch should own) → `--exclude`.
2. **Dry run**, then create:
   ```bash
   ~/.claude/skills/worktree-branch/scripts/create-worktree.sh feat/my-change --dry-run
   ~/.claude/skills/worktree-branch/scripts/create-worktree.sh feat/my-change [--files] [--exclude wip]
   ```
3. **Verify** (mandatory): `ls -la <worktree>` shows the expected `->` links, listing
   *through* a link (`ls <worktree>/outputs`) shows real files, and
   `git -C <worktree> status --short` is clean apart from entries that are untracked in
   main as well.
4. **Work in the worktree** (`cd` there). Run experiments as usual — outputs land in the
   shared directory, so name runs so they are distinguishable across branches.
5. **Tear down** when merged:
   ```bash
   ~/.claude/skills/worktree-branch/scripts/remove-worktree.sh <worktree> [--delete-branch]
   ```
   The script refuses if the worktree has uncommitted tracked changes.

## Why info/exclude
A `.gitignore` rule with a trailing slash (`outputs/`) matches **directories only**. In the
worktree `outputs` is a symlink, so git would list it as untracked and `git add -A` would
commit the link. `create-worktree.sh` therefore appends `/<name>` to
`.git/info/exclude` (shared by all worktrees) for each linked entry that is ignored in
main but not in the worktree. For main this is a no-op — the real directory is already
ignored. Entries that are *untracked but not ignored* in main are deliberately left
visible; they are untracked there too.

## Reminders
- Never `git add` a symlink created by this skill; if one shows up in `git status`,
  add it to `.gitignore` (without trailing slash) or `--exclude` it and re-create.
- Shared `outputs/`/`logs/` means two branches can overwrite each other's runs — use
  distinct run names / Hydra `hydra.run.dir` per branch.
- `.venv` is shared. If the branch changes dependencies, `--exclude .venv` and build a
  separate environment in the worktree instead.
- Worktrees live *inside* the main tree at `.worktrees/`. The script makes sure it is
  gitignored, but tools that walk the project tree (ruff, pytest, `find`, grep) will see
  the copies — add `.worktrees` to their exclude lists (e.g. `ruff.toml` `exclude`).
- If a repo's `CLAUDE.md` names a worktree location, it is `.worktrees/`; do not invent
  another one.
- `git worktree remove` on a dirty worktree needs `--force` only because of the untracked
  symlinks; `remove-worktree.sh` unlinks them first so shared data is never at risk.
