---
name: hydra-project-structure
description: Initialize or refactor a Python research project into the standard Hydra-driven layout - all essential code under src/, a configs/ tree that mirrors src/ package names, thin scripts/ wrappers, and misc/ for non-essential-but-necessary code (e.g. patches applied into the installed environment). Runner-agnostic (uv / pixi / venv / conda). Use when starting a new experiment/ML/research repo, when asked to "restructure"/"整理"/"リファクタ" an existing one, or when adding a new swappable component that needs a matching config group.
---

# Hydra Project Structure

## Purpose
Give every research/experiment repository the same shape, so that any entry point is
`<RUN> ./src/<entrypoint>.py <group>=<variant> ...`, every swappable component is
selected from the command line, and every run writes a self-describing output directory.

`<RUN>` throughout this skill means "however this project runs Python" — see
**Runner detection** below. It is never assumed to be a particular tool.

## Core Principles (NON-NEGOTIABLE)

1. **`src/` holds all essential code.** Anything the project genuinely needs to run —
   entry points included — lives under `src/`. Nothing importable sits at the repo root.
2. **`configs/` mirrors `src/`.** A swappable package `src/<group>s/` gets a config group
   `configs/<group>/` — **plural package, singular config dir** (`src/agents/` ⇒ `configs/agent/`).
   Names are not invented independently on the two sides; one implies the other.
3. **`misc/` is for the non-essential but necessary.** Usually absent. It exists for code
   that is not part of the project proper yet is required in practice — most commonly files
   that must be dropped into `.venv/` to patch a third-party library for a version mismatch.
4. **Config selects, code implements.** Components are built via Hydra `_target_`
   instantiation, never by `if name == ...` dispatch in the entry point.
5. **`scripts/` are thin.** A shell script is one `<RUN>` invocation plus config overrides,
   and nothing else. See **What "no logic in scripts" means**.

## What "no logic in scripts" means

A `scripts/*.sh` file is a *record of which config combination was run* — readable at a
glance, and fully reproducible from the `.hydra/config.yaml` it produces. Behaviour that
exists only in the shell breaks that. Concretely, do not put in a script:

- **Loops / sweeps** — `for seed in 1 2 3; do ...` becomes Hydra multirun: `-m seed=1,2,3`.
- **Branching** — `if [ "$MODE" = eval ]` becomes a second script, or a config group.
- **Path construction, checkpoint discovery, result aggregation, pre/post-processing** —
  all of this is essential code; it belongs in `src/` behind an entry point or a config value.
- **Inline Python** (`python -c "..."`), `sed`-ing configs, exporting derived variables.

Acceptable in a script: a shebang / `set -euo pipefail`, comments, a fixed device or
env-var export (`export CUDA_VISIBLE_DEVICES=0`), and forwarding `"$@"` so ad-hoc overrides
can be appended on the command line.

## Canonical Layout

```
<project>/
├── configs/                        # Hydra config tree — mirrors src/
│   ├── <entrypoint>.yaml           # one per entry point: train.yaml <-> src/train.py
│   ├── hydra/default.yaml          # run/sweep output dirs, job logging
│   ├── logger/<impl>.yaml          # loguru.yaml
│   ├── <group>/<variant>.yaml      # SINGULAR dir, one file per variant module
│   └── ...
├── src/                            # ALL essential code
│   ├── <entrypoint>.py             # @hydra.main entry point (train.py, evaluate.py, ...)
│   ├── <group>s/                   # PLURAL package
│   │   ├── __init__.py
│   │   ├── base.py                 # ABC / shared interface for the group
│   │   └── <variant>.py            # one module per config file in configs/<group>/
│   └── utils/                      # helpers with no swappable variants
├── scripts/                        # thin wrappers: <entrypoint>_<variant>_<variant>.sh
├── misc/                           # optional; see Principle 3
├── logs/                           # Hydra run/sweep outputs (gitignored)
├── pyproject.toml                  # or pixi.toml / requirements.txt — see Runner detection
├── ruff.toml
├── .pre-commit-config.yaml
├── .gitignore
└── README.md
```

### The mirroring rule, precisely

| src/ | configs/ | `_target_` in the yaml |
|------|----------|------------------------|
| `src/agents/ppo.py` → `PPOAgent` | `configs/agent/ppo.yaml` | `src.agents.ppo.PPOAgent` |
| `src/environments/gymnax_wrapper.py` | `configs/environment/pendulum.yaml` | `src.environments.gymnax_wrapper.GymnaxWrapper` |
| `src/networks/actor_critic.py` | `configs/network/actor_critic.yaml` | `src.networks.actor_critic.GaussianActor` |
| `src/train.py` | `configs/train.yaml` | — (entry point config) |

- **Group dir name**: strip the trailing `s` from the `src/` package (`agents`→`agent`,
  `networks`→`network`, `buffers`→`buffer`). Non-`s` plurals keep a sensible singular.
- **File name**: named after the *variant a user selects*, which is usually the module name
  (`ppo.py` ⇒ `ppo.yaml`). When one module serves several presets (one wrapper class, many
  envs), the config file is named after the preset (`pendulum.yaml`, `cartpole.yaml`) and
  several files share a `_target_`. This is the only allowed asymmetry.
- **No config group for helper-only packages.** `src/utils/`, `src/estimators/` and similar
  are imported directly and have nothing to select — do not manufacture an empty group.
  (Exception: a helper that *is* configurable, e.g. the logger, gets its own group.)
- **Entry points**: `configs/<name>.yaml` ⇄ `src/<name>.py`, matched by
  `@hydra.main(config_path="../configs", config_name="<name>")`.

## Hydra Conventions

- Entry-point config starts with a `defaults:` list naming one variant per group, then
  `- hydra: default` and `- _self_` last.
- Shared values are declared once and interpolated: `seed: ${seed}` inside a group config,
  `optimizer_cfg: ${optimizer}` to hand a whole group to a component,
  `${hydra:runtime.choices.<group>}` for run naming/tags.
- `_recursive_: False` on components that want to instantiate their own sub-configs.
- A `path:` block exposes Hydra's dirs to the code so nothing hardcodes paths:
  ```yaml
  path:
    work_dir: ${hydra:runtime.cwd}
    run_dir:  ${hydra:runtime.output_dir}
    log_dir:  "logs"
    ckpt_dir: "ckpt"
  ```
- `configs/hydra/default.yaml` sends every run to
  `logs/<job_name>/runs/<date>/<time>/` and every sweep to `logs/<job_name>/multiruns/...`,
  so outputs are grouped by entry point. `logs/` is gitignored.

## Runner detection

**Never assume a package manager.** Detect it once, at the start of the task, and use the
matching `<RUN>` prefix everywhere (scripts, verification commands, README):

| evidence in repo | `<RUN>` | install / add deps |
|---|---|---|
| `uv.lock`, or `[tool.uv]` in `pyproject.toml` | `uv run` | `uv sync` / `uv add <pkg>` |
| `pixi.toml`, `pixi.lock`, or `[tool.pixi]` | `pixi run python` | `pixi install` / `pixi add <pkg>` |
| plain `.venv/` + `requirements.txt` / bare `pyproject.toml` | `python` (venv assumed active) | `pip install -r requirements.txt` |
| conda `environment.yml` | `conda run -n <env> python` | `conda env update -f environment.yml` |
| nothing (new project) | **ask the user** which they want | — |

- When refactoring, keep whatever the project already uses. Switching package managers is a
  separate decision that belongs to the user, not to a restructuring pass.
- If a `.venv/` exists but the manager is ambiguous, ask rather than guessing — the wrong
  prefix in `scripts/` silently runs against the wrong interpreter.
- Whichever runner is chosen, use it consistently in every script and in the README, so a
  single project never mixes prefixes.

## Tooling Baseline

Runner-independent: `hydra-core` + `omegaconf` · `loguru` for logging · `ruff.toml` +
`.pre-commit-config.yaml` running `ruff-format` and `ruff --fix`.
Add `pyinstrument` when the entry point exposes a `profile:` flag.
Declare dependencies in whatever manifest the detected runner owns; commit the lockfile
if the runner produces one.

## Mode A — Initialize a new project

1. **Ask for the domain vocabulary first.** Which entry points (`train`, `evaluate`, …) and
   which swappable component groups exist. Do not invent groups the user has not asked for —
   an empty group directory is worse than none.
2. **Ask which runner** to use (uv / pixi / plain venv / conda) — see **Runner detection**.
3. Scaffold the layout above; copy from `templates/` and substitute names, including `<RUN>`.
4. Initialize the manifest with the chosen runner, add deps, copy `ruff.toml`,
   `pre-commit-config.yaml` → `.pre-commit-config.yaml`, `gitignore` → `.gitignore`
   (add the runner's own ignores, e.g. `.pixi/`).
5. Write one `base.py` per group and one working variant, so the tree runs end to end.
6. Add one `scripts/<entrypoint>_<variants>.sh`.
7. **Verify**: `<RUN> ./src/<entrypoint>.py --cfg job` resolves without error, and
   `--help` lists every config group.

## Mode B — Refactor an existing project

0. **Detect the runner** and keep it — do not migrate the project to a different one.
1. **Inventory** — list every `.py` outside `src/`, every existing config file, and how
   components are currently selected (argparse? `if`-dispatch? hardcoded?).
2. **Map** — build the move table before touching anything:

   | current path | target path | new config file | notes |
   |---|---|---|---|

   Classify each file as: essential (→ `src/`), thin runner (→ `scripts/`),
   non-essential-but-needed (→ `misc/`), or dead (→ propose deletion, never delete silently).
3. **Confirm the table with the user** when it renames packages, moves more than a handful
   of files, or when a file's classification is ambiguous. Apply the rest without asking.
4. **Apply**, in this order, verifying imports after each step:
   - `git mv` files into `src/` (history-preserving; never copy-and-delete).
   - Rename packages to the plural convention; add `__init__.py`.
   - Update every import to the `src.<group>s.<module>` form.
   - Create `configs/<group>/<variant>.yaml` with `_target_` for each component, hoisting
     the constructor arguments that were previously hardcoded.
   - Convert the entry point to `@hydra.main` + `hydra.utils.instantiate`, deleting the
     old dispatch code.
   - Rewrite runners as thin `scripts/*.sh`.
5. **Verify** — `--cfg job` for each entry point, then one short real run per script.
6. Update the `README.md` project-structure section to match the tree.

## Mode C — Add a new variant to an existing project

Adding an algorithm/environment/network is always the same three-to-four files:
`src/<group>s/<variant>.py` (subclassing the group's `base.py`) →
`configs/<group>/<variant>.yaml` (with `_target_`, and `${...}` interpolations for shared
values) → optional `scripts/<entrypoint>_<variant>.sh` → README table row.
If a new variant needs a differently-shaped sibling config (e.g. a new optimizer layout),
add that file to the sibling group too rather than special-casing inside the code.

## Templates

`templates/` holds ready-to-copy files; substitute the `<placeholder>` names — including
`<RUN>`, which the detected runner fills in. Files:
`configs/entrypoint.yaml`, `configs/hydra/default.yaml`, `configs/logger/loguru.yaml`,
`configs/group/variant.yaml`, `src/entrypoint.py`, `src/utils/logger.py`,
`scripts/run.sh`, `ruff.toml`, `pre-commit-config.yaml`, `gitignore`.

## Reminders

- Never leave importable code at the repo root — that is the failure this skill exists to fix.
- Never hardcode `uv run` (or any single runner) into a project that does not use it.
- Do not create `misc/` speculatively; create it the moment there is a real environment patch
  (`.venv/`, `.pixi/envs/`, site-packages) or similar side-artifact, and document in the
  README how it is applied.
- Do not add try/except around instantiation. A wrong config must fail loudly.
- Keep the diff minimal: move and rewire, do not rewrite component internals while
  restructuring. Behavioral changes belong in a separate pass.
