# GitHub Actions Self-Hosted Runner Setup

Part of the CICD Template System - Phase 6.2

This directory contains everything needed to set up GitHub Actions self-hosted runners for both **Windows** and **Linux** platforms with comprehensive development tools for Python and C++ projects.

## 🏗️ Platform-Specific Setup

Choose your platform below:

### 🪟 Windows Setup
**Directory**: `./windows/`

**Features**:
- GitHub Actions runner as Windows service
- Python development tools (Ruff, pytest, mypy, pre-commit)
- C++ development tools (Visual Studio Build Tools, CMake, Ninja, sccache)
- Comprehensive PowerShell management utilities
- Windows-specific security and performance optimizations

**Quick Start**:
```powershell
# Navigate to Windows directory
cd windows

# Run installation (PowerShell as Administrator)
.\install-runner-windows.ps1
```

**Documentation**: See `./windows/README.md` for complete Windows setup guide.

---

### 🐧 Linux Setup
**Directory**: `./linux/`

**Features**:
- GitHub Actions runner as systemd service
- Python development tools (Ruff, pytest, mypy, pre-commit)
- C++ development tools (GCC/Clang, CMake, Ninja, sccache)
- Bash shell management utilities
- Linux-specific security and performance optimizations

**Quick Start**:
```bash
# Navigate to Linux directory
cd linux

# Run installation (as root)
sudo ./install-runner-linux.sh
```

**Documentation**: See `./linux/README.md` for complete Linux setup guide.

---

## 📊 Performance Comparison

| Feature | GitHub-Hosted | Self-Hosted | Improvement |
|---------|---------------|-------------|-------------|
| Python lint (Ruff) | 30-60s | 5-10s | **5-6x faster** |
| C++ build (clean) | 5-10min | 2-4min | **2-3x faster** |
| C++ build (cached) | 5-10min | 30-60s | **10-15x faster** |
| Test execution | 2-5min | 1-2min | **2-3x faster** |

## 🛠️ Common Tools Across Platforms

### Python Development Tools
- **Ruff**: Ultra-fast Python linter and formatter (10-100x faster than traditional tools)
- **pytest**: Testing framework with coverage support
- **mypy**: Static type checking
- **pre-commit**: Git hooks management

### C++ Development Tools
- **CMake**: Build system generator
- **Ninja**: Fast build tool
- **sccache**: Compilation cache for dramatically faster builds
- **clang-format**: Code formatting (Linux) / Visual Studio formatting (Windows)

## 🎯 When to Use Self-Hosted Runners

### Ideal For:
- **Large projects** with long build times
- **Frequent builds** that can benefit from caching
- **Custom toolchains** or specific dependencies
- **Performance-critical** CI/CD pipelines
- **Cost optimization** for high-volume builds

### Not Ideal For:
- Small projects with infrequent builds
- Projects requiring completely isolated environments
- Teams without infrastructure management resources

## 🔧 System Requirements

### Windows Requirements
- Windows 10/11 or Windows Server 2019+
- PowerShell 5.1 or PowerShell Core 6+
- Administrator privileges
- Minimum 4GB RAM, 20GB disk space

### Linux Requirements
- Ubuntu 18.04+, Debian 10+, or RHEL 8+
- Bash shell
- sudo/root privileges
- Minimum 4GB RAM, 20GB disk space

## 📁 Directory Structure

```
runner-setup/
├── README.md                    # This file - overview and quick start
├── windows/                     # Windows-specific setup
│   ├── install-runner-windows.ps1
│   ├── manage-runner-service.ps1
│   ├── runner-config-windows.yaml
│   └── README.md                 # Windows detailed guide
└── linux/                       # Linux-specific setup
    ├── install-runner-linux.sh
    ├── setup-python-tools.sh
    ├── setup-cpp-tools.sh
    ├── runner-config.yaml
    └── README.md                 # Linux detailed guide
```

## 🚀 Getting Started

### 1. Choose Your Platform
```bash
# For Windows
cd runner-setup/windows

# For Linux
cd runner-setup/linux
```

### 2. Follow Platform-Specific Instructions
- **Windows**: See `./windows/README.md`
- **Linux**: See `./linux/README.md`

### 3. Install Development Tools (Optional)
Both platforms support optional installation of:
- Python development environment
- C++ development environment
- Additional performance optimizations

### 4. Configure Your Workflows
Update your GitHub Actions workflows to use `self-hosted` runners:

```yaml
# Example workflow
name: CI

on: [push, pull_request]

jobs:
  build:
    runs-on: self-hosted  # Uses your new runner
    steps:
      - uses: actions/checkout@v4
      - run: Your build commands here
```

## 🔒 Security Considerations

### Isolation
- **Dedicated user accounts** with minimal privileges
- **Service isolation** using systemd (Linux) or Windows Service
- **Network restrictions** - only outbound HTTPS to GitHub

### Access Control
- **Registration tokens** required for runner registration
- **Configurable labels** for job assignment control
- **Audit logging** for all runner activities

### File Permissions
- **Proper file permissions** set automatically
- **Configuration files** protected
- **Log access** controlled appropriately

## 📈 Monitoring and Maintenance

### Health Monitoring
Both platforms include:
- **Service status monitoring**
- **Log viewing and management**
- **Connectivity testing**
- **Performance metrics**

### Maintenance Tasks
- **Daily**: Monitor service status and logs
- **Weekly**: Check cache statistics and clear if needed
- **Monthly**: Review and update development tools
- **Quarterly**: Security updates and patch management

## 🆘 Support and Troubleshooting

### Platform-Specific Support
- **Windows**: See `./windows/README.md#troubleshooting`
- **Linux**: See `./linux/README.md#troubleshooting`

### Common Issues
1. **Permission problems** - Run with appropriate privileges
2. **Network connectivity** - Check firewall and proxy settings
3. **Token expiration** - Generate new registration tokens
4. **Disk space** - Monitor available disk space

### Getting Help
```bash
# Windows (PowerShell)
.\install-runner-windows.ps1 -Help
.\manage-runner-service.ps1 -Help

# Linux (Bash)
./install-runner-linux.sh --help
```

## 🔄 Integration with CICD Templates

These runners are designed to work seamlessly with the CICD Template System:

### Reusable Workflows
```yaml
# Python CI
jobs:
  python-ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/python-ci-reusable.yaml@v1
    with:
      runner-type: 'self-hosted'

# C++ CI
jobs:
  cpp-ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-ci-reusable.yaml@v1
    with:
      runner-type: 'self-hosted'
```

### Cookiecutter Templates
The runners automatically configure themselves for projects created with the CICD template cookiecutters.

## 📝 License

This setup is part of the CICD Template System. See the main project LICENSE file for details.

---

**Version**: 2.319.1 (Runner)
**Last Updated**: 2025-10-14
**Status**: Production Ready
**Supported Platforms**: Windows, Linux (Ubuntu/Debian/RHEL)