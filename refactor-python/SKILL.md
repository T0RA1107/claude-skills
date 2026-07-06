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

### 2. Import Organization
- **All imports must be at the top of the file**, immediately after the module docstring and any `__future__` imports. Never place `import` or `from ... import` statements inside functions, methods, or conditionals.
- Exception: imports that must be deferred due to side-effect ordering (e.g., setting `os.environ` before an import that reads it at load time) should be placed as high as possible and accompanied by a comment explaining why.
- Group imports in standard order: standard library → third-party → local, separated by blank lines.

### 3. Structural Integrity (DRY Principle)
- Identify and eliminate code duplication.
- Extract repeated logic into reusable functions or methods.
- Simplify complex conditional logic to enhance readability.

### 4. Type Safety & Documentation
- **Type Hinting**: Add comprehensive Python type hints to all function signatures and class variables. Use `typing` or built-in generic types (Python 3.9+).
- **English Documentation**: All docstrings, comments, and log messages must be written in **English**. Follow the Google or NumPy docstring format.

### 5. Modern Logging
- **Migrate to `loguru`**: Replace standard `logging` or `print` statements with `loguru`.
- Use appropriate log levels: `logger.info()`, `logger.debug()`, `logger.error()`, etc.
- Remove old `import logging` statements.

### 6. Module Splitting for Oversized Files
- **Consider splitting** a file into multiple modules when it grows too long (rough guideline: **~300 lines**). A single overlong file mixing several concerns is harder to navigate and test.
- **Caveat — judge reusability before extracting**: Only split out code that is genuinely reusable or represents a cohesive, self-contained concern. Avoid carving out narrow, single-use modules just to reduce line count — a module that is only ever imported by one caller and has no general applicability usually belongs alongside that caller.
- When in doubt about whether an extraction is worth it, keep the code in place or **ask the user** rather than creating a low-value module.

### 7. Automated Formatting & Linting
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
