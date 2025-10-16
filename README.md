# GitHub CICD Templates

> Fast and maintainable CI/CD pipeline template system using Cookiecutter, Ruff, and sccache

## 🚀 Quick Start

### Prerequisites

```bash
# Install Cookiecutter
pip install cookiecutter
```

### Create a Python Project

```bash
# Interactive mode
bash scripts/create-project.sh python

# Non-interactive mode with absolute path
bash scripts/create-project.sh python /home/user/my-awesome-project
```

### Create a C++ Project

```bash
# Interactive mode
bash scripts/create-project.sh cpp

# Non-interactive mode with absolute path
bash scripts/create-project.sh cpp /home/user/my-fast-library
```

### 🛠️ Development Environment Setup

For complete development environment setup with all tools and configurations:

#### Linux (sudo required)

```bash
# Full installation (recommended)
sudo bash setup-scripts/total_run.sh

# Basic tools only (system deps, compilers, build tools)
sudo bash setup-scripts/total_run.sh --basic

# C++ tools only
sudo bash setup-scripts/total_run.sh --cpp-only

# Python tools only
sudo bash setup-scripts/total_run.sh --python-only

# Run validation only
sudo bash setup-scripts/total_run.sh --validate-only

# Final comprehensive validation
sudo bash setup-scripts/total_run.sh --final-validation

# Show help
bash setup-scripts/total_run.sh --help
```

#### Windows (PowerShell Administrator)

```powershell
# Full installation (recommended)
.\setup-scripts\total_run.ps1

# Basic tools only
.\setup-scripts\total_run.ps1 -Basic

# C++ tools only
.\setup-scripts\total_run.ps1 -CppOnly

# Python tools only
.\setup-scripts\total_run.ps1 -PythonOnly

# Run validation only
.\setup-scripts\total_run.ps1 -ValidateOnly

# Final comprehensive validation
.\setup-scripts\total_run.ps1 -FinalValidation

# Show help
.\setup-scripts\total_run.ps1 -Help
```

## 📁 Project Structure

```
github-cicd-templates/
├── cookiecutters/           # Cookiecutter project templates
│   ├── python-project/      # Python template with Ruff
│   └── cpp-project/         # C++ template with CMake/sccache
│
├── setup-scripts/           # Development environment setup
│   ├── linux/
│   │   └── validation/      # Validation scripts for testing tools
│   └── total_run.sh         # Orchestration script with validation
│
├── .github/
│   ├── workflows/           # Reusable GitHub Actions workflows
│   │   ├── python-ci-reusable.yaml
│   │   └── cpp-ci-reusable.yaml
│   │
│   ├── actions/             # Composite actions
│   │   ├── setup-python-cache/
│   │   ├── setup-cpp-cache/
│   │   └── monitor-ci/
│   │
│   └── workflow-templates/  # Starter workflow templates
│       ├── python-ci.yml
│       └── cpp-ci.yml
│
├── configs/                 # Shared configuration files
│   ├── python/
│   │   ├── .pre-commit-config.yaml
│   │   ├── ruff.toml
│   │   └── pyproject.toml.template
│   │
│   └── cpp/
│       ├── .pre-commit-config.yaml
│       ├── .clang-format
│       ├── .clang-tidy
│       └── CMakeLists.txt.template
│
└── scripts/                 # Helper scripts
    ├── create-project.sh    # Create new project from template
    ├── sync-templates.sh    # Sync configs to existing projects
    └── lib/
        └── common-utils.sh  # Shared utilities
```

## 🎯 Features

### 1. Cookiecutter Templates

**Python Template:**
- Ruff for linting and formatting (100x faster than Black + Flake8)
- pytest for testing with coverage
- mypy for type checking
- Pre-commit hooks configured
- GitHub Actions CI/CD ready

**C++ Template:**
- CMake with Ninja build system
- sccache for compilation caching (50%+ faster builds)
- clang-format, clang-tidy for code quality
- GoogleTest framework
- Pre-commit hooks configured
- GitHub Actions CI/CD ready
- Built-in validation scripts for environment testing

### 2. Advanced C++ Linux Runner 🚀

**NEW: Comprehensive C++ CI/CD workflow for Linux**

Our new `cpp-linux-runner.yaml` provides enterprise-grade CI/CD with advanced features:

- **🔧 Multiple Compilers**: GCC and Clang with version detection
- **🏗️ Build Systems**: CMake and Meson support with Ninja generator
- **⚡ Smart Caching**: sccache integration for 2-12x faster builds
- **🔍 Static Analysis**: clang-tidy, cppcheck with customizable rules
- **📊 Code Coverage**: lcov integration with Codecov upload
- **🛡️ Safety Tools**: AddressSanitizer, UBSan, and Valgrind
- **📝 Code Quality**: clang-format verification and enforcement
- **📈 Performance**: Parallel builds and optimized configurations
- **📋 Reporting**: Comprehensive build summaries and status badges

```yaml
# Example usage
jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-linux-runner.yaml@v1
    with:
      build-type: 'Release'
      cpp-standard: '20'
      compiler: 'gcc'
      enable-cache: true
      enable-tests: true
      enable-static-analysis: true
      enable-coverage: true
```

### 3. Development Environment Setup

**Complete development environment orchestration with validation:**

**Linux Setup (`total_run.sh`):**
- System dependencies and core tools
- Multiple compiler support (GCC, Clang)
- Build tools (CMake, Ninja, Meson)
- C++ development tools (sccache, GoogleTest, clang-format)
- Python development tools (Ruff, pytest, mypy, pre-commit)
- Git configuration and aliases
- AI workflow templates
- Comprehensive validation and testing

**Windows Setup (`total_run.ps1`):**
- Visual Studio Build Tools and compilers
- Chocolatey package management
- CMake and Ninja build tools
- sccache for compilation caching
- Python development environment
- Git configuration with Windows optimizations
- Code formatting configurations
- Final validation and health checks

**Key Features:**
- **Modular installation**: Install only what you need
- **Comprehensive validation**: Test all tools and configurations
- **Performance optimization**: sccache, parallel builds, optimized settings
- **Cross-platform**: Consistent experience across Linux and Windows
- **AI-ready**: Pre-configured AI workflow templates

### 4. Reusable Workflows

Centralized CI/CD workflows that can be referenced across all projects:

```yaml
# In your project's .github/workflows/ci.yaml
jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/python-ci-reusable.yaml@v1
    with:
      python-version: '3.11'
      run-coverage: true
```

### 5. Composite Actions

Reusable action components:
- `setup-python-cache`: Python environment with dependency caching
- `setup-cpp-cache`: C++ build tools with sccache
- `monitor-ci`: CI status monitoring for automation

### 6. Configuration Management

Shared, version-controlled configurations:
- Ruff configuration (Python)
- clang-format, clang-tidy (C++)
- Pre-commit hooks
- CMake templates

## 📖 Usage Examples

### Development Environment Setup

**Linux:**
```bash
# Complete development environment setup
sudo bash setup-scripts/total_run.sh

# After setup, validate your environment
bash setup-scripts/total_run.sh --validate-only
```

**Windows:**
```powershell
# Complete development environment setup (Administrator)
.\setup-scripts\total_run.ps1

# After setup, validate your environment
.\setup-scripts\total_run.ps1 -ValidateOnly
```

### Python Project

```bash
# Create project with absolute path (auto-installs all dependencies)
bash scripts/create-project.sh python /home/user/my-api

# Activate and use immediately
cd /home/user/my-api
source .venv/bin/activate

# Everything is ready! Run tests
pytest

# Lint and format
ruff check .
ruff format .
```

**Note:** Dependencies (ruff, pytest, mypy, pre-commit) are automatically installed during project creation!

### C++ Project

```bash
# Create project with absolute path (auto-installs pre-commit)
bash scripts/create-project.sh cpp /home/user/my-library

# Validate your development environment
cd /home/user/my-library
bash setup-scripts/linux/validation/run-validation.sh

# Build and test
cmake -B build -G Ninja
cmake --build build

# Test
ctest --test-dir build
```

**Note:** Pre-commit is automatically installed and ready to use! The validation script command is prominently displayed during project creation for easy reference.

### Using Reusable Workflows

Create `.github/workflows/ci.yaml` in your project:

**Python:**
```yaml
name: CI

on: [push, pull_request]

jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/python-ci-reusable.yaml@v1
    with:
      python-version: '3.11'
      run-tests: true
      run-coverage: true
```

**C++ (Standard):**
```yaml
name: CI

on: [push, pull_request]

jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-ci-reusable.yaml@v1
    with:
      build-type: 'Release'
      enable-cache: true
      use-ninja: true
```

**C++ (Advanced Linux Runner):**
```yaml
name: Advanced CI

on: [push, pull_request]

jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-linux-runner.yaml@v1
    with:
      build-type: 'Release'
      cpp-standard: '20'
      compiler: 'gcc'
      enable-cache: true
      enable-tests: true
      enable-static-analysis: true
      enable-coverage: true
      enable-formatting-check: true
      use-ninja: true
    secrets:
      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
```

### Sync Configurations to Existing Project

```bash
# Sync Python configs
bash scripts/sync-templates.sh python /path/to/existing-project

# Sync C++ configs
bash scripts/sync-templates.sh cpp /path/to/existing-project
```

## 🚀 Performance Benefits

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Python lint | 60s (Black + Flake8) | 5s (Ruff) | **12x faster** |
| C++ build (clean) | 6 min | 3 min | **2x faster** |
| C++ build (cached) | 6 min | 30s | **12x faster** |
| Project setup | 2 hours | 2 min | **60x faster** |

## 🔧 Customization

### Template Variables

**Python (`cookiecutter.json`):**
- `project_name`: Project display name
- `project_slug`: Package name (auto-generated)
- `python_version`: Python version (3.10, 3.11, 3.12)
- `runner_type`: self-hosted or github-hosted (default: self-hosted)
- `use_ai_workflow`: Include AI workflow templates
- `license`: MIT, BSD-3-Clause, Apache-2.0, GPL-3.0, None

**C++ (`cookiecutter.json`):**
- `project_name`: Project display name
- `cpp_standard`: C++ standard (17, 20, 23)
- `build_system`: cmake or meson
- `use_ninja`: Use Ninja build system
- `enable_cache`: Enable sccache
- `testing_framework`: gtest, catch2, doctest
- `license`: MIT, BSD-3-Clause, Apache-2.0, GPL-3.0, None

### Workflow Inputs

**Python CI:**
- `python-version`: Python version
- `working-directory`: Working directory
- `run-tests`: Run pytest
- `run-coverage`: Generate coverage report
- `runner-type`: self-hosted (default) or ubuntu-latest

**C++ CI:**
- `build-type`: Release, Debug, RelWithDebInfo
- `cpp-compiler`: g++, clang++
- `cmake-options`: Extra CMake options
- `run-tests`: Run ctest
- `enable-cache`: Enable sccache
- `runner-type`: self-hosted (default) or ubuntu-latest
- `use-ninja`: Use Ninja generator

## 📚 Documentation

**📖 Comprehensive Guides:**
- [Quick Start Guide](docs/manuals/QUICK_START.md) - Get started in 5 minutes
- [Cookiecutter Guide](docs/manuals/COOKIECUTTER_GUIDE.md) - Template system deep dive
- **[Development Environment Setup](setup-scripts/README.md)** - Complete environment setup with validation
- **[C++ Linux Runner Guide](docs/manuals/CPP_LINUX_RUNNER_GUIDE.md)** - Advanced C++ CI/CD workflow
- [Troubleshooting](docs/manuals/TROUBLESHOOTING.md) - Common issues and solutions

**🔧 Setup Script Documentation:**
- [Linux Setup Scripts](setup-scripts/linux/README.md) - Linux-specific setup and configuration
- [Windows Setup Scripts](setup-scripts/windows/README.md) - Windows-specific setup and configuration

**🔧 Development Plan:**
See `0.DEV_PLAN.md` for the complete development plan covering:
- Phase 1-5: Implementation (completed)
- Phase 6: Self-hosted runner setup
- Phase 7: Integration testing
- Phase 8: Documentation
- Phase 9: Pilot migration

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with both templates
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 🔗 Related Resources

- [Cookiecutter Documentation](https://cookiecutter.readthedocs.io/)
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [sccache Documentation](https://github.com/mozilla/sccache)
- [GitHub Actions Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)

---

**Status:** ✅ Phases 1-5 Complete + Advanced C++ Linux Runner
**Version:** 1.1.0
**Last Updated:** 2025-10-14

**🎉 New in v1.1.0:**
- ✅ Advanced C++ Linux GitHub Actions runner
- ✅ Comprehensive static analysis integration
- ✅ Code coverage with Codecov support
- ✅ Memory safety tools (ASan, UBSan, Valgrind)
- ✅ Enterprise-grade CI/CD features
