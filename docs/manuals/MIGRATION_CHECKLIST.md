# Migration Checklist

This guide helps you migrate existing Python or C++ projects to use the CI/CD template system.

---

## Table of Contents

- [Pre-Migration](#pre-migration)
- [Python Project Migration](#python-project-migration)
- [C++ Project Migration](#c-project-migration)
- [Post-Migration](#post-migration)
- [Rollback Plan](#rollback-plan)

---

## Pre-Migration

### Step 1: Assessment

**Evaluate your project:**
- [ ] Project language (Python or C++)
- [ ] Current build system
- [ ] Existing CI/CD setup
- [ ] Test framework
- [ ] Code quality tools
- [ ] Team familiarity with new tools

**Estimate impact:**
- [ ] Time required (2-4 hours for typical project)
- [ ] Breaking changes (usually none)
- [ ] Team training needs

---

### Step 2: Backup

Create a backup before making changes:

```bash
# Create a git branch for migration
git checkout -b migrate-to-cicd-template

# Or create a backup copy
cp -r /path/to/project /path/to/project.backup

# Tag current state
git tag pre-migration-$(date +%Y%m%d)
git push --tags
```

---

### Step 3: Documentation

Document current state:

```bash
# Document current build times
# For Python:
time (pip install -e .[dev] && pytest)

# For C++:
time (cmake -B build && cmake --build build && ctest --test-dir build)

# Save current CI configuration
cp -r .github/workflows .github/workflows.backup

# List installed tools
pip list > pre-migration-pip-list.txt  # Python
cmake --version > pre-migration-tools.txt  # C++
```

---

### Step 4: Communication

Inform your team:

- [ ] Notify team of migration schedule
- [ ] Share this checklist
- [ ] Identify migration window (low-activity time)
- [ ] Plan for 2-4 hours of potential disruption

---

## Python Project Migration

### Step 1: Install Pre-commit Configuration

```bash
# Copy pre-commit config
cp /path/to/CICD_template/configs/python/.pre-commit-config.yaml .

# Review and adjust if needed
cat .pre-commit-config.yaml

# Install hooks
pip install pre-commit
pre-commit install

# Run once to download dependencies (may take 1-2 minutes)
pre-commit run --all-files
```

**Expected changes:**
- Code formatting with Ruff
- Trailing whitespace removed
- End-of-file newlines added

**Review changes:**
```bash
git diff
```

If changes are acceptable:
```bash
git add .
git commit -m "Apply code formatting from pre-commit hooks"
```

---

### Step 2: Update pyproject.toml

**Option A: Merge with template**

```bash
# Backup current file
cp pyproject.toml pyproject.toml.backup

# Copy template
cp /path/to/CICD_template/configs/python/pyproject.toml.template pyproject.toml.new

# Merge manually, keeping your:
# - project name, version, description
# - existing dependencies
# - custom configurations

# Add template sections:
# - [tool.ruff]
# - [tool.pytest.ini_options]
# - [tool.coverage.run]
# - dev dependencies (ruff, pytest, mypy, pre-commit)
```

**Option B: Add Ruff configuration to existing file**

Add to your `pyproject.toml`:

```toml
[tool.ruff]
target-version = "py310"
line-length = 88

[tool.ruff.lint]
select = ["E", "W", "F", "I", "N", "UP", "B", "C4", "SIM"]
ignore = ["E501"]
fixable = ["ALL"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

---

### Step 3: Add Ruff Configuration File (Optional)

If you prefer separate configuration:

```bash
cp /path/to/CICD_template/configs/python/ruff.toml .
```

---

### Step 4: Install New Dependencies

```bash
# Activate virtual environment
source .venv/bin/activate

# Add to pyproject.toml if not already there:
# [project.optional-dependencies]
# dev = [
#     "pytest>=7.4",
#     "pytest-cov>=4.1",
#     "ruff>=0.6.0",
#     "mypy>=1.11",
#     "pre-commit>=3.5",
# ]

# Install
pip install -e .[dev]

# Verify installations
ruff --version
pytest --version
mypy --version
```

---

### Step 5: Remove Old Tools (Optional)

If migrating from Black, Flake8, isort, pyupgrade:

```bash
# Update pyproject.toml - remove:
# - black
# - flake8
# - isort
# - pyupgrade

# Update .pre-commit-config.yaml - remove their hooks

# Uninstall
pip uninstall black flake8 isort pyupgrade

# Remove configuration files
rm -f .black .flake8 .isort.cfg setup.cfg  # If only used for these tools
```

---

### Step 6: Update CI Workflow

**Backup existing workflow:**
```bash
mv .github/workflows/ci.yaml .github/workflows/ci.yaml.backup
```

**Create new workflow:**

```bash
cat > .github/workflows/ci.yaml <<'EOF'
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/python-ci-reusable.yaml@v1
    with:
      python-version: '3.11'  # Adjust to your version
      run-tests: true
      run-coverage: true
      runner-type: 'ubuntu-latest'
EOF
```

**Customize as needed:**
- Change `YOUR-ORG` to your organization name
- Adjust `python-version`
- Modify branch names
- Add additional jobs if needed

---

### Step 7: Test Locally

```bash
# Run pre-commit (should pass)
pre-commit run --all-files

# Run tests (should pass)
pytest

# Run with coverage
pytest --cov=src --cov-report=term-missing

# Run type checking
mypy src/

# Fix any issues found
```

---

### Step 8: Commit and Push

```bash
# Review all changes
git status
git diff

# Stage changes
git add .

# Commit (pre-commit hooks will run)
git commit -m "Migrate to CI/CD template system

- Add pre-commit hooks with Ruff
- Update pyproject.toml with Ruff configuration
- Replace CI workflow with reusable template
- Remove deprecated linting tools (Black, Flake8)
"

# Push to branch
git push -u origin migrate-to-cicd-template
```

---

### Step 9: Create Pull Request

1. Create PR on GitHub
2. Wait for CI to complete (verify green ✅)
3. Review workflow run details
4. Compare build times with previous runs

---

### Step 10: Verify CI Success

Check that workflow runs successfully:

- [ ] Ruff linting passes
- [ ] Ruff formatting passes
- [ ] pytest runs and passes
- [ ] Coverage report generated
- [ ] Build time is acceptable

If issues occur, see [Troubleshooting](#troubleshooting) section.

---

## C++ Project Migration

### Step 1: Copy Configuration Files

```bash
# Copy pre-commit config
cp /path/to/CICD_template/configs/cpp/.pre-commit-config.yaml .

# Copy formatting config
cp /path/to/CICD_template/configs/cpp/.clang-format .

# Copy static analysis config
cp /path/to/CICD_template/configs/cpp/.clang-tidy .
```

---

### Step 2: Update CMakeLists.txt

Add sccache support and compile commands export:

```cmake
# Add near the top of CMakeLists.txt

# Export compile commands for clang-tidy
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Enable sccache (will use if available)
find_program(CCACHE_PROGRAM sccache)
if(CCACHE_PROGRAM)
    set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
    set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
endif()

# Compiler warnings
if(MSVC)
    add_compile_options(/W4 /WX)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -Werror)
endif()
```

**Or copy template and merge:**
```bash
cp /path/to/CICD_template/configs/cpp/CMakeLists.txt.template CMakeLists.txt.new
# Manually merge your project-specific content
```

---

### Step 3: Install Development Tools

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y \
    cmake ninja-build \
    clang-format clang-tidy \
    cppcheck
```

**macOS:**
```bash
brew install cmake ninja clang-format
```

**Install sccache (optional but recommended):**
```bash
# Linux
SCCACHE_VERSION=0.7.7
curl -L https://github.com/mozilla/sccache/releases/download/v${SCCACHE_VERSION}/sccache-v${SCCACHE_VERSION}-x86_64-unknown-linux-musl.tar.gz | tar xz
sudo mv sccache-*/sccache /usr/local/bin/
chmod +x /usr/local/bin/sccache

# macOS
brew install sccache

# Verify
sccache --version
```

---

### Step 4: Install Pre-commit Hooks

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run formatting (first time may reformat code)
pre-commit run --all-files
```

**Review formatting changes:**
```bash
git diff
```

**Commit formatting changes:**
```bash
git add .
git commit -m "Apply clang-format to existing code"
```

---

### Step 5: Configure Build with sccache

```bash
# Clean old build
rm -rf build

# Configure with sccache
export CMAKE_CXX_COMPILER_LAUNCHER=sccache
export CMAKE_C_COMPILER_LAUNCHER=sccache

cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build

# Check sccache stats
sccache --show-stats
```

---

### Step 6: Update CI Workflow

**Backup existing workflow:**
```bash
mv .github/workflows/ci.yaml .github/workflows/ci.yaml.backup
```

**Create new workflow:**

```bash
cat > .github/workflows/ci.yaml <<'EOF'
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-ci-reusable.yaml@v1
    with:
      build-type: 'Release'
      cpp-compiler: 'g++'
      run-tests: true
      enable-cache: true
      runner-type: 'ubuntu-latest'
      use-ninja: true
EOF
```

---

### Step 7: Test Build Locally

```bash
# Clean build
rm -rf build

# Configure
cmake -B build -G Ninja

# Build
cmake --build build -j$(nproc)

# Run tests
ctest --test-dir build --output-on-failure

# Run clang-tidy (if configured)
clang-tidy src/*.cpp -p build
```

---

### Step 8: Commit and Push

```bash
git status
git add .

git commit -m "Migrate to CI/CD template system

- Add pre-commit hooks with clang-format and clang-tidy
- Configure sccache for faster builds
- Update CI workflow to use reusable template
- Add compiler warnings
"

git push -u origin migrate-to-cicd-template
```

---

### Step 9: Verify CI Success

Monitor the workflow run:

- [ ] CMake configuration succeeds
- [ ] Build completes successfully
- [ ] Tests pass
- [ ] sccache is working (check logs)
- [ ] Build time is acceptable

---

## Post-Migration

### Step 1: Measure Performance

Compare before and after:

```bash
# Python
echo "Before: [X] seconds"
echo "After: [Y] seconds"

# C++
echo "Build time before: [X] minutes"
echo "Build time after: [Y] minutes"
```

**Expected improvements:**
- Python linting: 5-10x faster (Ruff vs Black+Flake8)
- C++ builds: 50%+ faster with sccache (after cache warm-up)

---

### Step 2: Update Documentation

Update project README:

```markdown
## Development Setup

### Prerequisites
- Python 3.11+ (or C++ compiler)
- pip, git

### Setup
\`\`\`bash
# Python
python3 -m venv .venv
source .venv/bin/activate
pip install -e .[dev]
pre-commit install

# C++
cmake -B build -G Ninja
cmake --build build
\`\`\`

### Code Quality
This project uses:
- Ruff for Python linting and formatting
- clang-format for C++ formatting
- Pre-commit hooks (run automatically on commit)

Run manually:
\`\`\`bash
# Python
ruff check .
ruff format .
pytest

# C++
cmake --build build
ctest --test-dir build
\`\`\`
```

---

### Step 3: Team Training

Share with team:

- [ ] Link to [Quick Start Guide](QUICK_START.md)
- [ ] Link to [Troubleshooting Guide](TROUBLESHOOTING.md)
- [ ] New development workflow
- [ ] How to run pre-commit manually
- [ ] Expected behavior (auto-formatting on commit)

**Common questions to address:**
- "Why did my code get reformatted?" → Pre-commit auto-fixes
- "How do I skip hooks temporarily?" → `git commit --no-verify` (⚠️ **DANGEROUS** - not recommended)
- "Why is the first build slow?" → Downloading dependencies (one-time)

---

### Step 4: Monitor Issues

Watch for:

- [ ] Build failures (check GitHub Actions)
- [ ] Team complaints about pre-commit hooks
- [ ] Performance issues
- [ ] Configuration problems

Address issues quickly to maintain team buy-in.

---

### Step 5: Cleanup

After successful migration (1-2 weeks):

```bash
# Remove backup files
rm .github/workflows/ci.yaml.backup
rm pyproject.toml.backup  # If created

# Remove backup branch (if not using PR)
git branch -d migrate-to-cicd-template

# Remove old tool configs
rm .black .flake8 setup.cfg  # Python
# (if no longer needed)

# Update .gitignore if needed
```

---

## Rollback Plan

If migration causes critical issues:

### Quick Rollback

```bash
# Revert last commit
git revert HEAD
git push

# Or reset to tag
git reset --hard pre-migration-YYYYMMDD
git push --force  # Use with caution!
```

---

### Restore Backup Files

```bash
# Restore workflow
mv .github/workflows/ci.yaml.backup .github/workflows/ci.yaml

# Restore Python config
mv pyproject.toml.backup pyproject.toml

# Uninstall pre-commit hooks
pre-commit uninstall

# Reinstall old tools
pip install black flake8 isort  # Python

git add .
git commit -m "Rollback CI/CD template migration"
git push
```

---

### Partial Rollback

Keep some improvements, rollback others:

**Keep pre-commit, rollback CI workflow:**
```bash
mv .github/workflows/ci.yaml.backup .github/workflows/ci.yaml
git add .github/workflows/ci.yaml
git commit -m "Revert CI workflow only"
```

**Keep Ruff, rollback pre-commit:**
```bash
pre-commit uninstall
rm .pre-commit-config.yaml
# Keep pyproject.toml with Ruff config
git add .
git commit -m "Remove pre-commit hooks, keep Ruff"
```

---

## Troubleshooting

### Migration Fails During Pre-commit

**Problem:** Pre-commit finds too many issues.

**Solution:**
```bash
# Let pre-commit auto-fix
pre-commit run --all-files

# Review changes
git diff

# If too many changes, do incrementally
pre-commit run --files src/module1.py
# Review and commit
# Repeat for other files
```

---

### CI Fails After Migration

**Problem:** New CI workflow fails.

**Solution:**
1. Check error message in GitHub Actions
2. Test locally first:
   ```bash
   # Python
   ruff check . && pytest

   # C++
   cmake -B build && cmake --build build && ctest --test-dir build
   ```
3. See [Troubleshooting Guide](TROUBLESHOOTING.md)

---

### Team Resistance

**Problem:** Team doesn't like automatic formatting.

**Solution:**
- Explain benefits (no more formatting debates)
- Show time savings
- Offer training session
- Start with `pre-commit run` manually before committing
- Make auto-commit optional initially

---

### Performance Degradation

**Problem:** Builds are slower after migration.

**Solution:**

**For Python:**
- Ruff should be faster, not slower
- Check if running all tools: `pre-commit run --all-files -v`
- Cache may need to warm up

**For C++:**
- sccache needs 1-2 builds to warm up cache
- Check sccache is actually running: `sccache --show-stats`
- Ensure environment variables are set

---

## Success Criteria

Migration is successful when:

- [ ] All tests pass locally
- [ ] All tests pass in CI
- [ ] Pre-commit hooks work automatically
- [ ] Build times are same or better
- [ ] Team can develop without issues
- [ ] No increase in bug reports
- [ ] CI provides clear feedback on failures

---

## Next Steps After Migration

1. **Standardize across projects**
   - Migrate other projects using lessons learned
   - Share migration experience with team

2. **Optimize further**
   - Set up self-hosted runners for even faster builds
   - Add more pre-commit hooks as needed
   - Configure coverage requirements

3. **Maintain**
   - Keep pre-commit hooks updated: `pre-commit autoupdate`
   - Update reusable workflows to latest versions
   - Monitor for new tool versions

---

## Migration Checklist Summary

### Python Projects
- [ ] Pre-migration backup
- [ ] Copy pre-commit config
- [ ] Update pyproject.toml with Ruff
- [ ] Install new dev dependencies
- [ ] Remove old linting tools
- [ ] Update CI workflow
- [ ] Test locally
- [ ] Push and verify CI
- [ ] Document changes
- [ ] Train team

### C++ Projects
- [ ] Pre-migration backup
- [ ] Copy configuration files (.clang-format, .clang-tidy)
- [ ] Update CMakeLists.txt (sccache, warnings)
- [ ] Install development tools
- [ ] Configure pre-commit hooks
- [ ] Test build with sccache
- [ ] Update CI workflow
- [ ] Push and verify CI
- [ ] Document changes
- [ ] Train team

---

## Support

Need help with migration?

- **Troubleshooting:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Questions:** Open GitHub Discussion
- **Issues:** Report on GitHub Issues
- **Training:** Request team training session

---

**Last Updated:** 2025-10-13
**Version:** 1.0
