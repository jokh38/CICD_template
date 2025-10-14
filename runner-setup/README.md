# GitHub Actions Self-Hosted Runner Setup

This directory contains scripts and configuration files for setting up GitHub Actions self-hosted runners on Ubuntu Linux systems.

## Files Overview

- `install-runner-linux.sh` - Main runner installation script
- `setup-python-tools.sh` - Python development tools setup
- `setup-cpp-tools.sh` - C++ development tools setup
- `runner-config.yaml` - Comprehensive runner configuration
- `README.md` - This documentation file

## Quick Start

### 1. Install GitHub Actions Runner

```bash
# Run as root
sudo ./install-runner-linux.sh
```

This will:
- Install system dependencies
- Create a dedicated `github-runner` user
- Download and configure the GitHub Actions runner
- Install and start the systemd service

You'll be prompted for:
- GitHub URL (e.g., https://github.com/your-org)
- Registration token (from GitHub repository/organization settings)
- Runner name (optional, defaults to hostname)

### 2. Setup Development Tools

After installing the runner, choose your development environment:

#### Python Development Tools

```bash
sudo ./install-runner-linux.sh --setup-python
# or
sudo ./setup-python-tools.sh
```

Installs:
- ruff (linting + formatting)
- pytest (testing)
- mypy (type checking)
- pre-commit (git hooks)
- Additional tools: black, isort, flake8, bandit, pipx

#### C++ Development Tools

```bash
sudo ./install-runner-linux.sh --setup-cpp
# or
sudo ./setup-cpp-tools.sh
```

Installs:
- GCC/G++ and Clang compilers
- CMake and Ninja build tools
- sccache (compilation cache)
- Google Test and Catch2 frameworks
- clang-format and clang-tidy

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