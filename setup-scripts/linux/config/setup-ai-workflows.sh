#!/bin/bash
# Setup AI Workflow Templates

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

# Create AI workflow templates directory
WORKFLOW_DIR="$HOME/.config/ai-workflows"
mkdir -p "$WORKFLOW_DIR"

print_status "Setting up AI workflow templates..."

# Create C++ development workflow template
cat > "$WORKFLOW_DIR/cpp-development.md" << 'EOF'
# C++ Development Workflow Template

## Project Setup
1. Initialize project structure
2. Configure CMake and build system
3. Setup code formatting and linting
4. Configure testing frameworks

## Code Development
1. Write tests first (TDD approach)
2. Implement functionality
3. Run clang-format and clang-tidy
4. Execute tests
5. Perform code review

## Build and Test Commands
```bash
# Configure project
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release

# Build project
cmake --build build --parallel

# Run tests
ctest --test-dir build --output-on-failure

# Run clang-format
clang-format -i src/**/*.cpp src/**/*.hpp include/**/*.hpp

# Run clang-tidy
run-clang-tidy -p build src/**/*.cpp
```

## Quality Gates
- All tests must pass
- Code coverage > 80%
- No clang-tidy warnings
- Code follows formatting standards
EOF

# Create Python development workflow template
cat > "$WORKFLOW_DIR/python-development.md" << 'EOF'
# Python Development Workflow Template

## Project Setup
1. Create virtual environment
2. Install dependencies
3. Configure code formatting and linting
4. Setup testing framework

## Code Development
1. Write tests first (TDD approach)
2. Implement functionality
3. Run code formatting (black, ruff)
4. Execute tests
5. Perform type checking (mypy)
6. Run security analysis (bandit)

## Development Commands
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements-dev.txt

# Run code formatting
black src/ tests/
ruff check src/ tests/
ruff format src/ tests/

# Run tests
pytest tests/ --cov=src --cov-report=html

# Type checking
mypy src/

# Security analysis
bandit -r src/
```

## Quality Gates
- All tests must pass
- Code coverage > 85%
- No type errors
- No security issues
- Code follows formatting standards
EOF

# Create Git workflow template
cat > "$WORKFLOW_DIR/git-workflow.md" << 'EOF'
# Git Workflow Template

## Branch Strategy
- `main`: Production-ready code
- `develop`: Integration branch for features
- `feature/*`: Individual features
- `hotfix/*`: Critical fixes
- `release/*`: Release preparation

## Commit Message Format
```
type(scope): subject

body

footer
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, missing semicolons)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process, maintenance

## Workflow Commands
```bash
# Start new feature
git checkout -b feature/feature-name

# Commit changes
git add .
git commit -m "feat(scope): add new feature"

# Push and create PR
git push origin feature/feature-name

# Sync with main branch
git checkout main
git pull origin main
git checkout feature/feature-name
git rebase main
```

## Pull Request Template
```markdown
## Description
Brief description of the change

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] All tests pass
- [ ] Code coverage maintained
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```
EOF

# Create CI/CD workflow template
cat > "$WORKFLOW_DIR/cicd-template.yml" << 'EOF'
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: [3.8, 3.9, '3.10']

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements-dev.txt

    - name: Lint with ruff
      run: |
        ruff check src/ tests/
        ruff format --check src/ tests/

    - name: Type check with mypy
      run: mypy src/

    - name: Test with pytest
      run: |
        pytest tests/ --cov=src --cov-report=xml

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3

  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install bandit

    - name: Run security scan
      run: bandit -r src/
EOF

# Create pre-commit configuration template
cat > "$WORKFLOW_DIR/pre-commit-config.yaml" << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: debug-statements

  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black
        language_version: python3

  - repo: https://github.com/charliermarsh/ruff-pre-commit
    rev: v0.0.272
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.3.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]

  - repo: https://github.com/PyCQA/bandit
    rev: 1.7.5
    hooks:
      - id: bandit
        args: [-r, src/]
EOF

# Create helpful aliases
cat > "$WORKFLOW_DIR/aliases.sh" << 'EOF'
# Development aliases for AI-assisted workflows

# Python development
alias py-test='pytest tests/ --cov=src --cov-report=html'
alias py-lint='ruff check src/ tests/ && mypy src/'
alias py-format='black src/ tests/ && ruff format src/ tests/'
alias py-secure='bandit -r src/'

# C++ development
alias cpp-build='cmake --build build --parallel'
alias cpp-test='ctest --test-dir build --output-on-failure'
alias cpp-format='clang-format -i src/**/*.cpp src/**/*.hpp include/**/*.hpp'
alias cpp-lint='run-clang-tidy -p build src/**/*.cpp'

# Git workflow
alias gs='git status'
alias ga='git add .'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gr='git rebase'
alias gf='git fetch'

# Quality checks
alias quality-check='py-lint && py-test && cpp-lint && cpp-test'
alias pre-commit-check='pre-commit run --all-files'
EOF

print_success "AI workflow templates created successfully"
print_status "Templates are available in: $WORKFLOW_DIR"