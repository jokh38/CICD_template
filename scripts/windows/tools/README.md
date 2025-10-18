# Windows Development Tools Installation Scripts

This directory contains PowerShell scripts for installing development tools on Windows.

## Scripts Overview

### Core System Tools

#### `install-system-deps.ps1`
Installs essential system dependencies required for development.

**Installs:**
- Git
- Visual Studio Build Tools
- Windows SDK
- Essential utilities

**Usage:**
```powershell
.\install-system-deps.ps1
```

**Requirements:** Administrator privileges

---

### Compilers and Build Tools

#### `install-compilers.ps1`
Installs C++ compilers for Windows.

**Installs:**
- MSVC (Microsoft Visual C++ Compiler)
- Clang/LLVM
- Compiler toolchains

**Usage:**
```powershell
.\install-compilers.ps1
```

**Requirements:** Administrator privileges

#### `install-build-tools.ps1`
Installs build system tools.

**Installs:**
- CMake
- Ninja build system
- Make utilities

**Usage:**
```powershell
.\install-build-tools.ps1
```

**Requirements:** Administrator privileges

---

### C++ Development Tools

#### `install-sccache.ps1`
Installs sccache - a compiler cache to speed up C++ builds.

**Features:**
- Caches compilation results
- Significantly reduces rebuild times
- Works with MSVC and Clang

**Usage:**
```powershell
.\install-sccache.ps1
```

**Post-installation:**
Set environment variable: `RUSTC_WRAPPER=sccache`

#### `install-cpp-frameworks.ps1`
Installs C++ testing frameworks.

**Installs:**
- Google Test (GTest)
- Catch2
- Testing utilities

**Usage:**
```powershell
.\install-cpp-frameworks.ps1
```

#### `install-cpp-pkg-managers.ps1` ✨ **NEW**
Installs C++ package managers for dependency management.

**Installs:**
- **vcpkg** - Microsoft's C++ package manager
  - Installed to: `C:\Program Files\vcpkg`
  - Environment variable: `VCPKG_ROOT`
  - Added to PATH

- **Conan** - Cross-platform C++ package manager
  - Installed via pip
  - Default profile auto-configured

**Usage:**
```powershell
.\install-cpp-pkg-managers.ps1
```

**Requirements:**
- Administrator privileges
- Git installed
- Python 3.x with pip

**Post-installation:**
```powershell
# Verify installation
vcpkg version
conan --version

# Use vcpkg
vcpkg install boost

# Use Conan
conan install .
```

**Environment Variables Set:**
- `VCPKG_ROOT` = `C:\Program Files\vcpkg`
- `PATH` updated to include vcpkg

---

### Python Development Tools

#### `install-python-tools.ps1`
Installs Python development and testing tools.

**Installs:**
- **ruff** - Fast Python linter
- **black** - Code formatter
- **pytest** - Testing framework
- **mypy** - Static type checker
- **bandit** - Security linter
- **pre-commit** - Git hook framework

**Usage:**
```powershell
.\install-python-tools.ps1
```

**Requirements:** Python 3.x installed

---

## Installation Order

For a complete C++ development environment:

```powershell
# 1. System dependencies (requires admin)
.\install-system-deps.ps1

# 2. Compilers (requires admin)
.\install-compilers.ps1

# 3. Build tools (requires admin)
.\install-build-tools.ps1

# 4. sccache (optional but recommended)
.\install-sccache.ps1

# 5. C++ frameworks
.\install-cpp-frameworks.ps1

# 6. C++ package managers (NEW!)
.\install-cpp-pkg-managers.ps1
```

For a complete Python development environment:

```powershell
# 1. System dependencies (requires admin)
.\install-system-deps.ps1

# 2. Python tools
.\install-python-tools.ps1
```

---

## Common Issues

### Administrator Privileges
Most scripts require Administrator privileges. Run PowerShell as Administrator:
```powershell
Start-Process powershell -Verb RunAs
```

### Execution Policy
If scripts don't run, you may need to change the execution policy:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### PATH Not Updated
After installation, restart your terminal or IDE to load new PATH variables.

### vcpkg Bootstrap Fails
Ensure Git is installed and accessible in PATH:
```powershell
git --version
```

### Conan Installation Fails
Ensure Python and pip are installed:
```powershell
python --version
pip --version
```

---

## Platform-Specific Notes

### vcpkg on Windows
- Installed to: `C:\Program Files\vcpkg` (configurable)
- Uses `bootstrap-vcpkg.bat` (Windows batch file)
- Integrates with Visual Studio via `vcpkg integrate install`

### Conan on Windows
- Uses Python pip for installation
- Auto-detects MSVC compiler
- Creates profile in `%USERPROFILE%\.conan2\profiles\default`

---

## See Also

- [Linux Tools](../../linux/tools/README.md) - Linux equivalents
- [Configuration Scripts](../config/) - Setup git, formatting, etc.
- [Validation Scripts](../validation/) - Test installation
- [Main Scripts README](../../README.md) - Overall documentation
