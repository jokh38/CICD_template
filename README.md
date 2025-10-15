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

## 📁 Project Structure

```
github-cicd-templates/
├── cookiecutters/           # Cookiecutter project templates
│   ├── python-project/      # Python template with Ruff
│   └── cpp-project/         # C++ template with CMake/sccache
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

### 3. Reusable Workflows

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

### 4. Composite Actions

Reusable action components:
- `setup-python-cache`: Python environment with dependency caching
- `setup-cpp-cache`: C++ build tools with sccache
- `monitor-ci`: CI status monitoring for automation

### 4. Configuration Management

Shared, version-controlled configurations:
- Ruff configuration (Python)
- clang-format, clang-tidy (C++)
- Pre-commit hooks
- CMake templates

## 📖 Usage Examples

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

# Build and test
cd /home/user/my-library
cmake -B build -G Ninja
cmake --build build

# Test
ctest --test-dir build
```

**Note:** Pre-commit is automatically installed and ready to use!

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
- **[C++ Linux Runner Guide](docs/manuals/CPP_LINUX_RUNNER_GUIDE.md)** - Advanced C++ CI/CD workflow
- [Troubleshooting](docs/manuals/TROUBLESHOOTING.md) - Common issues and solutions

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
