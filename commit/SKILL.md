---
name: commit
description: "Generate commit message and automatically commit staged changes. ONLY use when user explicitly invokes /git-cm slash command. Do NOT trigger on general git questions."
---

# Git Auto-Commit

Generate commit message and execute commit automatically.

## General Rules
- If user specifies language (e.g., "日本語で", "in English"), write commit message in that language
- If user wants to add details (e.g., "with details", "bodyあり"), ALWAYS write commit message with Body segment

## Workflow

### 1. Check Staged Changes

```bash
git diff --cached --stat
```

If empty, proceed to **Auto-Split Workflow** below. Otherwise continue to Step 2.

### 2. Analyze Diff

```bash
git diff --cached
```

For large diffs (>500 lines), check `--stat` first, then view key files selectively.

If needed for context:
- Read full file for new files
- Check `git log --oneline -5`

### 3. Generate & Execute Commit

Conventional Commits format:

```
<type>: <subject>

<body>
```

**Types (with usage and examples):**

| Type | When to use | Example |
| --- | --- | --- |
| `feat` | Add a **brand-new** feature or capability that did not exist before | `feat: add user search endpoint` |
| `update` | **Improve or extend an existing** feature/behavior (not a bug fix, not brand-new) | `update: add module-splitting guideline to refactor-python skill` |
| `fix` | Fix a bug or incorrect behavior | `fix: correct token expiration check` |
| `docs` | Documentation only (README, comments, docstrings) | `docs: document env var setup in README` |
| `style` | Formatting/whitespace/naming with no behavior change | `style: apply ruff formatting` |
| `refactor` | Restructure code without changing external behavior | `refactor: extract path helpers into module` |
| `perf` | Improve performance | `perf: cache SMPL-X model across batch` |
| `test` | Add or update tests | `test: add cases for empty input` |
| `chore` | Build, tooling, config, deps, housekeeping | `chore: ignore __pycache__` |

**`feat` vs `update`**: use `feat` only when introducing something that did **not** exist before. If the functionality already exists and you are enhancing, extending, or tweaking it, use `update`.

**Rules:**
- Subject: imperative, lowercase, no period, ≤50 chars
- Body: what/why not how, wrap 72 chars, keep simple if possible
  - The Body is optional: skip if the diff is very small to describe details

**Execute directly:**

```bash
git commit -m "type: subject" -m "body paragraph"
```

For multi-line body, use multiple `-m` flags.

## Auto-Split Workflow (when staging is empty)

### A. Inspect All Changes

```bash
git status --short
git diff --stat
git diff
```

If no changes exist, tell the user there is nothing to commit and stop.

### B. Classify Changes into Logical Work Units

Analyze the diff and group files by logical purpose:
- Group changes serving the same feature or goal into one commit
- Assign a type (feat/update/fix/refactor/test/chore/docs/etc.) to each group — see the **Types** table in Step 3 for when to use `feat` vs `update`
- Separate unrelated changes into distinct commits
- Order commits by dependency (e.g., feat before test)

### C. Present Split Plan to User and Confirm

Use AskUserQuestion to present the proposed plan in this format and wait for approval:

```
Proposed commits:

Commit 1: <type>: <subject>
  Files: <file1>, <file2>

Commit 2: <type>: <subject>
  Files: <file3>
...

Proceed? Let me know if you'd like any changes.
```

Only proceed to Step D after the user approves.

### D. Execute Commits in Order

For each planned commit:
```bash
git add <files for this commit>
git commit -m "type: subject" [-m "body"]
```

Apply the same Conventional Commits rules as Step 2/3.
All General Rules (language, body preference) apply here as well.

## Examples

**Simple:**
```bash
git commit -m "fix: correct token expiration check"
```

**With body:**
```bash
git commit -m "feat: add user search endpoint" -m "Implement fuzzy search across username and email fields."
```
