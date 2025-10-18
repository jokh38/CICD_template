# Migration Guide: setup-scripts → scripts

This document describes the restructuring of the development environment setup system.

## What Changed?

### Old Structure (Removed)
```
setup-scripts/          ❌ REMOVED
├── total_run.sh
├── total_run.ps1
├── linux/
└── windows/
```

### New Structure
```
scripts/                ✅ CURRENT
├── create-project.sh
├── total_validation.sh
├── total_validation.ps1
├── linux/
└── windows/
```

## Key Changes

### 1. Directory Renamed
- **Old:** `setup-scripts/`
- **New:** `scripts/`
- **Reason:** Clearer, more concise naming

### 2. Separation of Concerns
- **Old:** `total_run.*` (did both installation + validation)
- **New:**
  - `create-project.sh` - Creates project and auto-installs tools
  - `total_validation.*` - Validates project setup only

### 3. Improved Validation
- **Old:** Validated dummy files in `/tmp` or `$env:TEMP`
- **New:** Validates actual project files in `src/` directory

### 4. Auto-Detection
- Automatically detects project type (Python vs C++)
- Installs appropriate tools automatically

### 5. Windows Feature Parity
- Added `install-cpp-pkg-managers.ps1` for Windows
- Now 100% feature parity between Linux and Windows

## Migration Steps

### Old Way (Deprecated - No Longer Available)
```bash
# ❌ This no longer works
cookiecutter cookiecutters/python-project
cd my-project
sudo bash ../setup-scripts/total_run.sh
```

### New Way (Current)

**Linux/macOS:**
```bash
# Create project with auto-installation
bash scripts/create-project.sh python my-project

# Validate
cd my-project
bash ../scripts/total_validation.sh
```

**Windows:**
```powershell
# Create project (use WSL/Git Bash or cookiecutter directly)
cookiecutter cookiecutters/python-project

# Validate
cd my-project
pwsh ..\scripts\total_validation.ps1
```

## Benefits

| Feature | Old | New |
|---------|-----|-----|
| Installation | Manual | Automatic |
| Validation | Dummy files | Real project files |
| Project detection | Manual flags | Automatic |
| Naming clarity | `total_run` | `create-project` / `total_validation` |
| Ruff errors | Template errors | Templates excluded |
| Feature parity | Linux only had cpp-pkg-managers | Both platforms have all tools |

## Documentation

- [scripts/README.md](scripts/README.md) - Complete usage guide
- [scripts/windows/tools/README.md](scripts/windows/tools/README.md) - Windows tools documentation

## Breaking Changes

⚠️ **The `setup-scripts/` directory has been removed.**

If you have any references to `setup-scripts/` in your scripts or documentation, update them to `scripts/`.

## Need Help?

If you encounter issues with the migration, refer to:
1. [scripts/README.md](scripts/README.md) for detailed usage
2. Check that you're using the new `scripts/` directory
3. Use `create-project.sh` instead of manual project creation + `total_run.*`
