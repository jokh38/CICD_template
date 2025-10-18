# Development Scripts

This directory contains scripts for creating and managing development projects.

## Directory Structure

```
scripts/
├── linux/                          # Linux-specific installation and configuration scripts
│   ├── core/                       # Core system dependencies
│   ├── tools/                      # Development tools installation
│   ├── config/                     # Configuration setup scripts
│   └── validation/                 # Validation and testing scripts
├── windows/                        # Windows-specific installation and configuration scripts
│   ├── core/                       # Core system dependencies
│   ├── tools/                      # Development tools installation
│   ├── config/                     # Configuration setup scripts
│   └── validation/                 # Validation and testing scripts
├── create-project.sh               # Main project creation script (Unix/Linux/macOS)
├── total_validation.sh             # Project validation script (Unix/Linux/macOS)
└── total_validation.ps1            # Project validation script (Windows)
```

## Quick Start

### 1. Create a New Project

```bash
# Create a Python project
bash scripts/create-project.sh python my-project

# Create a C++ project
bash scripts/create-project.sh cpp my-cpp-project

# Create with GitHub repository
bash scripts/create-project.sh python my-project --github
```

The `create-project.sh` script will:
- Generate a new project from cookiecutter template
- Auto-detect the project type (Python or C++)
- **Automatically install required development tools**
- Set up git configuration
- Set up code formatting tools
- Optionally create a GitHub repository

### 2. Validate Your Project

After creating a project, navigate to the project directory and run validation:

**Linux/macOS:**
```bash
cd my-project
bash /path/to/CICD_template/scripts/total_validation.sh
```

**Windows:**
```powershell
cd my-project
pwsh /path/to/CICD_template/scripts/total_validation.ps1
```

The validation script will:
- Auto-detect the project type
- Test that all required tools are installed
- Verify that code formatting tools work correctly
- Check that the project structure is correct
- **Test actual project files** (not dummy test files)

## Workflow

### Old Workflow (deprecated)
```
create project manually → run total_run.sh → validate manually
```

### New Workflow
```
run create-project.sh → tools auto-installed → run total_validation.sh
```

## Scripts Overview

### create-project.sh
**Purpose**: Create a new project from templates with automatic tool installation

**Usage**:
```bash
./create-project.sh <language> [project-name] [--github]
```

**Features**:
- Automatic project type detection
- Automatic tool installation based on project type
- Git repository initialization
- Optional GitHub repository creation
- Configuration setup

**Example**:
```bash
# Create Python project with tools
./create-project.sh python my-awesome-app

# Create C++ project with GitHub repo
./create-project.sh cpp my-fast-lib --github
```

### total_validation.sh
**Purpose**: Validate the development environment setup in a project directory

**Usage**:
```bash
# Run from within a project directory
./total_validation.sh [OPTIONS]
```

**Options**:
- `--python-only`: Validate only Python tools
- `--cpp-only`: Validate only C++ tools
- `--system-only`: Validate only system tools
- (no option): Auto-detect and validate

**Features**:
- Auto-detects project type from current directory
- Tests actual project files (not just dummy files)
- Validates tool installation
- Checks code formatting and linting
- Verifies test framework setup

**Example**:
```bash
# Auto-detect and validate
cd my-project
bash ../scripts/total_validation.sh

# Validate Python-only
bash ../scripts/total_validation.sh --python-only
```

## Linux Scripts

### Core Scripts (`linux/core/`)
- `install-system-deps.sh`: Install system-level dependencies

### Tools Scripts (`linux/tools/`)
- `install-python-tools.sh`: Install Python development tools (ruff, pytest, mypy, etc.)
- `install-compilers.sh`: Install C++ compilers (gcc, clang)
- `install-build-tools.sh`: Install build tools (cmake, ninja, make)
- `install-cpp-frameworks.sh`: Install C++ testing frameworks (GTest, Catch2)
- `install-cpp-pkg-managers.sh`: Install C++ package managers (conan, vcpkg)
- `install-sccache.sh`: Install sccache for faster builds

### Config Scripts (`linux/config/`)
- `setup-git-config.sh`: Configure git with user info and defaults
- `setup-code-formatting.sh`: Set up code formatting configurations
- `setup-ai-workflows.sh`: Set up AI workflow templates

### Validation Scripts (`linux/validation/`)
- `final-validation.sh`: Comprehensive validation of development environment
- `run-validation.sh`: Run validation tests
- `create-test-projects.sh`: Create test projects for validation

## Migration Guide

If you have existing `setup-scripts/` usage, update your scripts:

### Before
```bash
sudo bash setup-scripts/total_run.sh
```

### After
```bash
# For project creation (includes installation)
bash scripts/create-project.sh python my-project

# For validation only
bash scripts/total_validation.sh
```

## Important Notes

1. **Project Creation**: Always use `create-project.sh` to create new projects - it handles tool installation automatically

2. **Validation**: Run `total_validation.sh` from within your project directory to validate the setup

3. **Tool Installation**: Development tools are now installed automatically during project creation

4. **Ruff Errors**: The `.ruffignore` file in the repository root excludes cookiecutter templates from linting

5. **Permissions**: Some installations may require sudo privileges - the scripts will prompt when needed

## Troubleshooting

### "Ruff linting check failed"
- Ensure you're running validation from within a project directory
- Check that the project has a `src/` directory with Python files
- Verify that `.ruffignore` excludes cookiecutter templates

### "Could not locate scripts directory"
- Ensure you're running the script from the correct location
- Use absolute paths if necessary
- Check that `linux/` subdirectory exists

### "Failed to install tools"
- Check that you have sudo privileges if required
- Verify internet connection for package downloads
- Review the error messages for specific package issues

## See Also

- [Cookiecutter Templates](../cookiecutters/README.md)
- [Setup Scripts Documentation](../setup-scripts/README.md) (legacy)
- [Project Templates](../README.md)
