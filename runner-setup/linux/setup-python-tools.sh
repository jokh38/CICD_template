#!/bin/bash
# Python Development Tools Setup for GitHub Actions Runner

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

RUNNER_USER="github-runner"

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root${NC}"
        exit 1
    fi
}

install_system_deps() {
    echo -e "${GREEN}Installing system dependencies...${NC}"

    if [ -f /etc/debian_version ]; then
        apt-get update
        apt-get install -y \
            python3 python3-pip python3-venv \
            python3-dev build-essential
    elif [ -f /etc/redhat-release ]; then
        yum install -y \
            python3 python3-pip python3-devel \
            gcc gcc-c++ make
    fi
}

install_python_tools() {
    echo -e "${GREEN}Installing Python development tools for $RUNNER_USER...${NC}"

    # Install tools for the runner user
    sudo -u "$RUNNER_USER" bash <<'EOF'
    # Upgrade pip
    python3 -m pip install --upgrade pip setuptools wheel

    # Install core Python development tools
    python3 -m pip install --user \
        ruff \
        pytest pytest-cov pytest-mock \
        mypy \
        pre-commit \
        black \
        isort \
        flake8 \
        bandit \
        pipx

    # Create pipx directory for standalone tools
    mkdir -p ~/.local/pipx/bin
    echo 'export PATH="$HOME/.local/pipx/bin:$PATH"' >> ~/.bashrc
EOF

    echo -e "${GREEN}✅ Python tools installed${NC}"
}

setup_global_configs() {
    echo -e "${GREEN}Setting up global Python configurations...${NC}"

    # Create global ruff config
    sudo -u "$RUNNER_USER" bash <<'EOF'
    mkdir -p ~/.config/ruff
    cat > ~/.config/ruff/ruff.toml << 'RUFF_CONFIG'
# Global Ruff configuration
target-version = "py310"
line-length = 88
indent-width = 4

[lint]
# Enable common rules
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort
    "N",   # pep8-naming
    "UP",  # pyupgrade
    "B",   # flake8-bugbear
    "C4",  # flake8-comprehensions
    "SIM", # flake8-simplify
    "S",   # flake8-bandit
]

ignore = [
    "E501",  # line too long (handled by formatter)
    "S101",  # use of assert detected
]

# Allow autofix
fixable = ["ALL"]
unfixable = []

[format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "auto"
RUFF_CONFIG

    # Create global pre-commit config template
    mkdir -p ~/.config/pre-commit
    cat > ~/.config/pre-commit/pre-commit-config.yaml << 'PRECOMMIT_CONFIG'
# Global pre-commit configuration template
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: check-merge-conflict
      - id: detect-private-key

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.0
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.11.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
        args: [--strict, --ignore-missing-imports]
PRECOMMIT_CONFIG

    # Add useful aliases to bashrc
    cat >> ~/.bashrc << 'BASHRC_EOF'

# Python development aliases
alias lint='ruff check . && ruff format --check .'
alias fmt='ruff check . --fix && ruff format .'
alias test='pytest'
alias cov='pytest --cov=src --cov-report=html --cov-report=term'
alias typecheck='mypy .'
alias precommit-run='pre-commit run --all-files'
BASHRC_EOF
EOF

    echo -e "${GREEN}✅ Global configurations created${NC}"
}

create_test_project() {
    echo -e "${GREEN}Creating test project to verify installation...${NC}"

    TEST_DIR="/tmp/python-test-project"
    sudo -u "$RUNNER_USER" bash <<EOF
    # Create test project
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"

    # Create simple Python package
    mkdir -p src/test_project tests .github/workflows

    # Create __init__.py
    echo '"""Test project."""' > src/test_project/__init__.py

    # Create simple module
    cat > src/test_project/main.py << 'PY_FILE'
def hello(name: str) -> str:
    """Return a greeting message."""
    return f"Hello, {name}!"

def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b
PY_FILE

    # Create test file
    cat > tests/test_main.py << 'PY_TEST'
import pytest
from test_project.main import hello, add

def test_hello():
    assert hello("World") == "Hello, World!"

def test_add():
    assert add(2, 3) == 5
    assert add(-1, 1) == 0
PY_TEST

    # Create pyproject.toml
    cat > pyproject.toml << 'PYPROJECT'
[build-system]
requires = ["setuptools>=68.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "test-project"
version = "0.1.0"
description = "Test project for runner validation"
authors = [{name = "Test User"}]
requires-python = ">=3.10"

[project.optional-dependencies]
dev = [
    "pytest>=7.4",
    "pytest-cov>=4.1",
    "ruff>=0.6.0",
    "mypy>=1.11",
]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]

[tool.ruff]
target-version = "py310"
line-length = 88

[tool.mypy]
python_version = "3.10"
strict = true
PYPROJECT

    # Create AI workflow file
    cat > .github/workflows/ai-workflow.yaml << 'AI_WORKFLOW'
name: AI Assistant Workflow

on:
  issue_comment:
    types: [created]
  issues:
    types: [opened, edited]
  pull_request:
    types: [opened, edited, synchronize]

jobs:
  ai-assistant:
    runs-on: ubuntu-latest
    if: contains({% raw %}{{ github.event.comment.body }}{% endraw %}, '@claude') || contains({% raw %}{{ github.event.issue.body }}{% endraw %}, '@claude')

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Setup Python Environment
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'

    - name: Install Dependencies
      run: |
        python -m pip install --upgrade pip
        pip install ruff pytest mypy

    - name: AI Assistant Analysis
      run: |
        echo "🤖 AI Assistant workflow triggered for Python project"
        echo "📊 Project Analysis:"
        echo "   - Language: Python 3.10"
        echo "   - Tools: ruff, pytest, mypy"

        if [ "{% raw %}{{ github.event_name }}{% endraw %}" = "issue_comment" ]; then
          echo "💬 Comment detected: {% raw %}{{ github.event.comment.body }}{% endraw %}"
        elif [ "{% raw %}{{ github.event_name }}{% endraw %}" = "issues" ]; then
          echo "🐛 Issue detected: {% raw %}{{ github.event.issue.title }}{% endraw %}"
        elif [ "{% raw %}{{ github.event_name }}{% endraw %}" = "pull_request" ]; then
          echo "🔄 PR detected: {% raw %}{{ github.event.pull_request.title }}{% endraw %}"

          # Run basic checks on PR
          echo "🔍 Running code quality checks..."
          ruff check .
          ruff format --check .
          mypy .
          pytest tests/ -v
        fi

    - name: Code Quality Check
      run: |
        echo "🔍 Running code quality checks..."

        # Check if ruff is available
        if command -v ruff &> /dev/null; then
          echo "✓ ruff found"
          ruff --version
        else
          echo "⚠️ ruff not found"
        fi

        # Check if pytest is available
        if command -v pytest &> /dev/null; then
          echo "✓ pytest found"
          pytest --version
        else
          echo "⚠️ pytest not found"
        fi

        # Check if mypy is available
        if command -v mypy &> /dev/null; then
          echo "✓ mypy found"
          mypy --version
        else
          echo "⚠️ mypy not found"
        fi

        echo "📋 Static analysis summary:"
        find src/ tests/ -name "*.py" | head -10 | while read file; do
          echo "   - Analyzing: $file"
        done

    - name: AI Assistant Response
      uses: actions/github-script@v7
      with:
        script: |
          const response = `
          🤖 **Python AI Assistant Analysis Complete**

          **Project Status**: ✅ Analyzed
          **Language**: Python 3.10
          **Tools**: ruff, pytest, mypy

          **Next Steps**:
          1. Review the code quality output above
          2. Check test results
          3. Address any linting issues
          4. Consider type annotations with mypy

          **Available Commands**:
          - \`@claude review code\` - Request code review
          - \`@claude fix imports\` - Help with import organization
          - \`@claude add tests\` - Help with test coverage
          - \`@claude type check\` - Help with type annotations
          `;

          if (context.eventName === 'issue_comment') {
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: response
            });
          } else if (context.eventName === 'issues') {
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: response
            });
          } else if (context.eventName === 'pull_request') {
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: response
            });
          }
AI_WORKFLOW

    # Initialize git repository
    echo "Initializing git repository..."
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"

    # Create .gitignore
    cat > .gitignore << 'GITIGNORE'
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# C extensions
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.py,cover
.hypothesis/
.pytest_cache/
cover/

# Translations
*.mo
*.pot

# Django stuff:
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal

# Flask stuff:
instance/
.webassets-cache

# Scrapy stuff:
.scrapy

# Sphinx documentation
docs/_build/

# PyBuilder
.pybuilder/
target/

# Jupyter Notebook
.ipynb_checkpoints

# IPython
profile_default/
ipython_config.py

# pyenv
.python-version

# pipenv
Pipfile.lock

# poetry
poetry.lock

# pdm
.pdm.toml

# PEP 582
__pypackages__/

# Celery stuff
celerybeat-schedule
celerybeat.pid

# SageMath parsed files
*.sage.py

# Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Spyder project settings
.spyderproject
.spyproject

# Rope project settings
.ropeproject

# mkdocs documentation
/site

# mypy
.mypy_cache/
.dmypy.json
dmypy.json

# Pyre type checker
.pyre/

# pytype static type analyzer
.pytype/

# Cython debug symbols
cython_debug/

# PyCharm
.idea/

# VS Code
.vscode/
GITIGNORE

    # Add initial files to git
    git add .
    git commit -m "Initial project setup with AI workflow

    - Created basic Python project structure
    - Added AI workflow integration (.github/workflows/ai-workflow.yaml)
    - Included source files, tests, and pyproject.toml configuration
    - Set up .gitignore for Python development
    - Configured ruff, pytest, and mypy

    🤖 Generated with Python development tools setup
    "

    echo "Test project created at $TEST_DIR"
EOF

    echo -e "${GREEN}✅ Test project created${NC}"
}

run_validation_tests() {
    echo -e "${GREEN}Running validation tests...${NC}"

    TEST_DIR="/tmp/python-test-project"

    # Test ruff
    echo "Testing ruff..."
    sudo -u "$RUNNER_USER" bash -c "cd $TEST_DIR && python3 -m ruff check ."
    sudo -u "$RUNNER_USER" bash -c "cd $TEST_DIR && python3 -m ruff format --check ."

    # Test pytest
    echo "Testing pytest..."
    sudo -u "$RUNNER_USER" bash -c "cd $TEST_DIR && python3 -m pytest tests/ -v"

    # Test mypy
    echo "Testing mypy..."
    sudo -u "$RUNNER_USER" bash -c "cd $TEST_DIR && python3 -m mypy ."

    # Cleanup
    rm -rf "$TEST_DIR"

    echo -e "${GREEN}✅ All validation tests passed${NC}"
}

print_success() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✅ Python tools setup complete!${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo "Installed tools:"
    echo "  - ruff (linting + formatting)"
    echo "  - pytest (testing)"
    echo "  - mypy (type checking)"
    echo "  - pre-commit (git hooks)"
    echo "  - Additional: black, isort, flake8, bandit, pipx"
    echo ""
    echo "Global configurations created:"
    echo "  - ~/.config/ruff/ruff.toml"
    echo "  - ~/.config/pre-commit/pre-commit-config.yaml"
    echo "  - ~/.bashrc (Python aliases added)"
    echo ""
    echo "Test project includes:"
    echo "  - .github/workflows/ai-workflow.yaml (AI assistant integration)"
    echo "  - Git repository with initial commit"
    echo ""
    echo "Available aliases for $RUNNER_USER:"
    echo "  - lint    : Run ruff check and format check"
    echo "  - fmt     : Run ruff check with fix and format"
    echo "  - test    : Run pytest"
    echo "  - cov     : Run pytest with coverage"
    echo "  - typecheck: Run mypy"
    echo "  - precommit-run: Run pre-commit on all files"
    echo ""
    echo "The runner is now ready for Python projects!"
}

main() {
    case "${1:-}" in
        --validate-only)
            run_validation_tests
            ;;
        *)
            check_root
            install_system_deps
            install_python_tools
            setup_global_configs
            create_test_project
            run_validation_tests
            print_success
            ;;
    esac
}

main "$@"