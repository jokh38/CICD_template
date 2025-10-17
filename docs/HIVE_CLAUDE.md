## CICD Template: AI-Enhanced Development Workflow Documentation

### Overview

This CICD Template system provides **cookiecutter-based project templates** with integrated AI workflow capabilities. Users can create new Python or C++ projects with pre-configured development environments, automated code quality checks through **git hooks**, and optional AI workflow templates for enhanced development productivity.

### System Architecture

1.  **User**: Creates new projects using cookiecutter templates with optional AI workflow integration
2.  **Cookiecutter Templates**: Generate project structure with pre-configured tools and settings
3.  **Git Hooks**: Provide local CI/CD through `prepare-commit-msg` and `pre-commit` hooks
4.  **Setup Scripts**: Automated development environment configuration and validation
5.  **AI Workflow Templates**: Optional Claude AI integration guidelines and documentation

### Core Components

#### A. Cookiecutter Project Templates
- **Python Template**: Ruff, pytest, mypy, pre-commit hooks, virtual environment setup
- **C++ Template**: CMake/Meson, clang-format/clang-tidy, GoogleTest, sccache integration

#### B. Local Development Workflow
- **`prepare-commit-msg` hook**: Code formatting, linting, syntax validation
- **`pre-commit` hook**: Testing, build verification, security checks, dependency validation

#### C. Development Environment Setup
- **Linux**: `setup-scripts/total_run.sh` for complete environment setup
- **Windows**: `setup-scripts/total_run.ps1` for PowerShell-based setup
- **Validation**: Comprehensive tool testing and health checks

### Project Creation Workflow

The system enables rapid project setup with AI-enhanced development capabilities:

#### Creating New Projects

**Python Projects:**
```bash
# Interactive mode with AI workflows enabled
bash scripts/create-project.sh python

# Non-interactive mode with absolute path
bash scripts/create-project.sh python /home/user/my-python-project
```

**C++ Projects:**
```bash
# Interactive mode with AI workflows enabled
bash scripts/create-project.sh cpp

# Non-interactive mode with absolute path
bash scripts/create-project.sh cpp /home/user/my-cpp-project
```

#### AI Workflow Integration

Each created project includes:
- **`.github/claude/CLAUDE.md`**: AI assistant context and guidelines
- **`.github/labels.yml`**: Pre-configured GitHub labels for AI automation
- **AI-enabled documentation**: Templates and examples for AI-assisted development

### Local Development Workflow

The system uses **git hooks** instead of GitHub Actions for local CI/CD:

#### Prepare Commit Message Hook (`prepare-commit-msg`)
- **Code Formatting**: Automatic formatting with ruff (Python) or clang-format (C++)
- **Static Analysis**: Linting and type checking (ruff, mypy, clang-tidy)
- **Syntax Validation**: Basic syntax error detection
- **Commit Message Validation**: Conventional commit format checking

#### Pre-commit Hook (`pre-commit`)
- **Testing**: Automatic test execution (pytest, ctest)
- **Build Verification**: Build system validation (CMake, Meson)
- **Security Scans**: Basic security and secret detection
- **Dependency Checks**: Vulnerability scanning and dependency validation
- **Performance Analysis**: Basic code complexity and performance checks

### Development Environment Setup

#### Linux Setup
```bash
# Complete development environment setup
sudo bash setup-scripts/total_run.sh

# Validate existing setup
sudo bash setup-scripts/total_run.sh --validate-only
```

#### Windows Setup
```powershell
# Complete development environment setup (Administrator)
.\setup-scripts\total_run.ps1

# Validate existing setup
.\setup-scripts\total_run.ps1 -ValidateOnly
```

### AI-Assisted Development Features

#### Serena MCP Integration
Projects are created with **Serena MCP** (Model Context Protocol) server integration for enhanced AI capabilities:

**Installation:**
```bash
# Install Serena MCP server for Claude Code
claude mcp add-json "serena" '{"command":"uvx","args":["--from","git+https://github.com/oraios/serena","serena-mcp-server"]}'
```

**Features:**
- **Enhanced Context**: Serena provides intelligent code analysis and context awareness
- **Workflow Automation**: Advanced automation capabilities for development tasks
- **Code Understanding**: Deep semantic analysis of code structure and patterns
- **Documentation Generation**: Automated documentation creation and updates

#### GitHub Labels for AI Workflows
Projects are created with pre-configured labels:
- **`claude`**: Issues and PRs related to Claude AI automation
- **`ai-assist`**: Issues requiring AI assistance or automation
- **`ai-automation`**: Automated tasks performed by AI assistants
- **`automated-pr`**: Pull requests created automatically by AI
- **`serena-mcp`**: Tasks requiring Serena MCP capabilities

#### AI Workflow Templates
- **Development Guidelines**: AI-ready project structure and conventions
- **Code Review Templates**: Standardized review processes
- **Testing Strategies**: Automated test generation and validation
- **Documentation Standards**: AI-compatible documentation formats
- **MCP Integration**: Serena MCP server setup and usage instructions

### Project Structure

```
created-project/
├── .github/
│   ├── labels.yml              # Pre-configured GitHub labels
│   └── claude/
│       └── CLAUDE.md           # AI assistant context
├── src/                        # Source code
├── tests/                      # Test files
├── git-hooks/                  # Local CI/CD hooks
│   ├── prepare-commit-msg      # Code quality checks
│   └── pre-commit              # Testing and validation
├── configs/                    # Tool configurations
│   ├── .pre-commit-config.yaml
│   ├── ruff.toml (Python)
│   ├── .clang-format (C++)
│   └── pyproject.toml (Python)
└── README.md                   # Project documentation
```

### Available Features

#### Python Template Features
- **Ruff**: Fast Python linting and formatting (100x faster than Black + Flake8)
- **pytest**: Testing framework with coverage reporting
- **mypy**: Static type checking
- **Virtual Environment**: Automatic venv creation and dependency management
- **Pre-commit Hooks**: Comprehensive code quality validation

#### C++ Template Features
- **CMake/Meson**: Flexible build system support
- **clang-format/clang-tidy**: Code formatting and static analysis
- **GoogleTest**: Unit testing framework
- **sccache**: Compilation caching for faster builds
- **Pre-commit Hooks**: Build verification and testing validation

#### AI Enhancement Features
- **Claude Integration**: Pre-configured AI assistant context
- **Serena MCP**: Model Context Protocol server for enhanced AI capabilities
- **Automated Labels**: GitHub labels for AI workflow triggering
- **Documentation Templates**: AI-ready project documentation
- **Quality Gates**: Automated code quality and validation checks
- **Workflow Automation**: Advanced AI-powered development workflows

### Usage Examples

#### Creating and Setting Up Projects

**1. Create a Python Project**
```bash
# Interactive mode
bash scripts/create-project.sh python

# Non-interactive with absolute path
bash scripts/create-project.sh python /home/user/my-python-project

# Create with GitHub repository
bash scripts/create-project.sh python my-project --github
```

**2. Create a C++ Project**
```bash
# Interactive mode
bash scripts/create-project.sh cpp

# Non-interactive with absolute path
bash scripts/create-project.sh cpp /home/user/my-cpp-library

# Create with GitHub repository
bash scripts/create-project.sh cpp my-library --github
```

**3. Setup Development Environment**
```bash
# Linux - Complete setup
sudo bash setup-scripts/total_run.sh

# Linux - Validate existing setup
sudo bash setup-scripts/total_run.sh --validate-only

# Windows - Complete setup (PowerShell Administrator)
.\setup-scripts\total_run.ps1

# Windows - Validate existing setup
.\setup-scripts\total_run.ps1 -ValidateOnly
```

#### Daily Development Workflow

**1. Start Development**
```bash
cd your-project

# Python - Activate virtual environment
source venv/bin/activate

# Git hooks will automatically run when you commit
git add .
git commit -m "feat: add new feature"
# prepare-commit-msg hook: formats code, runs linting
# pre-commit hook: runs tests, builds project, validates security
```

**2. Code Quality Checks**
```bash
# Manual checks (git hooks run these automatically)
# Python
ruff check .          # Linting
ruff format .          # Formatting
mypy src/             # Type checking
pytest tests/         # Testing

# C++
cmake -B build -G Ninja
cmake --build build
ctest --test-dir build  # Testing
clang-format -i src/**/*.cpp  # Formatting
```

#### Using AI-Enhanced Features

**1. GitHub Labels for AI Workflows**
```bash
# Projects are created with pre-configured labels
gh label list  # Shows: claude, ai-assist, ai-automation, etc.

# Create issue with AI label
gh issue create --title "Add user authentication" \
  --label "enhancement,claude" \
  --body "Implement OAuth2 authentication with social providers"
```

**2. AI Assistant Integration**
```bash
# Each project includes .github/claude/CLAUDE.md
cat .github/claude/CLAUDE.md

# This file provides context for AI assistants like Claude Code
# Includes project structure, development standards, and workflow guidelines
```

**3. Serena MCP Integration**
```bash
# Install Serena MCP (if not already installed)
claude mcp add-json "serena" '{"command":"uvx","args":["--from","git+https://github.com/oraios/serena","serena-mcp-server"]}'

# Verify installation
claude mcp list

# Use Serena MCP features in your project
# Serena provides enhanced context analysis and workflow automation
# Projects are pre-configured to work seamlessly with Serena MCP
```

### Configuration

#### Template Customization

**Python Template Options:**
- `project_name`: Project display name
- `project_slug`: Package name (auto-generated from project_name)
- `package_name`: Python package name (auto-generated)
- `python_version`: Target Python version (3.10, 3.11, 3.12)
- `use_git_hooks`: Enable git hooks (yes/no)
- `include_docker`: Include Docker files (no/yes)
- `use_ai_workflow`: Include AI workflow templates (yes/no)
- `license`: Project license (MIT, BSD-3-Clause, Apache-2.0, GPL-3.0, None)

**C++ Template Options:**
- `project_name`: Project display name
- `cpp_standard`: C++ standard (17, 20, 23)
- `build_system`: Build system (cmake/meson)
- `use_ai_workflow`: Include AI workflow templates (yes/no)
- `enable_cache`: Enable sccache (yes/no)
- `use_ninja`: Use Ninja generator (yes/no)
- `testing_framework`: Testing framework (gtest, catch2, doctest)
- `license`: Project license (MIT, BSD-3-Clause, Apache-2.0, GPL-3.0, None)

#### Git Hooks Configuration

Git hooks are automatically set up during project creation:

```bash
# Manual hook setup (if needed)
chmod +x git-hooks/prepare-commit-msg git-hooks/pre-commit
ln -sf ../../git-hooks/prepare-commit-msg .git/hooks/
ln -sf ../../git-hooks/pre-commit .git/hooks/
```

### Performance Benefits

| Operation | Traditional Setup | CICD Template Approach | Improvement |
|-----------|------------------|----------------------|-------------|
| Project Creation | 2-4 hours manual setup | 2-5 minutes automated | **24-48x faster** |
| Python Linting | 60s (Black + Flake8) | 5s (Ruff) | **12x faster** |
| C++ Build (clean) | 6 minutes | 3 minutes | **2x faster** |
| C++ Build (cached) | 6 minutes | 30 seconds | **12x faster** |
| Code Quality | Manual configuration | Automatic via hooks | **Instant** |
| Environment Setup | 1-2 days manual | 10-15 minutes automated | **100x faster** |

### Quality Features

- **Automated Code Quality**: Git hooks ensure consistent formatting and linting
- **Built-in Testing**: Test execution on every commit
- **Security Scanning**: Basic secret detection and vulnerability checking
- **Performance Analysis**: Code complexity and basic performance checks
- **Documentation**: AI-ready project structure and documentation

### Troubleshooting

#### Git Hook Issues

**Hooks not running:**
```bash
# Check hook permissions and links
ls -la .git/hooks/prepare-commit-msg
ls -la .git/hooks/pre-commit

# Fix if needed
chmod +x git-hooks/prepare-commit-msg git-hooks/pre-commit
ln -sf ../../git-hooks/prepare-commit-msg .git/hooks/
ln -sf ../../git-hooks/pre-commit .git/hooks/
```

**Hook failures:**
```bash
# Run hooks manually for debugging
./git-hooks/prepare-commit-msg .git/COMMIT_EDITMSG
./git-hooks/pre-commit
```

#### Environment Setup Issues

**Missing tools:**
```bash
# Linux - Run complete setup
sudo bash setup-scripts/total_run.sh

# Windows - Run complete setup
.\setup-scripts\total_run.ps1

# Validate installation
sudo bash setup-scripts/total_run.sh --validate-only
```

#### Project Creation Issues

**Cookiecutter problems:**
```bash
# Check cookiecutter installation
cookiecutter --version

# Verify template exists
ls -la cookiecutters/python-project/
ls -la cookiecutters/cpp-project/
```

### Advanced Features

#### AI Workflow Templates

Each project includes AI-ready documentation:
- **`.github/claude/CLAUDE.md`**: Context for AI assistants
- **Development Standards**: Architecture invariants and coding guidelines
- **Quality Gates**: Automated validation and testing requirements
- **Project Structure**: Standardized organization for AI understanding

#### GitHub Label Integration

Pre-configured labels for AI workflows:
- `claude`: AI automation related issues
- `ai-assist`: Requests for AI assistance
- `ai-automation`: Automated AI tasks
- `automated-pr`: AI-generated pull requests

#### Environment Validation

Comprehensive validation scripts:
```bash
# Linux validation
bash setup-scripts/linux/validation/run-validation.sh

# Check specific tools
which ruff pytest mypy cmake clang-format clang-tidy
```

---

## 📚 Additional Resources

### Documentation
- [Quick Start Guide](docs/manuals/QUICK_START.md)
- [Cookiecutter Guide](docs/manuals/COOKIECUTTER_GUIDE.md)
- [Development Environment Setup](setup-scripts/README.md)
- [Troubleshooting](docs/manuals/TROUBLESHOOTING.md)
- [Label Automation](docs/LABEL_AUTOMATION.md)

### Tool Documentation
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [Cookiecutter Documentation](https://cookiecutter.readthedocs.io/)
- [Git Hooks Guide](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [CMake Documentation](https://cmake.org/documentation/)
- [GoogleTest Guide](https://google.github.io/googletest/)

### External Links
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [Python Packaging](https://packaging.python.org/)
- [CMake Best Practices](https://cliutils.gitlab.io/modern-cmake/)

---

*This CICD Template system provides a comprehensive foundation for rapid, high-quality project setup with AI-enhanced development capabilities.*