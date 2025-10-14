# Quick Start Guide

Get started with the CI/CD Template System in under 5 minutes.

---

## Prerequisites

Before you begin, ensure you have:

- **Python 3.10+** (for Cookiecutter)
- **Git** (for version control)
- **pip** (Python package manager)

### Install Prerequisites

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install python3 python3-pip git
```

**macOS:**
```bash
brew install python3 git
```

**Windows:**
- Install Python from [python.org](https://www.python.org/downloads/)
- Install Git from [git-scm.com](https://git-scm.com/downloads)

---

## Installation

### Step 1: Install Cookiecutter

```bash
# Using pip
pip install cookiecutter

# Or using pipx (recommended for tool isolation)
pipx install cookiecutter

# Verify installation
cookiecutter --version
```

**Expected output:** `Cookiecutter 2.x.x` or higher

---

## Create Your First Project

### Option A: Python Project

#### 1. Create Project

```bash
# Interactive mode (recommended for first time)
bash scripts/create-project.sh python

# You'll be prompted for:
# - Project name: my-awesome-api
# - Author name: Your Name
# - Python version: 3.11
# - License: MIT
# - etc.
```

**Or use non-interactive mode with absolute path:**
```bash
bash scripts/create-project.sh python /home/user/my-awesome-api
```

#### 2. Navigate to Project

```bash
cd /home/user/my-awesome-api
```

#### 3. Activate Virtual Environment

```bash
# Linux/macOS
source .venv/bin/activate

# Windows
.venv\Scripts\activate
```

You should see `(.venv)` in your terminal prompt.

**Note:** All dependencies (Ruff, pytest, mypy, pre-commit) are already installed during project creation!

#### 4. Run Tests

```bash
# Run the example test
pytest

# With coverage
pytest --cov=src --cov-report=html
```

#### 5. Check Code Quality

```bash
# Lint and format
ruff check src/
ruff format src/

# Type checking
mypy src/
```

#### 6. Make Your First Commit

```bash
# The project is already initialized with git
git status

# Pre-commit hooks are already installed
# They'll run automatically on commit

# Make a change to test hooks
echo "# My Project" >> README.md

# Commit (hooks will run)
git add README.md
git commit -m "Update README"
```

#### 7. Push to GitHub

```bash
# Add your remote repository
git remote add origin https://github.com/YOUR-USERNAME/my-awesome-api.git

# Push
git push -u origin main
```

The CI/CD workflow will run automatically on GitHub Actions!

---

**What was automatically set up for you:**
- ✅ Virtual environment created
- ✅ All dev dependencies installed (ruff, pytest, mypy, pre-commit)
- ✅ Pre-commit hooks installed and ready
- ✅ Git repository initialized with initial commit

---

### Option B: C++ Project

#### 1. Create Project

```bash
# Interactive mode
bash scripts/create-project.sh cpp

# Or non-interactive with absolute path
bash scripts/create-project.sh cpp /home/user/my-fast-library
```

#### 2. Navigate to Project

```bash
cd /home/user/my-fast-library
```

#### 3. Install Build Tools

**Ubuntu/Debian:**
```bash
sudo apt-get install cmake ninja-build clang-format clang-tidy
```

**macOS:**
```bash
brew install cmake ninja clang-format
```

#### 4. Configure Build

```bash
# Using Ninja (fast, recommended)
cmake -B build -G Ninja

# Or using Make
cmake -B build
```

#### 5. Build

```bash
cmake --build build

# Or with multiple cores
cmake --build build -j$(nproc)
```

#### 6. Run Tests

```bash
ctest --test-dir build --output-on-failure

# Or with verbose output
ctest --test-dir build -V
```

#### 7. Run Formatting

```bash
# Format code
clang-format -i src/*.cpp include/*.hpp

# Or use pre-commit
pre-commit run --all-files
```

#### 8. Push to GitHub

```bash
git remote add origin https://github.com/YOUR-USERNAME/my-fast-library.git
git push -u origin main
```

---

**What was automatically set up for you:**
- ✅ Git repository initialized with initial commit
- ✅ Pre-commit tool installed
- ✅ Pre-commit hooks installed and ready
- ✅ Build directory created

---

## Project Structure

### Python Project
```
my-awesome-api/
├── .github/
│   └── workflows/
│       └── ci.yaml              # GitHub Actions CI
├── src/
│   └── my_awesome_api/
│       └── __init__.py          # Your code here
├── tests/
│   └── test_example.py          # Your tests here
├── .pre-commit-config.yaml      # Pre-commit hooks
├── pyproject.toml               # Project configuration
├── README.md                    # Documentation
└── .venv/                       # Virtual environment
```

### C++ Project
```
my-fast-library/
├── .github/
│   └── workflows/
│       └── ci.yaml              # GitHub Actions CI
├── src/
│   └── main.cpp                 # Your source code
├── include/
│   └── my_library.hpp           # Your headers
├── tests/
│   ├── CMakeLists.txt
│   └── test_example.cpp         # Your tests
├── .clang-format                # Code formatting rules
├── .clang-tidy                  # Static analysis rules
├── CMakeLists.txt               # Build configuration
├── README.md                    # Documentation
└── build/                       # Build output
```

---

## Using Reusable Workflows

You can also add the reusable workflows to existing projects.

### For Existing Python Project

Create `.github/workflows/ci.yaml`:

```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/python-ci-reusable.yaml@v1
    with:
      python-version: '3.11'
      run-tests: true
      run-coverage: true
      runner-type: 'ubuntu-latest'
```

### For Existing C++ Project

Create `.github/workflows/ci.yaml`:

```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-ci-reusable.yaml@v1
    with:
      build-type: 'Release'
      cpp-compiler: 'g++'
      enable-cache: true
      use-ninja: true
      runner-type: 'ubuntu-latest'
```

---

## Sync Configurations

To sync the latest configurations to an existing project:

```bash
# Sync Python configs
bash scripts/sync-templates.sh python /path/to/your/project

# Sync C++ configs
bash scripts/sync-templates.sh cpp /path/to/your/project
```

This will:
- Backup your existing configs (`.backup` extension)
- Copy latest templates
- Prompt before overwriting

---

## Verify Setup

Check if everything is correctly set up:

```bash
bash scripts/verify-setup.sh
```

This will check:
- All template files exist
- Scripts are executable
- Dependencies are installed
- Configuration files are valid

---

## Common Workflows

### Python Development

```bash
# Activate environment
source .venv/bin/activate

# Install dependencies (after updating pyproject.toml)
pip install -e .[dev]

# Run tests
pytest

# Run tests with coverage
pytest --cov=src --cov-report=html
open htmlcov/index.html  # View coverage report

# Lint and format
ruff check .
ruff format .

# Type check
mypy src/

# Run pre-commit hooks manually
pre-commit run --all-files

# Update pre-commit hooks
pre-commit autoupdate
```

### C++ Development

```bash
# Configure (first time only)
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug

# Build
cmake --build build

# Run specific test
ctest --test-dir build -R test_name

# Clean and rebuild
rm -rf build
cmake -B build -G Ninja
cmake --build build

# Format code
clang-format -i src/**/*.cpp include/**/*.hpp

# Run static analysis
clang-tidy src/*.cpp -p build

# Check with different compiler
CC=clang CXX=clang++ cmake -B build-clang -G Ninja
cmake --build build-clang
```

---

## Customization

### Python Customization

**Change Python version:**
Edit `pyproject.toml`:
```toml
requires-python = ">=3.11"
```

**Add dependencies:**
```toml
[project]
dependencies = [
    "requests>=2.28",
    "pydantic>=2.0",
]
```

**Add dev dependencies:**
```toml
[project.optional-dependencies]
dev = [
    "pytest>=7.4",
    "ruff>=0.6.0",
    # Add more...
]
```

**Customize Ruff:**
Edit `ruff.toml` or `pyproject.toml`:
```toml
[tool.ruff]
line-length = 100  # Default is 88
```

### C++ Customization

**Change C++ standard:**
Edit `CMakeLists.txt`:
```cmake
set(CMAKE_CXX_STANDARD 20)  # 17, 20, or 23
```

**Add dependencies:**
```cmake
find_package(Boost REQUIRED)
target_link_libraries(my_library PRIVATE Boost::boost)
```

**Change build type:**
```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug    # or Release, RelWithDebInfo
```

---

## GitHub Actions Configuration

### Workflow Inputs

**Python workflow inputs:**
```yaml
with:
  python-version: '3.11'      # Python version (3.10, 3.11, 3.12)
  working-directory: '.'      # Working directory
  run-tests: true             # Run pytest
  run-coverage: true          # Generate coverage report
  runner-type: 'ubuntu-latest' # or 'self-hosted'
```

**C++ workflow inputs:**
```yaml
with:
  build-type: 'Release'       # Debug, Release, RelWithDebInfo
  cpp-compiler: 'g++'         # g++ or clang++
  cmake-options: ''           # Extra CMake options
  run-tests: true             # Run ctest
  enable-cache: true          # Enable sccache
  runner-type: 'ubuntu-latest'
  use-ninja: true             # Use Ninja build system
```

### Matrix Builds

Test multiple versions:

```yaml
jobs:
  test:
    strategy:
      matrix:
        python-version: ['3.10', '3.11', '3.12']
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      - run: pip install -e .[dev]
      - run: pytest
```

---

## Tips & Best Practices

### Python

1. **Always use virtual environments**
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```

2. **Pin your dependencies**
   ```bash
   pip freeze > requirements.txt
   ```

3. **Run pre-commit before pushing**
   ```bash
   pre-commit run --all-files
   ```

4. **Keep test coverage high**
   ```bash
   pytest --cov=src --cov-report=term-missing
   ```

### C++

1. **Use out-of-source builds**
   ```bash
   cmake -B build  # NOT: cmake .
   ```

2. **Enable all warnings**
   ```cmake
   add_compile_options(-Wall -Wextra -Wpedantic -Werror)
   ```

3. **Use sccache for faster builds**
   ```bash
   export CMAKE_CXX_COMPILER_LAUNCHER=sccache
   ```

4. **Run sanitizers in debug mode**
   ```bash
   cmake -B build -DCMAKE_BUILD_TYPE=Debug \
     -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined"
   ```

---

## Next Steps

Now that you have a project set up:

1. **Read the main README** for more details
   ```bash
   cat README.md
   ```

2. **Customize the template** to match your needs
   - Update `README.md` with project-specific information
   - Add your code to `src/`
   - Add tests to `tests/`

3. **Set up GitHub repository**
   - Enable branch protection on `main`
   - Require CI to pass before merging
   - Enable Dependabot for dependency updates

4. **Add more features**
   - Code coverage badges
   - Documentation generation (Sphinx for Python, Doxygen for C++)
   - Release automation

5. **Explore advanced features**
   - Self-hosted runners for faster builds
   - Matrix builds for multiple platforms
   - Deployment workflows

---

## Troubleshooting

If you encounter issues, see:

- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Common problems and solutions
- **[Main README](../README.md)** - Full documentation
- **[Dev Plan](../0.DEV_PLAN.md)** - Architecture details

Or run the verification script:
```bash
bash scripts/verify-setup.sh
```

---

## Getting Help

- **Documentation:** Check `docs/` directory
- **Examples:** See generated projects for reference
- **Issues:** Report bugs on GitHub Issues
- **Questions:** Open a GitHub Discussion

---

## Quick Reference Card

### Python Commands
```bash
# Setup
python3 -m venv .venv && source .venv/bin/activate
pip install -e .[dev]

# Development
pytest                    # Run tests
ruff check .              # Lint
ruff format .             # Format
mypy src/                 # Type check
pre-commit run --all-files  # Run all hooks

# Git
git add . && git commit -m "message"  # Pre-commit runs automatically
```

### C++ Commands
```bash
# Setup
cmake -B build -G Ninja

# Development
cmake --build build            # Build
ctest --test-dir build        # Test
clang-format -i src/*.cpp     # Format
clang-tidy src/*.cpp -p build # Lint

# Clean
rm -rf build && cmake -B build -G Ninja
```

### Template Commands
```bash
# Create project with absolute path
bash scripts/create-project.sh python /home/user/my-project
bash scripts/create-project.sh cpp /home/user/my-project

# Sync configs (use absolute path)
bash scripts/sync-templates.sh python /home/user/existing-project

# Verify setup
bash scripts/verify-setup.sh
```

---

**Happy Coding!** 🚀

---

**Last Updated:** 2025-10-13
**Version:** 1.0
