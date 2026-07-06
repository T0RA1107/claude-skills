---
name: setup-model-weights
description: Store large project assets (checkpoints, datasets, weights) under /data/<Project> and symlink them back into the project tree. Use when setting up model weights or datasets.
---

# Setup Model Weights (data/ symlink convention)

## Purpose
Keep heavyweight artifacts (checkpoints, body models, pretrained priors, datasets)
out of the project repository. The **real files live under `/data/<ProjectName>/...`**,
and the project tree only contains **symlinks** pointing there.

This keeps repos small/cloneable, lets multiple checkouts share one copy of the
weights, and matches every other project on this machine.

## Core Principles (NON-NEGOTIABLE)

1. **Real files go to `/data/<ProjectName>/...`** — never commit weights into the repo.
2. **The directory that "should" hold weights becomes a symlink** to its `/data` counterpart.
3. **Mirror the existing layout**: inside `/data/<Project>` recreate the *same relative path*
   the project expects (e.g. project `outputs/...` ⇒ `/data/<Project>/outputs/...`).
4. **Always check a precedent first.** Before creating links, inspect how an existing
   project already did it and match the granularity exactly.

## Link granularity — pick to match precedent
There are two established styles. Choose per the project's `.gitignore` / how the
upstream code resolves paths, copying whichever an existing project used:

- **Whole top-level dir** — when the entire dir is artifacts, link the dir itself.
- **Per-subdirectory** — when the parent dir mixes code/config with artifacts, keep the
  parent a real directory and link only the heavy children.

## Procedure

1. **Create the `/data` home** for the real files (`mkdir -p /data/<Project>/...`).
2. **Download** using the project's own script (or manually) into the project as usual.
3. **Relocate** the downloaded files into `/data`, preserving the relative layout.
4. **Symlink** the project path → `/data` path.
5. **Verify** the link resolves and the files are reachable through it.

> If the target project path is *already* a symlink into `/data`, downloads land there
> directly — no relocate step is needed. Just verify afterward.

**Verification is mandatory** — confirm with `ls -la` that (a) the project entry is a
symlink to `/data/<Project>/...` and (b) listing *through* the link shows the real files.

## Reference examples
See `examples/` for concrete, working setups (precedent links, per-project procedures,
and the HMP download case) to copy from.

## Reminders
- Never hardcode or commit account credentials (e.g. HMP account); ask the user and pass via env.
- If a needed parent dir on the project side is a real directory (not a link), keep it real
  and link only the heavy child — matching the per-subdirectory precedent.
- Don't delete or overwrite an existing weights dir without first `ls -la`-ing it; if it
  already resolves into `/data`, the setup is done.
