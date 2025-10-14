# AI Assistant Workflow Guide

This document provides guidance for AI assistants (like Claude) working on this project.

## Project Overview

**Project**: {{cookiecutter.project_name}}
**Description**: {{cookiecutter.project_description}}
**Language**: Python {{cookiecutter.python_version}}}

## Development Setup

The project uses a virtual environment with all dependencies pre-installed:

```bash
# Activate virtual environment
source .venv/bin/activate

# Run tests
pytest

# Lint code
ruff check .

# Type checking
mypy src/

# Format code
ruff format .
```

## Code Style Guidelines

- Use `ruff` for linting and formatting
- Follow PEP 8 style guidelines
- Include type hints for all functions
- Write docstrings for all modules and functions
- Maintain test coverage with `pytest`

## Testing

- Tests are located in the `tests/` directory
- Use `pytest` for running tests
- Test files should be named `test_*.py`
- Aim for high test coverage

## Project Structure

```
{{cookiecutter.project_slug}}/
├── src/{{cookiecutter.project_slug}}/    # Main package
├── tests/                                # Test files
├── pyproject.toml                        # Project configuration
├── README.md                             # Project documentation
└── .github/workflows/                    # CI/CD workflows
```

## Working with this Project

When making changes:

1. Always run tests before committing: `pytest`
2. Check code style: `ruff check .`
3. Format code: `ruff format .`
4. Run type checking: `mypy src/`

## Pre-commit Hooks

Pre-commit hooks are installed to ensure code quality:
- Linting with ruff
- Type checking with mypy
- Test execution

The hooks will run automatically on each commit.