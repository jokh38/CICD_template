# Linux Development Environment Setup

Part of the CICD Template System - Modular Setup Scripts

This directory contains modular scripts for setting up GitHub Actions self-hosted runners and development environments on Linux systems (Ubuntu/Debian/RHEL).

## 📁 File Structure

```
linux/
├── core/                            # Core system dependencies
│   └── install-system-deps.sh       # System packages and dependencies
├── tools/                           # Development tools
│   ├── install-compilers.sh         # Compiler tools (GCC, Clang)
│   ├── install-build-tools.sh       # Build tools (CMake, Ninja)
│   ├── install-sccache.sh           # Compilation caching
│   ├── install-cpp-frameworks.sh    # C++ testing frameworks
│   └── install-python-tools.sh      # Python development tools
├── config/                          # Configuration setup
│   ├── setup-code-formatting.sh     # Code formatting configurations
│   └── setup-ai-workflows.sh        # AI workflow templates
├── validation/                      # Testing and validation
│   ├── create-test-projects.sh      # Create test projects for validation
│   └── run-validation.sh            # Run validation tests
├── install-runner-linux.sh          # GitHub Actions runner setup
├── runner-config.yaml               # Runner configuration
└── README.md                        # This file
```

**Note**: For Windows setup, see the `../windows/` directory.
**Note**: Use `../total_run.sh` for complete orchestrated setup.

## Quick Start

### Option 1: Complete Orchestration (Recommended)

```bash
# From setup-scripts root directory
sudo ./total_run.sh
```

This will install everything: system dependencies, compilers, build tools, C++ and Python development environments, configurations, and run validation.

### Option 2: Modular Installation

#### Install System Dependencies and Runner

```bash
# Install system dependencies
sudo ./core/install-system-deps.sh

# Install GitHub Actions runner
sudo ./install-runner-linux.sh
```

#### Install Development Tools

```bash
# Basic tools (compilers + build tools)
sudo ./tools/install-compilers.sh
sudo ./tools/install-build-tools.sh

# Python development tools
sudo ./tools/install-python-tools.sh

# C++ development tools
sudo ./tools/install-sccache.sh
sudo ./tools/install-cpp-frameworks.sh

# Configuration setup
sudo ./config/setup-code-formatting.sh
sudo ./config/setup-ai-workflows.sh

# Validation
./validation/create-test-projects.sh
sudo ./validation/run-validation.sh
```

### Option 3: Selective Installation

```bash
# C++ development only
sudo ./total_run.sh --cpp-only

# Python development only
sudo ./total_run.sh --python-only

# Basic tools only
sudo ./total_run.sh --basic
```

## What Gets Installed

### Core Components
- **System dependencies**: build-essential, git, curl, etc.
- **Compilers**: GCC/G++, Clang/LLVM
- **Build tools**: CMake, Ninja, Meson
- **GitHub Actions runner**: Configured as systemd service

### Python Development
- **ruff**: Ultra-fast linting and formatting
- **pytest**: Testing framework with coverage
- **mypy**: Static type checking
- **pre-commit**: Git hooks management
- **Additional**: black, isort, flake8, bandit, pipx

### C++ Development
- **sccache**: Compilation caching for faster builds
- **Google Test**: Testing framework
- **Catch2**: Modern testing framework
- **Google Benchmark**: Performance testing
- **clang-format**: Code formatting
- **clang-tidy**: Static analysis

### Configurations
- **Global configs**: `.clang-format`, `.clang-tidy`, `ruff.toml`
- **CMake presets**: Debug and release configurations
- **AI workflows**: GitHub Actions templates
- **Shell aliases**: Development shortcuts for both languages

## Configuration

The `runner-config.yaml` file contains comprehensive configuration options for:

- Runner settings and labels
- Python and C++ tool configurations
- sccache cache settings
- Performance tuning
- Security hardening
- Monitoring and logging
- Backup and recovery

To use custom configuration:
```bash
# Edit the config file as needed
nano runner-config.yaml

# The scripts will read from this file for advanced configuration
```

## Validation

Each setup script includes validation tests:

```bash
# Validate Python tools setup
sudo ./setup-python-tools.sh --validate-only

# Validate C++ tools setup
sudo ./setup-cpp-tools.sh --validate-only
```

## Runner Management

### Check Runner Status

```bash
# Check systemd service status
systemctl status actions.runner.*.service

# Check runner logs
journalctl -u actions.runner.*.service -f

# Check GitHub runner status
sudo -u github-runner ./actions-runner/run.sh --once --check
```

### Start/Stop Runner

```bash
# Start runner
sudo systemctl start actions.runner.*.service

# Stop runner
sudo systemctl stop actions.runner.*.service

# Restart runner
sudo systemctl restart actions.runner.*.service
```

### Update Runner

```bash
cd /opt/actions-runner
sudo -u github-runner ./svc.sh stop
sudo -u github-runner ./run.sh --update
sudo -u github-runner ./svc.sh start
```

## Development Aliases

The setup scripts create useful aliases for the `github-runner` user:

### Python Aliases
```bash
lint        # Run ruff check and format check
fmt         # Run ruff check with fix and format
test        # Run pytest
cov         # Run pytest with coverage
typecheck   # Run mypy
precommit-run # Run pre-commit on all files
```

### C++ Aliases
```bash
cmake-debug     # Configure debug build
cmake-release   # Configure release build
build-debug     # Build debug configuration
build-release   # Build release configuration
test-debug      # Run debug tests
test-release    # Run release tests
format-clang    # Format all C++ files
lint-clang      # Run clang-tidy on all C++ files
sccache-stats   # Show sccache statistics
sccache-zero    # Reset sccache statistics
```

## Performance Optimization

### sccache Configuration

The C++ setup includes sccache for compilation caching:

```bash
# Check cache statistics
sudo -u github-runner sccache --show-stats

# Reset statistics
sudo -u github-runner sccache --zero-stats

# Clear cache
sudo -u github-runner rm -rf /home/github-runner/.cache/sccache/*
```

### Python Tool Performance

```bash
# Switch to the github-runner user
sudo -u github-runner bash

# Test ruff performance
time ruff check /path/to/project

# Test pytest performance
time pytest /path/to/project
```

## Security Considerations

1. **Runner User**: Scripts create a dedicated non-root user for security
2. **File Permissions**: Proper file permissions are set throughout
3. **Service Management**: Runner runs as a systemd service with proper isolation
4. **Network Access**: Runner only needs outbound HTTPS to GitHub

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Ensure scripts are executable
   chmod +x *.sh

   # Run as root
   sudo ./install-runner-linux.sh
   ```

2. **Runner Not Connecting**
   ```bash
   # Check service status
   systemctl status actions.runner.*.service

   # Check logs
   journalctl -u actions.runner.*.service -f

   # Verify token is valid
   # Get new token from GitHub repository/organization settings
   ```

3. **Build Tools Not Found**
   ```bash
   # Re-run setup scripts
   sudo ./setup-python-tools.sh
   sudo ./setup-cpp-tools.sh
   ```

4. **sccache Not Working**
   ```bash
   # Check sccache server
   sudo -u github-runner sccache --start-server
   sudo -u github-runner sccache --show-stats

   # Check environment variables
   sudo -u github-runner env | grep SCCACHE
   ```

### Log Locations

- **Runner logs**: `journalctl -u actions.runner.*.service`
- **System logs**: `/var/log/syslog` or `/var/log/messages`
- **sccache logs**: Check the runner's output for sccache messages
- **Build logs**: In GitHub Actions UI or runner's work directory

## Advanced Configuration

### Custom Labels

Edit the runner configuration or re-run config with custom labels:

```bash
sudo -u github-runner ./config.sh \
    --labels "self-hosted,Linux,X64,custom-label"
```

### Resource Limits

Update `runner-config.yaml` to adjust resource limits:

```yaml
performance:
  resources:
    max_memory: "16G"
    max_cpu_cores: 8
```

### Cache Storage

Configure sccache to use cloud storage in `runner-config.yaml`:

```yaml
sccache:
  storage:
    type: "s3"
    s3:
      bucket: "your-sccache-bucket"
      region: "us-west-2"
```

## Integration with Templates

Once the runner is set up, update your project workflows to use it:

```yaml
# .github/workflows/ci.yaml
name: CI

on: [push, pull_request]

jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/python-ci-reusable.yaml@v1
    with:
      runner-type: 'self-hosted'  # Use your new runner
      python-version: '3.10'
```

## Support

For issues with:
- **GitHub Actions**: Check [GitHub Actions documentation](https://docs.github.com/en/actions)
- **sccache**: Check [sccache documentation](https://github.com/mozilla/sccache)
- **CMake/Ninja**: Check respective documentation
- **This template**: Create an issue in the template repository