---
name: project-documentation-mapper
description: Read existing project documents and generate a structured markdown documentation map under docs/ so Claude can later explore the repository efficiently. Supports documenting the whole project or specific directories/files.
---

# Project Documentation Mapper

## Purpose

This skill helps Claude create persistent, navigation-friendly documentation for a codebase.
It reads existing documentation first, then generates markdown files under `docs/` that describe the repository structure and the purpose of important directories and files.
The output is intended to help future repository exploration.

## When to use

Use this skill when the user wants to:
- document the overall structure of a repository
- create or update `docs/` for future navigation
- generate a directory map of the project
- add documentation for a specific directory or file
- leave exploration notes for future Claude sessions

## Inputs

The user may optionally provide:
- a project root path
- one or more directory paths
- one or more file paths
- a scope such as whole project, selected directories, or selected files only

## Core behavior

### 1. Read existing documentation first

Before writing new docs, inspect existing top-level documentation such as:
- `README.md`
- `README`
- `docs/`
- onboarding or architecture docs
- contribution guides
- setup instructions
- package manifests if useful for understanding structure

Prioritize human-written overview documents before inferring structure from code.

### 2. Respect ignore rules

Before scanning or documenting files, read repository ignore rules and skip ignored content.
At minimum, use `.gitignore` as an exclusion source.
Do not include files or directories ignored by `.gitignore` in the generated documentation unless the user explicitly asks for them.
If multiple ignore files or equivalent exclusion rules exist and are easy to identify, respect them as well.

### 3. Check whether `docs/` already exists

- If `docs/` does not exist, create it.
- If `docs/` already exists, do not overwrite its structure blindly.
- First summarize what is already present and consult the user before making large structural changes.
- Small additive updates are allowed when clearly requested.

### 4. Create a top-level project map under `docs/`

Create a top-level markdown document under `docs/` that acts as a navigation map for the repository.
Suggested filename:
- `docs/project-map.md`

This file should include:
- the repository purpose in 2 to 6 lines
- major top-level directories
- what each directory is for
- important entry points
- important config files
- key scripts or executables
- notes on where implementation, experiments, assets, tests, and docs live

Prefer concise navigation-oriented descriptions over long prose.

### 5. Mirror project structure in `docs/` when needed

If additional detail is needed, create subdirectories under `docs/` that mirror the project structure.
Examples:
- project directory `src/models/` -> doc path `docs/src/models/overview.md`
- project directory `scripts/` -> doc path `docs/scripts/overview.md`
- project file `src/train.py` -> doc path `docs/src/train.md`

Create mirrored documentation only for areas that are important, complex, requested by the user, or insufficiently explained by the top-level map.
Do not document every trivial file unless explicitly requested.

### 6. Handle additional path arguments

If the user provides a directory path or file path:
- document only the requested target unless the user asks for broader coverage
- create the corresponding markdown file under `docs/`
- preserve path correspondence as much as possible

Examples:
- input: `src/agents/` -> output: `docs/src/agents/overview.md`
- input: `configs/train.yaml` -> output: `docs/configs/train.yaml.md` or `docs/configs/train.md`

When choosing filenames, prefer readable names while keeping the mapping obvious.

## Output format rules

- Use markdown only.
- Use short sections and bullet lists where helpful.
- Keep descriptions factual and repository-specific.
- Avoid inventing intent when evidence is weak. Mark uncertainty explicitly.
- Prefer explaining role, dependencies, and relationships over repeating code.
- Do not dump full source code into docs.

## Recommended document templates

### Template for `docs/project-map.md`

```md
# Project Map

## Overview
Short summary of the repository purpose and main workflow.

## Top-level Structure
- `src/`: core implementation
- `configs/`: configuration files
- `scripts/`: utility and execution scripts
- `tests/`: test suite
- `docs/`: project documentation

## Main Entry Points
- `train.py`: training entry point
- `evaluate.py`: evaluation entry point

## Important Config and Metadata
- `pyproject.toml`: packaging and dependencies
- `README.md`: high-level introduction

## Notes
- Where experiments are defined
- Where generated artifacts are stored
- Which directories are incomplete or unclear
```