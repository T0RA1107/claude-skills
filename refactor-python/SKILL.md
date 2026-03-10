---
name: refactor-python
description: Refactor Python code to modern standards using pathlib, loguru, type hints, and English docstrings, followed by Ruff formatting.
---

# Refactor Python Skill

## Purpose
This skill refactors Python source code to improve maintainability, type safety, and consistency with modern tooling (uv/pixi) and best practices.

## Transformation Rules (Ordered by Execution)

### 1. Modern Path Handling
- **Mandatory Use of `pathlib`**: Replace all occurrences of `os.path` and string-based path manipulations with `pathlib.Path` objects.
- Ensure all file system operations (joining, checking existence, globbing) use `pathlib` methods.

### 2. Structural Integrity (DRY Principle)
- Identify and eliminate code duplication.
- Extract repeated logic into reusable functions or methods.
- Simplify complex conditional logic to enhance readability.

### 3. Type Safety & Documentation
- **Type Hinting**: Add comprehensive Python type hints to all function signatures and class variables. Use `typing` or built-in generic types (Python 3.9+).
- **English Documentation**: All docstrings, comments, and log messages must be written in **English**. Follow the Google or NumPy docstring format.

### 4. Modern Logging
- **Migrate to `loguru`**: Replace standard `logging` or `print` statements with `loguru`.
- Use appropriate log levels: `logger.info()`, `logger.debug()`, `logger.error()`, etc.
- Remove old `import logging` statements.

### 5. Automated Formatting & Linting
- Identify the project's package manager by checking for `uv.lock`/`pyproject.toml` or `pixi.toml`.
- **Ruff Execution**: Run Ruff to fix linting issues and format the code.
  - If the project uses **uv**: Use `uvx ruff check --fix` and `uvx ruff format`.
  - If the project uses **pixi**: Use `pixi exec ruff check --fix` and `pixi exec ruff format`.
  - Fallback to `ruff` if neither is explicitly detected.

## Workflow
1. **Analyze**: Read the target file(s) and identify violations of the rules above.
2. **Apply**: Rewrite the code logic (Pathlib, DRY, Types, Loguru).
3. **Document**: Update or generate English docstrings.
4. **Finalize**: Execute the Ruff formatting command based on the environment detection.
5. **Verify**: Ensure the code remains functional and passes basic syntax checks.
