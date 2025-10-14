# Development Environment Setup Scripts

This directory contains modular setup scripts for configuring GitHub Actions runners with C++ and Python development environments.

## 📁 Directory Structure

```
setup-scripts/
├── README.md                    # This file
├── total_run.sh                 # Linux orchestration script
├── total_run.ps1                # Windows orchestration script
├── linux/                       # Linux-specific scripts
│   ├── core/                    # Core system dependencies
│   │   └── install-system-deps.sh
│   ├── tools/                   # Development tools
│   │   ├── install-compilers.sh
│   │   ├── install-build-tools.sh
│   │   ├── install-sccache.sh
│   │   ├── install-cpp-frameworks.sh
│   │   └── install-python-tools.sh
│   ├── config/                  # Configuration setup
│   │   ├── setup-git-config.sh
│   │   ├── setup-code-formatting.sh
│   │   └── setup-ai-workflows.sh
│   ├── validation/              # Testing and validation
│   │   ├── create-test-projects.sh
│   │   └── run-validation.sh
│   ├── install-runner-linux.sh  # GitHub Actions runner setup
│   ├── runner-config.yaml       # Runner configuration
│   └── README.md               # Linux-specific documentation
└── windows/                     # Windows-specific scripts
    ├── core/                    # Core system dependencies
    │   └── install-system-deps.ps1
    ├── tools/                   # Development tools
    │   ├── install-compilers.ps1
    │   ├── install-build-tools.ps1
    │   ├── install-sccache.ps1
    │   ├── install-cpp-frameworks.ps1
    │   └── install-python-tools.ps1
    ├── config/                  # Configuration setup
    │   ├── setup-git-config.ps1
    │   └── setup-code-formatting.ps1
    ├── install-runner-windows.ps1 # GitHub Actions runner setup
    ├── runner-config-windows.yaml # Runner configuration
    └── README.md               # Windows-specific documentation
```

## 🚀 Quick Start

### Linux

```bash
# Full installation (recommended)
sudo ./total_run.sh

# Basic tools only
sudo ./total_run.sh --basic

# C++ tools only
sudo ./total_run.sh --cpp-only

# Python tools only
sudo ./total_run.sh --python-only

# Run validation only
sudo ./total_run.sh --validate-only

# Show help
./total_run.sh --help
```

### Windows (PowerShell - Administrator)

```powershell
# Full installation (recommended)
.\total_run.ps1

# Basic tools only
.\total_run.ps1 -Basic

# C++ tools only
.\total_run.ps1 -CppOnly

# Python tools only
.\total_run.ps1 -PythonOnly

# Run validation only
.\total_run.ps1 -ValidateOnly

# Show help
.\total_run.ps1 -Help
```

## 📋 What Gets Installed

### Core System Dependencies
- **Linux**: build-essential, cmake, ninja, git, curl, etc.
- **Windows**: Visual Studio Build Tools, Chocolatey, Git, Python

### Compiler Tools
- **GCC/G++** (GNU Compiler Collection)
- **Clang/LLVM** (Modern C++ compiler)
- **MSVC** (Windows only)
- **MinGW-w64** (Windows alternative)

### Build Tools
- **CMake** (3.20+)
- **Ninja** (Fast build system)
- **Meson** (Alternative build system)

### Development Tools

#### C++ Tools
- **sccache** (Compilation caching)
- **Google Test** (Testing framework)
- **Catch2** (Testing framework)
- **Google Benchmark** (Performance testing)
- **clang-format** (Code formatting)
- **clang-tidy** (Static analysis)

#### Python Tools
- **ruff** (Linting and formatting)
- **pytest** (Testing framework)
- **mypy** (Type checking)
- **pre-commit** (Git hooks)
- **black** (Code formatting)
- **isort** (Import sorting)

### Configuration Files
- **Git**: Global git configuration, user settings, aliases, commit templates
- **C++**: `.clang-format`, `.clang-tidy`, CMake presets
- **Python**: `ruff.toml`, pre-commit configurations
- **AI Workflows**: GitHub Actions templates for Claude assistance

### Git Configuration
- **User setup**: Configured with Kwanghyun Jo <jokh38@gmail.com>
- **Global aliases**: Common shortcuts (st, co, br, cm, lg, etc.)
- **Global .gitignore**: Comprehensive ignore patterns
- **Commit template**: Standardized commit message format
- **Credentials helper**: Configured for seamless authentication

## 🔧 Modular Usage

Each script can be run independently for specific needs:

### Linux Examples
```bash
# Install only system dependencies
sudo ./linux/core/install-system-deps.sh

# Install only C++ frameworks
sudo ./linux/tools/install-cpp-frameworks.sh

# Setup code formatting configurations
./linux/config/setup-code-formatting.sh

# Setup git configuration
./linux/config/setup-git-config.sh

# Create test projects
./linux/validation/create-test-projects.sh
```

### Windows Examples
```powershell
# Install only system dependencies
.\windows\core\install-system-deps.ps1

# Install only Python tools
.\windows\tools\install-python-tools.ps1

# Setup code formatting configurations
.\windows\config\setup-code-formatting.ps1

# Setup git configuration
.\windows\config\setup-git-config.ps1
```

## 🧪 Validation

The setup includes comprehensive validation:

- **Compiler verification**: Ensures all compilers are working
- **Build system testing**: Tests CMake/Ninja integration
- **Framework validation**: Verifies testing frameworks work
- **Tool functionality**: Confirms formatting and linting tools operate correctly

## 🤖 AI Integration

The setup creates AI workflow templates that enable:
- **Code review automation**
- **Build failure analysis**
- **Test coverage assistance**
- **Performance optimization suggestions**

## 📝 Environment Variables

The scripts configure these environment variables automatically:

### sccache
- `SCCACHE_DIR`: Cache directory location
- `SCCACHE_CACHE_SIZE`: Maximum cache size (10GB)
- `CMAKE_C_COMPILER_LAUNCHER`: sccache integration
- `CMAKE_CXX_COMPILER_LAUNCHER`: sccache integration

### CMake
- `CMAKE_EXPORT_COMPILE_COMMANDS`: Enabled for IDE support

## 🔄 Post-Installation Steps

1. **Restart your shell/terminal** to apply PATH changes
2. **Verify installation** by running validation:
   ```bash
   ./total_run.sh --validate-only  # Linux
   .\total_run.ps1 -ValidateOnly   # Windows
   ```
3. **Test with a project** to ensure everything works
4. **Check aliases** are available in your shell

## 🐛 Troubleshooting

### Common Issues

1. **Permission denied**: Run with sudo/Administrator privileges
2. **PATH not updated**: Restart terminal or log out/in
3. **Tools not found**: Check if installation completed successfully
4. **Validation failures**: Run individual scripts to isolate issues

### Getting Help

```bash
# Linux
./total_run.sh --help

# Windows
.\total_run.ps1 -Help
```

## 🤝 Contributing

When adding new tools or configurations:

1. **Create modular scripts** in the appropriate subdirectory
2. **Update orchestration scripts** to include new components
3. **Add validation tests** for new tools
4. **Update documentation** with new features

## 📄 License

This setup script collection is provided as-is for development environment configuration. Use at your own risk and review scripts before execution in production environments.

---

**Version**: 3.0.0 (Modular Setup)
**Last Updated**: 2025-10-14
**Status**: Production Ready
**Supported Platforms**: Windows, Linux (Ubuntu/Debian/RHEL)