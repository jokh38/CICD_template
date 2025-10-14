# Troubleshooting Guide

This guide helps you resolve common issues when using the CI/CD template system.

---

## Table of Contents

- [Cookiecutter Issues](#cookiecutter-issues)
- [Pre-commit Issues](#pre-commit-issues)
- [Python Project Issues](#python-project-issues)
- [C++ Project Issues](#c-project-issues)
- [GitHub Actions Issues](#github-actions-issues)
- [Self-Hosted Runner Issues](#self-hosted-runner-issues)
- [General Issues](#general-issues)

---

## Cookiecutter Issues

### "cookiecutter: command not found"

**Problem:** Cookiecutter is not installed or not in PATH.

**Solution:**
```bash
# Install with pip
pip install cookiecutter

# Or with pipx (recommended)
pipx install cookiecutter

# Verify installation
cookiecutter --version
```

**Alternative:** Use pip3 or python3 -m pip if pip is not available.

---

### "Template not found" or "Repository not found"

**Problem:** Cannot locate the template repository.

**Solutions:**

1. **Use full path for local templates:**
   ```bash
   # Absolute path
   cookiecutter /full/path/to/CICD_template/cookiecutters/python-project

   # Relative path
   cd /path/to/CICD_template
   cookiecutter cookiecutters/python-project
   ```

2. **For GitHub repositories:**
   ```bash
   # Use full GitHub URL
   cookiecutter https://github.com/YOUR-ORG/github-cicd-templates \
     --directory="cookiecutters/python-project"
   ```

3. **Check directory exists:**
   ```bash
   ls -la cookiecutters/python-project/cookiecutter.json
   ```

---

### "Invalid template" or JSON parsing errors

**Problem:** Template configuration is malformed.

**Solution:**
```bash
# Validate cookiecutter.json
python3 -c "import json; print(json.load(open('cookiecutters/python-project/cookiecutter.json')))"

# Check for syntax errors
cat cookiecutters/python-project/cookiecutter.json | jq .
```

---

### Template generates but with errors

**Problem:** Post-generation hook fails.

**Solution:**
```bash
# Check hook permissions
ls -l cookiecutters/python-project/hooks/post_gen_project.py

# Make executable if needed
chmod +x cookiecutters/python-project/hooks/post_gen_project.py

# Test hook manually
cd generated-project
python3 ../cookiecutters/python-project/hooks/post_gen_project.py
```

---

### Project already exists error

**Problem:** Directory with project name already exists.

**Solutions:**

1. **Remove existing directory:**
   ```bash
   rm -rf my-project-name
   ```

2. **Use different project name:**
   ```bash
   cookiecutter ... project_name="my-project-v2"
   ```

---

## Pre-commit Issues

### "pre-commit: command not found"

**Problem:** Pre-commit is not installed.

**Solution:**
```bash
# Install pre-commit
pip install pre-commit

# Or with system package manager
# Ubuntu/Debian:
sudo apt-get install pre-commit

# macOS:
brew install pre-commit

# Verify installation
pre-commit --version
```

---

### Pre-commit hooks fail on first run

**Problem:** Hooks need to be installed and dependencies downloaded.

**Solution:**
```bash
# Install hooks
pre-commit install

# Update to latest versions
pre-commit autoupdate

# Run once to download all dependencies
pre-commit run --all-files
```

This is normal on first run. Subsequent runs will be faster.

---

### "Ruff not found" or Ruff errors

**Problem:** Ruff is not installed in the environment.

**Solution:**
```bash
# For Python projects, install dev dependencies
pip install -e .[dev]

# Or install Ruff directly
pip install ruff

# Verify installation
ruff --version
```

---

### Pre-commit modifies files

**Problem:** Pre-commit hooks auto-fix issues (this is expected behavior).

**What happens:**
- Ruff formats code automatically
- Trailing whitespace is removed
- End-of-file newlines are added

**Solution:**
```bash
# This is correct behavior! Just stage the changes:
git add .

# Then commit again
git commit -m "Your message"
```

---

### "hook installation failed"

**Problem:** Pre-commit cannot install git hooks.

**Solution:**
```bash
# Ensure you're in a git repository
git status

# If not, initialize git
git init

# Reinstall hooks
pre-commit uninstall
pre-commit install

# Check .git/hooks directory
ls -la .git/hooks/
```

---

### Hooks take too long

**Problem:** First run downloads dependencies.

**Solution:**
- First run: 30-60 seconds (downloading Ruff, clang-tools, etc.)
- Subsequent runs: 1-5 seconds

**To speed up:**
```bash
# Cache pre-commit environments
pre-commit run --all-files  # Run once to cache

# Skip hooks temporarily (not recommended)
git commit --no-verify -m "message"
```

---

## Python Project Issues

### Virtual environment not created

**Problem:** .venv directory missing after project creation.

**Solution:**
```bash
# Create manually
python3 -m venv .venv

# Activate
source .venv/bin/activate  # Linux/macOS
.venv\Scripts\activate     # Windows

# Install dependencies
pip install -e .[dev]
```

---

### "ModuleNotFoundError" when running tests

**Problem:** Package not installed in editable mode.

**Solution:**
```bash
# Activate virtual environment first
source .venv/bin/activate

# Install in editable mode
pip install -e .[dev]

# Verify installation
pip list | grep your-package-name
```

---

### Ruff check fails with "rule not found"

**Problem:** Ruff configuration has invalid rule codes.

**Solution:**
```bash
# Check Ruff configuration
cat ruff.toml
cat pyproject.toml | grep -A 10 "\[tool.ruff\]"

# List available rules
ruff rule --all

# Test configuration
ruff check . --show-settings
```

---

### pytest fails with "no tests found"

**Problem:** Test files not following naming convention.

**Solution:**
```bash
# Test files must match pattern
# Correct: test_*.py or *_test.py
# Incorrect: tests.py, testing.py

# Check test discovery
pytest --collect-only

# Verify test directory structure
ls -la tests/
```

---

### Import errors in tests

**Problem:** Test cannot import source code.

**Solution:**
```bash
# Ensure package is installed
pip install -e .

# Or check PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)/src"

# Verify package structure
ls -la src/your_package/
cat src/your_package/__init__.py
```

---

### mypy type checking errors

**Problem:** Type annotations are incorrect or incomplete.

**Solution:**
```bash
# See specific errors
mypy src/

# Ignore errors temporarily (not recommended)
# Add to pyproject.toml:
# [tool.mypy]
# ignore_errors = true

# Or use less strict mode
mypy src/ --no-strict-optional
```

---

## C++ Project Issues

### CMake configuration fails

**Problem:** CMake cannot find required tools.

**Solution:**
```bash
# Install CMake
# Ubuntu/Debian:
sudo apt-get install cmake ninja-build

# macOS:
brew install cmake ninja

# Verify installation
cmake --version
ninja --version

# Clean and reconfigure
rm -rf build
cmake -B build -G Ninja
```

---

### "Ninja not found" error

**Problem:** Ninja build system not installed.

**Solution:**
```bash
# Install Ninja
# Ubuntu/Debian:
sudo apt-get install ninja-build

# macOS:
brew install ninja

# Or use Make instead
cmake -B build  # Without -G Ninja
cmake --build build
```

---

### sccache not working

**Symptoms:**
- Cache hit rate: 0%
- Build times not improving
- "sccache: command not found"

**Solution:**
```bash
# Install sccache
SCCACHE_VERSION=0.7.7
# Linux:
curl -L https://github.com/mozilla/sccache/releases/download/v${SCCACHE_VERSION}/sccache-v${SCCACHE_VERSION}-x86_64-unknown-linux-musl.tar.gz | tar xz
sudo mv sccache-*/sccache /usr/local/bin/
chmod +x /usr/local/bin/sccache

# macOS:
brew install sccache

# Verify installation
sccache --version

# Check environment variables
echo $CMAKE_CXX_COMPILER_LAUNCHER

# Set if missing
export CMAKE_CXX_COMPILER_LAUNCHER=sccache
export CMAKE_C_COMPILER_LAUNCHER=sccache

# Check stats
sccache --show-stats

# Clear cache if needed
sccache --stop-server
rm -rf ~/.cache/sccache
sccache --start-server
```

---

### clang-format not found

**Problem:** Code formatting fails in pre-commit.

**Solution:**
```bash
# Install clang-format
# Ubuntu/Debian:
sudo apt-get install clang-format

# macOS:
brew install clang-format

# Verify version (need 10+)
clang-format --version

# Test manually
clang-format -i src/*.cpp
```

---

### clang-tidy errors

**Problem:** Static analysis finds issues.

**Solution:**
```bash
# Check .clang-tidy configuration
cat .clang-tidy

# Generate compile_commands.json (required)
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Run clang-tidy manually
clang-tidy src/main.cpp -p build

# Disable specific checks temporarily
# Add to .clang-tidy:
# Checks: '-readability-magic-numbers'
```

---

### GoogleTest not found

**Problem:** CMake cannot find testing framework.

**Solution:**
```bash
# Install GoogleTest
# Ubuntu/Debian:
sudo apt-get install libgtest-dev

# macOS:
brew install googletest

# Or use CMake FetchContent (already in template)
# CMakeLists.txt will download automatically

# Verify tests build
cmake -B build
cmake --build build
ctest --test-dir build
```

---

### Compilation errors with C++ standard

**Problem:** Code uses features from newer C++ standard.

**Solution:**
```bash
# Check C++ standard in CMakeLists.txt
grep "CMAKE_CXX_STANDARD" CMakeLists.txt

# Change to C++17/20/23 as needed
# In CMakeLists.txt:
# set(CMAKE_CXX_STANDARD 20)

# Verify compiler supports standard
g++ --version
clang++ --version
```

---

## GitHub Actions Issues

### Workflow not triggering

**Problem:** Push/PR does not start CI.

**Checklist:**
- [ ] Workflow file in `.github/workflows/` directory
- [ ] File has `.yml` or `.yaml` extension
- [ ] Valid YAML syntax
- [ ] Correct trigger events (on: push, pull_request)

**Solution:**
```bash
# Validate YAML syntax
python3 -c "import yaml; print(yaml.safe_load(open('.github/workflows/ci.yaml')))"

# Or use online validator: https://www.yamllint.com/

# Check GitHub Actions tab for errors
# Repository -> Actions -> Check for workflow runs

# Ensure workflow is not disabled
# Settings -> Actions -> General -> Allow all actions
```

---

### "Reusable workflow not found"

**Error:**
```
workflow ... references ... which could not be resolved
```

**Problem:** Cannot find reusable workflow reference.

**Solution:**
```yaml
# Verify format:
jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/python-ci-reusable.yaml@v1
    #     ^^^^^^^^ Org name
    #              ^^^^^^^^^^^^^^^^^^^^^^^ Repo name
    #                                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Path
    #                                                                           ^^^ Ref (branch/tag)
```

**Checklist:**
- [ ] Repository is public or you have access
- [ ] Reference uses correct org/repo name
- [ ] Path to workflow file is correct
- [ ] Branch/tag exists (`@main`, `@v1`, etc.)
- [ ] Workflow has `workflow_call` trigger

**Test:**
```bash
# Verify repository exists
gh repo view YOUR-ORG/github-cicd-templates

# Check workflow file exists
curl https://raw.githubusercontent.com/YOUR-ORG/github-cicd-templates/main/.github/workflows/python-ci-reusable.yaml
```

---

### Workflow inputs not working

**Problem:** Custom inputs not being passed to reusable workflow.

**Solution:**
```yaml
# Ensure 'with:' is at correct indentation level
jobs:
  ci:
    uses: org/repo/.github/workflows/python-ci-reusable.yaml@v1
    with:                        # Same level as 'uses'
      python-version: '3.11'
      run-coverage: true
```

**Verify input names match workflow definition:**
```bash
# Check workflow file for input names
grep -A 5 "inputs:" .github/workflows/python-ci-reusable.yaml
```

---

### "Action not found" errors

**Problem:** Cannot find composite action.

**Solution:**
```yaml
# Verify action path
- uses: YOUR-ORG/github-cicd-templates/.github/actions/setup-python-cache@v1
  #     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Full path required
```

**For local actions:**
```yaml
# Must checkout first
- uses: actions/checkout@v4
- uses: ./.github/actions/setup-python-cache  # Relative path
```

---

### Workflow fails but no errors shown

**Problem:** Job fails silently.

**Solution:**
```bash
# Check workflow run details
# GitHub -> Actions -> Click on failed run -> Click on failed job

# Add debugging
# In workflow YAML, add:
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true

# Or add explicit error checking:
- name: Run tests
  run: |
    set -e  # Exit on error
    pytest tests/ -v
```

---

### Python/C++ tools not found in runner

**Problem:** Command not found (ruff, cmake, etc.).

**Solution for Python:**
```yaml
# Ensure setup-python and installation steps
- uses: actions/setup-python@v5
  with:
    python-version: '3.11'

- run: pip install -e .[dev]  # Install dependencies
```

**Solution for C++:**
```yaml
# Install build tools
- name: Install dependencies
  run: |
    sudo apt-get update
    sudo apt-get install -y cmake ninja-build

# Or use composite action
- uses: YOUR-ORG/repo/.github/actions/setup-cpp-cache@v1
```

---

## Self-Hosted Runner Issues

### Runner shows as offline

**Problem:** Self-hosted runner not connecting to GitHub.

**Solution:**
```bash
# Check runner service status
systemctl status actions.runner.*.service

# Restart service
sudo systemctl restart actions.runner.*.service

# Check logs
journalctl -u actions.runner.*.service -f

# Verify network connectivity
curl https://api.github.com

# Check registration token hasn't expired
# Go to: Settings -> Actions -> Runners -> Add new runner
```

---

### Runner not accepting jobs

**Problem:** Jobs stay queued, runner idle.

**Solution:**

1. **Check runner labels match workflow:**
   ```yaml
   # In workflow:
   runs-on: self-hosted

   # Runner must have label: self-hosted
   ```

2. **Verify runner has required tools:**
   ```bash
   # For Python
   which python3 ruff pytest

   # For C++
   which cmake ninja g++ sccache
   ```

3. **Check runner permissions:**
   ```bash
   # Runner user should own work directory
   ls -la /opt/actions-runner/_work
   ```

---

### Runner out of disk space

**Problem:** Builds fail with "No space left on device".

**Solution:**
```bash
# Check disk usage
df -h

# Clean old workflow runs
cd /opt/actions-runner/_work
sudo rm -rf */  # CAUTION: Deletes all work directories

# Clean Docker images (if using Docker)
docker system prune -a

# Clean sccache
sccache --stop-server
rm -rf ~/.cache/sccache
sccache --start-server

# Set up automatic cleanup
# Add to cron:
# 0 2 * * * find /opt/actions-runner/_work -mtime +7 -delete
```

---

### Permission denied errors

**Problem:** Runner cannot access files or execute commands.

**Solution:**
```bash
# Check runner user
ps aux | grep Runner.Listener

# Fix ownership
sudo chown -R github-runner:github-runner /opt/actions-runner

# Check sudo permissions (if needed)
sudo visudo
# Add: github-runner ALL=(ALL) NOPASSWD: /usr/bin/apt-get

# Fix work directory permissions
chmod 755 /opt/actions-runner/_work
```

---

## General Issues

### Git commit fails

**Problem:** Cannot commit generated project.

**Solution:**
```bash
# Configure git if not already done
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Check git status
git status

# Add files
git add .

# Commit
git commit -m "Initial commit"
```

---

### "Permission denied" when running scripts

**Problem:** Script is not executable.

**Solution:**
```bash
# Make script executable
chmod +x scripts/create-project.sh
chmod +x scripts/sync-templates.sh
chmod +x scripts/verify-setup.sh

# Or run with bash
bash scripts/create-project.sh python my-project
```

---

### Python version mismatch

**Problem:** Wrong Python version being used.

**Solution:**
```bash
# Check available Python versions
python3 --version
python3.10 --version
python3.11 --version

# Use specific version
python3.11 -m venv .venv

# Or use pyenv
pyenv install 3.11.0
pyenv local 3.11.0
```

---

### Dependencies not installing

**Problem:** pip install fails or times out.

**Solution:**
```bash
# Upgrade pip first
pip install --upgrade pip setuptools wheel

# Try with verbose output
pip install -e .[dev] -v

# Clear pip cache
pip cache purge

# Use different index
pip install -e .[dev] --index-url https://pypi.org/simple

# Check network/firewall issues
curl https://pypi.org
```

---

### Template sync conflicts

**Problem:** sync-templates.sh overwrites local changes.

**Solution:**
```bash
# Sync creates backups
ls -la *.backup

# Compare before syncing
diff your-file.yaml configs/python/your-file.yaml

# Use dry-run mode first (if available)
bash scripts/sync-templates.sh python . --dry-run

# Manual sync (cherry-pick changes)
# 1. Backup your file
cp pyproject.toml pyproject.toml.backup

# 2. Copy template
cp configs/python/pyproject.toml.template pyproject.toml

# 3. Merge changes manually
```

---

## Getting Help

If you can't resolve your issue:

1. **Check existing documentation:**
   - `README.md` - Basic usage and examples
   - `0.DEV_PLAN.md` - Architecture and design
   - `IMPLEMENTATION_SUMMARY.md` - What's implemented

2. **Run verification script:**
   ```bash
   bash scripts/verify-setup.sh
   ```

3. **Check GitHub Issues:**
   - Search for similar issues
   - Open a new issue with:
     - Error message (full text)
     - Steps to reproduce
     - Your environment (OS, Python version, etc.)
     - Output of `verify-setup.sh`

4. **Debug mode:**
   ```bash
   # Run with debug output
   set -x
   bash scripts/create-project.sh python my-project
   set +x
   ```

5. **Common debugging commands:**
   ```bash
   # Check environment
   env | grep -i python
   which python3
   pip list

   # Check git
   git --version
   git config --list

   # Check tools
   cookiecutter --version
   pre-commit --version
   ruff --version
   cmake --version
   ```

---

## Quick Reference

### Reset Everything

If all else fails, start fresh:

```bash
# 1. Backup any custom code
cp -r my-project my-project.backup

# 2. Remove generated project
rm -rf my-project

# 3. Clear caches
pip cache purge
pre-commit clean
rm -rf ~/.cache/sccache

# 4. Reinstall tools
pip install --upgrade cookiecutter pre-commit

# 5. Regenerate project
bash scripts/create-project.sh python my-project

# 6. Restore custom code
# Manually copy your files back
```

---

**Last Updated:** 2025-10-13
**Version:** 1.0
