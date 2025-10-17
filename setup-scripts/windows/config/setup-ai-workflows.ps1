#!/usr/bin/env pwsh
# Setup AI Workflow Templates for Windows

param(
    [string]$DeveloperUser = "developer"
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Status {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[SUCCESS] $Message" "Green"
}

function Write-Error-Output {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

# Function to create AI workflow templates directory
function New-AIWorkflowDirectory {
    Write-Status "Creating AI workflow templates directory..."

    try {
        $workflowDir = Join-Path $env:USERPROFILE ".config\ai-workflows"
        if (-not (Test-Path $workflowDir)) {
            New-Item -Path $workflowDir -ItemType Directory -Force | Out-Null
        }

        # Create subdirectories
        $subdirs = @("templates", "scripts", "examples")
        foreach ($subdir in $subdirs) {
            $subPath = Join-Path $workflowDir $subdir
            if (-not (Test-Path $subPath)) {
                New-Item -Path $subPath -ItemType Directory -Force | Out-Null
            }
        }

        return $workflowDir

    } catch {
        Write-Error-Output "Failed to create AI workflow directory: $($_.Exception.Message)"
        throw
    }
}

# Function to create C++ development workflow template
function New-CppDevelopmentTemplate {
    param(
        [string]$WorkflowDir
    )

    Write-Status "Creating C++ development workflow template..."

    try {
        $templatePath = Join-Path $WorkflowDir "templates\cpp-development.md"

        $templateContent = @"
# C++ Development Workflow Template (Windows)

## Prerequisites
- Visual Studio 2022 or Build Tools
- CMake 3.16+
- vcpkg package manager
- Git for Windows
- clang-format, clang-tidy

## Project Setup
1. Create project structure
2. Configure CMake and vcpkg
3. Setup code formatting and linting
4. Configure testing frameworks (Google Test, Catch2)
5. Setup pre-commit hooks

## Code Development Process
1. **Write tests first** (TDD approach)
2. **Implement functionality**
3. **Run code formatting** (clang-format)
4. **Run static analysis** (clang-tidy)
5. **Execute tests** (ctest, Google Test)
6. **Perform code review**

## Windows-Specific Commands

### Using Developer Command Prompt
\`\`\`cmd
# Open Developer Command Prompt for VS 2022
"C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

# Configure project with CMake
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -DCMAKE_TOOLCHAIN_FILE=C:\Program Files\vcpkg\scripts\buildsystems\vcpkg.cmake

# Build project
cmake --build build --config Release --parallel

# Run tests
ctest --test-dir build --build-config Release --output-on-failure
\`\`\`

### Using PowerShell
\`\`\`powershell
# Configure project
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -DCMAKE_TOOLCHAIN_FILE="C:\Program Files\vcpkg\scripts\buildsystems\vcpkg.cmake"

# Build project
cmake --build build --config Release --parallel

# Run tests
ctest --test-dir build --build-config Release --output-on-failure

# Run clang-format
Get-ChildItem -Recurse -Include *.cpp,*.hpp,*.h | ForEach-Object { clang-format -i $_.FullName }

# Run clang-tidy
run-clang-tidy -p build src/**/*.cpp
\`\`\`

### Using Ninja (faster builds)
\`\`\`powershell
# Configure with Ninja
cmake -S . -B build -G Ninja -DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl -DCMAKE_TOOLCHAIN_FILE="C:\Program Files\vcpkg\scripts\buildsystems\vcpkg.cmake"

# Build (much faster)
cmake --build build --parallel
\`\`\`

## Code Quality Gates
- [ ] All tests must pass
- [ ] Code coverage > 80%
- [ ] No clang-tidy warnings
- [ ] Code follows clang-format standards
- [ ] Static analysis passes
- [ ] No memory leaks (AddressSanitizer)
- [ ] Performance benchmarks meet criteria

## AI Assistant Prompts for C++

### Code Generation
- "Generate a C++ class for [specific functionality] with proper RAII, move semantics, and modern C++17 features"
- "Create a unit test using Google Test for this function with edge cases and exception handling"
- "Refactor this legacy C++ code to use modern C++17/20 features"

### Debugging Help
- "Help me debug this segmentation fault. Here's the stack trace and relevant code"
- "Explain this template metaprogramming code and suggest simplifications"
- "Analyze this memory leak and suggest fixes using smart pointers"

### Code Review
- "Review this C++ code for potential issues, performance problems, and modernization opportunities"
- "Suggest improvements for exception safety and thread safety in this code"
- "Help me optimize this algorithm for better cache performance on x86_64"

## Windows Development Tips

### Visual Studio Integration
- Use CMake Tools extension for VS Code
- Configure vcpkg integration in CMakePresets.json
- Use AddressSanitizer and UndefinedBehaviorSanitizer

### Performance Profiling
- Use Visual Studio Profiler or Intel VTune
- Use Windows Performance Analyzer
- Use clang's built-in sanitizers

### Package Management
- Use vcpkg for C++ dependencies
- Configure CMake to find vcpkg packages automatically
- Use Conan for complex dependency management

## Troubleshooting Common Issues

### Build Issues
- **Linker errors**: Check vcpkg triplet and library paths
- **Missing headers**: Verify include directories in CMake
- **CMake configuration**: Clear build directory and reconfigure

### Formatting Issues
- **clang-format not working**: Check .clang-format file location
- **Inconsistent formatting**: Verify file encoding (UTF-8) and line endings

### Testing Issues
- **Google Test not found**: Ensure vcpkg installed gtest
- **Test discovery**: Check CTest configuration in CMakeLists.txt

## Example Project Structure
\`\`\`
my-project/
├── CMakeLists.txt
├── CMakePresets.json
├── .clang-format
├── .clang-tidy
├── vcpkg.json
├── src/
│   ├── calculator.cpp
│   └── calculator.h
├── include/
│   └── calculator.h
├── tests/
│   ├── test_calculator.cpp
│   └── CMakeLists.txt
├── docs/
│   └── README.md
└── scripts/
    └── build.ps1
\`\`\`
"@

        $templateContent | Out-File -FilePath $templatePath -Encoding UTF8 -Force

        Write-Success "C++ development workflow template created"

    } catch {
        Write-Error-Output "Failed to create C++ development template: $($_.Exception.Message)"
        throw
    }
}

# Function to create Python development workflow template
function New-PythonDevelopmentTemplate {
    param(
        [string]$WorkflowDir
    )

    Write-Status "Creating Python development workflow template..."

    try {
        $templatePath = Join-Path $WorkflowDir "templates\python-development.md"

        $templateContent = @"
# Python Development Workflow Template (Windows)

## Prerequisites
- Python 3.8+ (installed via Chocolatey or python.org)
- PowerShell 5.1+ or PowerShell Core
- Git for Windows
- Windows Terminal (recommended)

## Project Setup
1. Create virtual environment
2. Install dependencies (poetry, pip-tools)
3. Configure code formatting and linting
4. Setup testing framework (pytest)
5. Configure pre-commit hooks

## Code Development Process
1. **Write tests first** (TDD approach)
2. **Implement functionality**
3. **Run code formatting** (black, ruff)
4. **Execute tests** (pytest)
5. **Perform type checking** (mypy)
6. **Run security analysis** (bandit)

## Windows-Specific Commands

### PowerShell Commands
\`\`\`powershell
# Create virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements-dev.txt

# Run code formatting
black src/ tests/
ruff check src/ tests/
ruff format src/ tests/

# Run tests with coverage
pytest tests/ --cov=src --cov-report=html --cov-report=term-missing

# Type checking
mypy src/

# Security analysis
bandit -r src/

# Run pre-commit hooks manually
pre-commit run --all-files
\`\`\`

### Using Poetry (Recommended)
\`\`\`powershell
# Install Poetry
curl -sSL https://install.python-poetry.org | python3 -

# Create new project
poetry new my-project
cd my-project

# Add dependencies
poetry add numpy pandas
poetry add --group dev pytest black ruff mypy

# Run commands in poetry environment
poetry run pytest
poetry run black src/
poetry run ruff check src/

# Activate virtual environment
poetry shell
\`\`\`

### Using Windows Terminal
\`\`\`json
// Add to Windows Terminal settings.json
{
    "name": "Python Dev",
    "commandline": "pwsh.exe -NoExit -Command '& { & \"C:\\\\path\\\\to\\\\venv\\\\Scripts\\\\Activate.ps1\" }'",
    "startingDirectory": "%USERPROFILE%\\dev\\python"
}
\`\`\`

## Code Quality Gates
- [ ] All tests must pass
- [ ] Code coverage > 85%
- [ ] No type errors (mypy)
- [ ] No security issues (bandit)
- [ ] Code follows formatting standards (black, ruff)
- [ ] No code smells (complexity, duplication)

## AI Assistant Prompts for Python

### Code Generation
- "Generate a Python class for [specific functionality] with proper type hints, docstrings, and error handling"
- "Create a pytest test suite for this function with parametrized tests and fixtures"
- "Help me refactor this Python code to use async/await and context managers"

### Debugging Help
- "Help me debug this Python exception. Here's the traceback and relevant code"
- "Explain this metaclass code and suggest a simpler approach"
- "Analyze this performance bottleneck and suggest optimizations using cProfile"

### Code Review
- "Review this Python code for PEP 8 compliance, type hints, and best practices"
- "Suggest improvements for exception handling and logging in this code"
- "Help me optimize this data processing pipeline using pandas and numpy"

## Windows Development Tips

### Performance Optimization
- Use PyPy for CPU-bound tasks
- Use asyncio for I/O-bound operations
- Profile with cProfile and memory_profiler
- Use numba or cython for critical sections

### Package Management
- Use Poetry for dependency management
- Use pip-tools for requirements.txt generation
- Configure private package repositories

### Virtual Environment Management
- Use virtualenvwrapper-win for easy venv management
- Configure .venv in .gitignore
- Use direnv for automatic activation

## Troubleshooting Common Issues

### Environment Issues
- **PowerShell execution policy**: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **Virtual environment activation**: Use `Activate.ps1` instead of `activate.bat`
- **Path issues**: Restart PowerShell after installing Python packages

### Dependency Conflicts
- Use poetry for better dependency resolution
- Create separate virtual environments for each project
- Use pip-tools to pin dependency versions

### Performance Issues
- Use conda for scientific computing packages
- Configure Python to use UTF-8 encoding
- Optimize imports and reduce startup time

## Example Project Structure
\`\`\`
my-project/
├── pyproject.toml
├── poetry.lock
├── README.md
├── src/
│   └── my_package/
│       ├── __init__.py
│       ├── calculator.py
│       └── utils.py
├── tests/
│   ├── __init__.py
│   ├── test_calculator.py
│   └── conftest.py
├── docs/
│   └── README.md
├── scripts/
│   └── setup.ps1
├── .git/
│   └── hooks/
│       ├── prepare-commit-msg
│       └── pre-commit
├── .gitignore
├── .pre-commit-config.yaml
└── .vscode/
    ├── settings.json
    └── extensions.json
\`\`\`
"@

        $templateContent | Out-File -FilePath $templatePath -Encoding UTF8 -Force

        Write-Success "Python development workflow template created"

    } catch {
        Write-Error-Output "Failed to create Python development template: $($_.Exception.Message)"
        throw
    }
}

# Function to create Git workflow template
function New-GitWorkflowTemplate {
    param(
        [string]$WorkflowDir
    )

    Write-Status "Creating Git workflow template..."

    try {
        $templatePath = Join-Path $WorkflowDir "templates\git-workflow.md"

        $templateContent = @"
# Git Workflow Template (Windows)

## Branch Strategy
- \`main\`: Production-ready code
- \`develop\`: Integration branch for features
- \`feature/*\`: Individual features
- \`hotfix/*\`: Critical fixes
- \`release/*\`: Release preparation

## Commit Message Format
\`\`\`
type(scope): subject

body

footer
\`\`\`

### Types
- \`feat\`: New feature
- \`fix\`: Bug fix
- \`docs\`: Documentation
- \`style\`: Code style (formatting, missing semicolons)
- \`refactor\`: Code refactoring
- \`test\`: Adding or updating tests
- \`chore\`: Build process, maintenance
- \`perf\`: Performance improvements
- \`ci\`: CI/CD changes

### Scopes
- \`ui\`: User interface components
- \`api\`: API endpoints and services
- \`config\`: Configuration files
- \`build\`: Build system and dependencies
- \`docs\`: Documentation
- \`test\`: Test infrastructure

## Windows Git Workflow Commands

### Using Git Bash (Recommended for Git operations)
\`\`\`bash
# Start new feature
git checkout -b feature/calculator-module

# Commit changes
git add .
git commit -m "feat(calculator): add advanced mathematical operations"

# Push and create PR
git push origin feature/calculator-module

# Sync with main branch
git checkout main
git pull origin main
git checkout feature/calculator-module
git rebase main
\`\`\`

### Using PowerShell
\`\`\`powershell
# Start new feature
git checkout -b feature/calculator-module

# Stage changes
git add .

# Commit with template
git commit -m "feat(calculator): add advanced mathematical operations

- Added support for trigonometric functions
- Improved error handling for division by zero
- Updated unit tests to cover new functionality

Closes #123"

# Push and create PR
git push origin feature/calculator-module

# Interactive rebase (clean up commits)
git rebase -i HEAD~3
\`\`\`

## Pull Request Template
\`\`\`markdown
## Description
Brief description of the change and why it's needed.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring (no functional changes)

## Testing
- [ ] All tests pass on Windows
- [ ] Manual testing completed on Windows 10/11
- [ ] Cross-platform compatibility tested (if applicable)
- [ ] Performance benchmarks pass

## Windows-Specific Testing
- [ ] Tested on PowerShell 5.1 and PowerShell Core
- [ ] Path handling works with Windows paths (backslashes)
- [ ] File permissions and NTFS considerations
- [ ] Environment variable handling

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] Git hooks validation passes
- [ ] Security considerations addressed

## Screenshots (if applicable)
Add screenshots to help explain your changes.

## Additional Context
Add any other context about the change here.
\`\`\`

## Pre-commit Hooks Setup (Windows)

### Install pre-commit
\`\`\`powershell
pip install pre-commit

# Install hooks
pre-commit install

# Run on all files
pre-commit run --all-files
\`\`\`

### .pre-commit-config.yaml example
\`\`\`yaml
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
\`\`\`

## Windows Git Configuration

### .gitconfig for Windows
\`\`\`ini
[user]
    name = Your Name
    email = your.email@example.com

[core]
    autocrlf = true
    eol = crlf
    precomposeunicode = true
    protectNTFS = true
    filemode = false

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    unstage = reset HEAD --
    last = log -1 HEAD
    graph = log --oneline --graph --decorate --all
    Amend = commit --amend --no-edit
    fixup = commit --fixup
    squash = !git rebase -i --autosquash
    tree = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit

[pull]
    rebase = true

[push]
    default = simple

[rebase]
    autosquash = true
    autostash = true

[init]
    defaultBranch = main
\`\`\`

## Troubleshooting Git Issues on Windows

### Line Ending Issues
\`\`\`powershell
# Fix line endings
git add --renormalize .
git commit -m "Fix line endings"

# Check line endings
git ls-files --eol
\`\`\`

### Permission Issues
\`\`\`powershell
# Fix file permissions
git config core.filemode false

# Remove locked files
git clean -fd
\`\`\`

### Long Path Issues
\`\`\`powershell
# Enable long path support in Windows 10/11
# This requires administrator privileges
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
\`\`\`

## Git GUI Tools for Windows

### Recommended Tools
- **GitKraken**: Visual Git client with great UX
- **SourceTree**: Free Git GUI from Atlassian
- **GitHub Desktop**: Simple Git client for GitHub
- **Git Extensions**: Powerful Git GUI with integration

### VS Code Git Integration
- Source Control panel (Ctrl+Shift+G)
- GitLens extension for enhanced Git capabilities
- Git Graph extension for branch visualization
\`\`\`
"@

        $templateContent | Out-File -FilePath $templatePath -Encoding UTF8 -Force

        Write-Success "Git workflow template created"

    } catch {
        Write-Error-Output "Failed to create Git workflow template: $($_.Exception.Message)"
        throw
    }
}

# Function to create CI/CD workflow templates
function New-GitHooksTemplate {
    param(
        [string]$WorkflowDir
    )

    Write-Status "Creating Git Hooks workflow templates..."

    try {
        $templatePath = Join-Path $WorkflowDir "templates\git-hooks-workflow.md"

        $templateContent = @"
# Git Hooks Workflow Template (Windows)

## Hook Configuration
This template uses git hooks to replace GitHub Actions CI/CD pipeline on Windows.

### Hook Types Used
- \`prepare-commit-msg\`: Code formatting, linting, and commit message validation
- \`pre-commit\`: Testing, build verification, and comprehensive validation

### Hook Setup Commands (PowerShell)
\`\`\`powershell
# Install git hooks
Set-ItemProperty -Path ".\git-hooks\prepare-commit-msg" -Name IsReadOnly -Value `$false
Set-ItemProperty -Path ".\git-hooks\pre-commit" -Name IsReadOnly -Value `$false
Copy-Item ".\git-hooks\prepare-commit-msg" ".git/hooks\" -Force
Copy-Item ".\git-hooks\pre-commit" ".git/hooks\" -Force

# Or use the setup script
.\setup-scripts\windows\config\setup-git-hooks.ps1
\`\`\`

### Hook Validation Flow on Windows
1. **prepare-commit-msg hook** runs:
   - Code formatting (ruff, black, clang-format)
   - Static analysis (mypy, clang-tidy)
   - Syntax validation
   - Commit message format checking

2. **pre-commit hook** runs:
   - Unit tests (pytest, ctest)
   - Build verification (CMake, Visual Studio)
   - Security scans (bandit, safety checks)
   - Dependency validation
   - Performance analysis

### Windows-Specific Hook Configuration
\`\`\`powershell
# .git/hooks/prepare-commit-msg (Windows)
#!/usr/bin/env pwsh
# PowerShell implementation of prepare-commit-msg hook

# Import required modules
Import-Module Microsoft.PowerShell.Utility

# Determine project type
`$projectType = `$null
if (Test-Path "pyproject.toml") { `$projectType = "python" }
elseif (Test-Path "CMakeLists.txt") { `$projectType = "cpp" }

# Run formatting and linting
switch (`$projectType) {
    "python" {
        if (Get-Command ruff -ErrorAction SilentlyContinue) {
            ruff check --fix --exit-non-zero-on-fix .
            ruff format .
        }
        if (Get-Command mypy -ErrorAction SilentlyContinue) {
            mypy src/
        }
    }
    "cpp" {
        if (Get-Command clang-format -ErrorAction SilentlyContinue) {
            Get-ChildItem -Recurse -Include *.cpp,*.hpp | ForEach-Object {
                clang-format -i `$_.FullName
            }
        }
    }
}
\`\`\`

### Local Development Workflow (Windows)
\`\`\`powershell
# Make changes to your code
git add .
git commit -m "feat: add new feature"  # Triggers prepare-commit-msg hook
                                    # Then triggers pre-commit hook

# If all checks pass, commit is created
# If any check fails, commit is blocked with error details

# Run hooks manually if needed
.\.git\hooks\prepare-commit-msg .git/COMMIT_EDITMSG message ""
.\.git\hooks\pre-commit
\`\`\`

### Windows Git Hooks Troubleshooting

#### PowerShell Execution Policy
\`\`\`powershell
# Set execution policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass execution policy for specific scripts
powershell -ExecutionPolicy Bypass -File ".git/hooks/pre-commit"
\`\`\`

#### Line Ending Issues
\`\`\`cmd
# Configure git for Windows
git config --global core.autocrlf true
git config --global core.eol crlf

# Fix existing files
git add --renormalize .
git commit -m "Fix line endings for Windows"
\`\`\`

#### Path Separator Issues
\`\`\`powershell
# Use PowerShell's path Join-Path for cross-platform compatibility
`$buildPath = Join-Path "." "build"
`$srcPath = Join-Path "." "src"

# Or use forward slashes in git hooks (works on Windows too)
`$buildPath = "./build"
`$srcPath = "./src"
\`\`\`

### Quality Gates (Windows)
- All tests must pass in PowerShell environment
- Code coverage thresholds met
- No linting errors (ruff, mypy, clang-tidy)
- No security vulnerabilities (bandit, safety)
- Build must succeed with Visual Studio or CMake
- Commit message follows conventional format
- PowerShell execution policy configured correctly

### Integration with Windows Development Tools

#### Visual Studio Integration
- Git hooks run automatically when committing via Visual Studio
- Configure Visual Studio to use UTF-8 encoding
- Set up Visual Studio Git integration to respect hooks

#### VS Code Integration
- Git hooks run automatically when committing via VS Code
- Configure VS Code to use PowerShell as default terminal
- Install GitLens and Git Graph extensions for better Git experience

#### Windows Terminal Integration
\`\`\`json
// Windows Terminal settings.json profile
{
    "name": "Git Dev",
    "commandline": "pwsh.exe -NoExit -Command 'Set-Location C:\\\\dev\\\\my-project'",
    "startingDirectory": "C:\\\\dev\\\\my-project",
    "icon": "🔧"
}
\`\`\`

### Performance Optimization for Windows
\`\`\`powershell
# Optimize PowerShell startup
Add-Content `$PROFILE "`$env:POWERSHELL_UPDATECHECK = 'Off'"

# Use parallel execution where possible
`$files = Get-ChildItem -Recurse -Include *.cpp,*.hpp
`$files | ForEach-Object -ThrottleLimit 4 -Parallel {
    clang-format -i `$_.FullName
}
\`\`\`

### Example Windows Git Hook Scripts

#### Enhanced pre-commit hook for Windows
\`\`\`powershell
#!/usr/bin/env pwsh
`$ErrorActionPreference = "Stop"

Write-Host "🚀 Running Windows pre-commit hook..." -ForegroundColor Cyan

# Check for virtual environment (Python projects)
if (Test-Path "venv") {
    & ".\venv\Scripts\Activate.ps1"
    Write-Host "🐍 Python virtual environment activated" -ForegroundColor Green
}

# Run tests based on project type
if (Test-Path "pyproject.toml") {
    Write-Host "🧪 Running Python tests..." -ForegroundColor Yellow
    pytest tests/ --cov=src --cov-report=term-missing
} elseif (Test-Path "CMakeLists.txt") {
    Write-Host "🔧 Running C++ tests..." -ForegroundColor Yellow
    if (Test-Path "build") {
        ctest --test-dir build --output-on-failure
    } else {
        Write-Warning "Build directory not found. Run CMake configuration first."
    }
}

Write-Host "✅ All checks passed!" -ForegroundColor Green
\`\`\`

#### Enhanced prepare-commit-msg hook for Windows
\`\`\`powershell
#!/usr/bin/env pwsh
`$ErrorActionPreference = "Stop"

Write-Host "🔍 Running Windows prepare-commit-msg hook..." -ForegroundColor Cyan

# Run formatting
if (Get-Command ruff -ErrorAction SilentlyContinue) {
    Write-Host "📝 Running ruff formatting..." -ForegroundColor Yellow
    ruff format .
    ruff check --fix .
}

if (Get-Command black -ErrorAction SilentlyContinue) {
    Write-Host "📝 Running black formatting..." -ForegroundColor Yellow
    black .
}

# Run type checking
if (Get-Command mypy -ErrorAction SilentlyContinue) {
    Write-Host "🔍 Running mypy type checking..." -ForegroundColor Yellow
    mypy src/
}

Write-Host "✅ Code quality checks passed!" -ForegroundColor Green
\`\`\`
"@

        $templateContent | Out-File -FilePath $templatePath -Encoding UTF8 -Force

        Write-Success "Git Hooks workflow template created"

    } catch {
        Write-Error-Output "Failed to create Git Hooks template: $($_.Exception.Message)"
        throw
    }
}

# Function to create PowerShell scripts for common tasks
function New-PowerShellScripts {
    param(
        [string]$WorkflowDir
    )

    Write-Status "Creating PowerShell helper scripts..."

    try {
        $scriptsDir = Join-Path $WorkflowDir "scripts"

        # Development aliases script
        $aliasesPath = Join-Path $scriptsDir "dev-aliases.ps1"

        $aliasesContent = @"
# Development aliases for AI-assisted workflows (Windows)
# Add this to your PowerShell profile or run it in each session

# Python development aliases
function py-test { pytest tests/ --cov=src --cov-report=html --cov-report=term-missing }
function py-lint { ruff check src/ tests/; mypy src/ }
function py-format { black src/ tests/; ruff format src/ tests/ }
function py-secure { bandit -r src/ }
function py-clean { Remove-Item -Recurse -Force .pytest_cache, .mypy_cache, __pycache__, .coverage, htmlcov -ErrorAction SilentlyContinue }

# C++ development aliases
function cpp-build { cmake --build build --parallel }
function cpp-test { ctest --test-dir build --output-on-failure }
function cpp-format { Get-ChildItem -Recurse -Include *.cpp,*.hpp | ForEach-Object { clang-format -i `$_.FullName } }
function cpp-lint { run-clang-tidy -p build src/**/*.cpp }
function cpp-clean { Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue }

# Git aliases
function gs { git status }
function ga { git add . }
function gc { git commit }
function gp { git push }
function gl { git pull }
function gr { git rebase }
function gf { git fetch }
function ggraph { git log --oneline --graph --decorate --all }

# Project management aliases
function proj-init { param([string]`$name) python -m cookiecutter gh:cookiecutter/cookiecutter-pypackage --output-dir `$name }
function proj-venv { python -m venv venv; .\venv\Scripts\Activate.ps1 }
function proj-install { pip install -r requirements-dev.txt; pre-commit install }

# Quality check aliases
function quality-check { py-lint; py-test; if (Get-Command run-clang-tidy -ErrorAction SilentlyContinue) { cpp-lint } }
function pre-commit-check { pre-commit run --all-files }

# Development environment aliases
function dev-setup { & "`$PSScriptRoot\setup-dev-env.ps1" }
function dev-clean { py-clean; cpp-clean; git clean -fd }

# Windows-specific aliases
function refresh-env { `$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User") }
function admin-shell { Start-Process powershell -Verb RunAs }

# Helper function to set up a new project directory
function New-DevProject {
    param(
        [string]`$Name,
        [string]`$Type = "python"  # python, cpp, mixed
    )

    `$projectPath = Join-Path `$HOME "dev" `$Name
    New-Item -Path `$projectPath -ItemType Directory -Force | Out-Null
    Set-Location `$projectPath

    Write-Host "Created new project directory: `$projectPath" -ForegroundColor Green

    switch (`$Type) {
        "python" {
            py-venv
            Write-Host "Python virtual environment created. Run 'proj-install' to setup dependencies." -ForegroundColor Yellow
        }
        "cpp" {
            New-Item -Path "src", "include", "tests", "build" -ItemType Directory | Out-Null
            Write-Host "C++ project structure created." -ForegroundColor Yellow
        }
        "mixed" {
            New-Item -Path "src", "include", "tests", "build", "python", "scripts" -ItemType Directory | Out-Null
            py-venv
            Write-Host "Mixed Python/C++ project structure created." -ForegroundColor Yellow
        }
    }
}

# Export functions
Export-ModuleMember -Function *
"@

        $aliasesContent | Out-File -FilePath $aliasesPath -Encoding UTF8 -Force

        Write-Success "PowerShell helper scripts created"

    } catch {
        Write-Error-Output "Failed to create PowerShell scripts: $($_.Exception.Message)"
        throw
    }
}

# Function to create example configurations
function New-ExampleConfigurations {
    param(
        [string]$WorkflowDir
    )

    Write-Status "Creating example configurations..."

    try {
        $examplesDir = Join-Path $WorkflowDir "examples"

        # Windows Terminal configuration
        $terminalConfigPath = Join-Path $examplesDir "windows-terminal-settings.json"

        $terminalConfig = @{
            profiles = @{
                defaults = @{
                    fontFace = "Cascadia Code"
                    fontSize = 12
                    colorScheme = "Campbell Powershell"
                }
                list = @(
                    @{
                        name = "Python Dev"
                        commandline = "pwsh.exe -NoExit -Command '& { & \"$env:USERPROFILE\\dev\\python\\venv\\Scripts\\Activate.ps1\" }'"
                        startingDirectory = "%USERPROFILE%\\dev\\python"
                        icon = "🐍"
                    },
                    @{
                        name = "C++ Dev"
                        commandline = "cmd.exe /k \"C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat\""
                        startingDirectory = "%USERPROFILE%\\dev\\cpp"
                        icon = "⚙️"
                    },
                    @{
                        name = "PowerShell"
                        commandline = "pwsh.exe"
                        startingDirectory = "%USERPROFILE%"
                        icon = "💻"
                    }
                )
            }
            schemes = @(
                @{
                    name = "Dev Theme"
                    background = "#1E1E1E"
                    foreground = "#FFFFFF"
                    cursorColor = "#FFFFFF"
                    black = "#0C0C0C"
                    red = "#C50F1F"
                    green = "#13A10E"
                    yellow = "#C19C00"
                    blue = "#0037DA"
                    purple = "#881798"
                    cyan = "#3A96DD"
                    white = "#CCCCCC"
                    brightBlack = "#767676"
                    brightRed = "#E74856"
                    brightGreen = "#16C60C"
                    brightYellow = "#F9F1A5"
                    brightBlue = "#3B78FF"
                    brightPurple = "#B4009E"
                    brightCyan = "#61D6D6"
                    brightWhite = "#F2F2F2"
                }
            )
        }

        $terminalConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $terminalConfigPath -Encoding UTF8 -Force

        Write-Success "Example configurations created"

    } catch {
        Write-Warning "Failed to create example configurations: $($_.Exception.Message)"
    }
}

# Main setup
try {
    Write-Status "Starting Windows AI workflow templates setup..."

    # Create directory structure
    $workflowDir = New-AIWorkflowDirectory

    # Create templates
    New-CppDevelopmentTemplate -WorkflowDir $workflowDir
    New-PythonDevelopmentTemplate -WorkflowDir $workflowDir
    New-GitWorkflowTemplate -WorkflowDir $workflowDir
    New-GitHooksTemplate -WorkflowDir $workflowDir

    # Create scripts and examples
    New-PowerShellScripts -WorkflowDir $workflowDir
    New-ExampleConfigurations -WorkflowDir $workflowDir

    Write-Success "AI workflow templates created successfully"
    Write-Status "Templates are available in: $workflowDir"
    Write-Status ""
    Write-Status "Next steps:"
    Write-Status "1. Import PowerShell aliases: . $workflowDir\scripts\dev-aliases.ps1"
    Write-Status "2. Review the workflow templates in $workflowDir\templates\"
    Write-Status "3. Customize templates for your specific needs"
    Write-Status "4. Add the scripts to your PowerShell profile for automatic loading"

} catch {
    Write-Error-Output "AI workflow templates setup failed: $($_.Exception.Message)"
    exit 1
}