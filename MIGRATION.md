# Migration Guide: setup-scripts → scripts

This document describes the restructuring of the development environment setup system.

## What Changed?

### Old Structure (Deprecated)
```
setup-scripts/
├── total_run.sh          # Installation + Validation
├── linux/
│   ├── tools/
│   ├── config/
│   └── validation/
└── README.md
```

**Old Workflow:**
1. Manually create project
2. Run `sudo bash setup-scripts/total_run.sh`
3. Manually validate

**Problems:**
- Mixed responsibilities (installation + validation)
- Validation didn't test actual project files
- Confusing naming (`total_run.sh` doesn't describe its purpose)
- Ruff errors on cookiecutter templates

### New Structure
```
scripts/
├── create-project.sh     # Create project + Auto-install tools
├── total_validation.sh   # Validation only (tests actual project)
├── linux/
│   ├── core/             # System dependencies
│   ├── tools/            # Development tools
│   ├── config/           # Configurations
│   └── validation/       # Validation scripts
└── README.md
```

**New Workflow:**
1. Run `bash scripts/create-project.sh python my-project`
   - Creates project from template
   - **Auto-installs required tools**
   - Sets up configurations
2. Run `bash scripts/total_validation.sh` (from project directory)
   - Tests **actual project files**
   - Validates installation
   - Checks code quality

**Improvements:**
- Clear separation of concerns
- Automatic tool installation
- Validation tests real project code
- Better naming conventions
- No more Ruff errors on templates

## Migration Steps

### For Users

#### Before (Old Way)
```bash
# Create project manually or with cookiecutter
cookiecutter cookiecutters/python-project

# Install tools
cd my-project
sudo bash ../setup-scripts/total_run.sh

# Manually validate
pytest
ruff check src/
```

#### After (New Way)
```bash
# Create project (tools auto-installed)
bash scripts/create-project.sh python my-project

# Validate (tests actual project)
cd my-project
bash ../scripts/total_validation.sh
```

### For Script Developers

#### Updating References

**Before:**
```bash
SETUP_DIR="setup-scripts"
bash setup-scripts/total_run.sh
```

**After:**
```bash
SCRIPTS_DIR="scripts"
bash scripts/create-project.sh python my-project
cd my-project
bash ../scripts/total_validation.sh
```

#### Key Changes

1. **Installation moved to `create-project.sh`**
   - Automatic tool installation based on project type
   - No need for separate installation step

2. **`total_run.sh` → `total_validation.sh`**
   - Renamed to reflect actual purpose (validation only)
   - No longer performs installation
   - Tests actual project files, not dummy files

3. **Validation improvements**
   - Auto-detects project type from current directory
   - Tests `src/` directory of actual project
   - Provides meaningful feedback on project quality

## Technical Details

### Ruff Configuration

Added cookiecutter template exclusion to `configs/python/ruff.toml`:

```toml
exclude = [
    "cookiecutters/",
    "__pycache__",
    ".venv",
    "venv",
    "build",
    "dist",
    "*.egg-info",
]
```

This prevents Ruff from trying to lint Jinja2 template files like `{{cookiecutter.package_name}}`.

### Validation Logic Change

**Before (`total_run.sh`):**
```bash
# Created temporary test files in /tmp
mkdir -p /tmp/python_test/src
cp /tmp/test_python.py /tmp/python_test/src/
ruff check /tmp/python_test/src/  # Tests dummy file
```

**After (`total_validation.sh`):**
```bash
# Tests actual project files
if [ -d "src" ]; then
    ruff check src/  # Tests real project code
fi
```

### Auto-Detection

Both scripts now auto-detect project type:

**`create-project.sh`:**
```bash
# Detects from created files
if [ -f "pyproject.toml" ]; then
    install_python_tools
elif [ -f "CMakeLists.txt" ]; then
    install_cpp_tools
fi
```

**`total_validation.sh`:**
```bash
# Detects from current directory
if [ -f "pyproject.toml" ]; then
    PYTHON_ONLY="true"
elif [ -f "CMakeLists.txt" ]; then
    CPP_ONLY="true"
fi
```

## Backwards Compatibility

### Legacy Support

The old `setup-scripts/` directory is **kept for now** to avoid breaking existing workflows, but it is **deprecated**.

**Deprecation Timeline:**
- **Phase 1 (Current)**: Both structures exist, new structure recommended
- **Phase 2 (1 month)**: Add deprecation warnings to old scripts
- **Phase 3 (3 months)**: Remove `setup-scripts/` entirely

### Transition Period

During the transition:
- Old scripts still work but show deprecation warning
- New scripts are the recommended approach
- Documentation updated to show new workflow

## Benefits Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Project Creation** | Manual | Automated |
| **Tool Installation** | Manual, separate step | Automatic during creation |
| **Validation** | Tests dummy files | Tests actual project files |
| **Naming** | Confusing (`total_run`) | Clear (`create-project`, `total_validation`) |
| **Ruff Errors** | Template files cause errors | Templates excluded |
| **User Experience** | Multiple manual steps | Single command |
| **Clarity** | Mixed responsibilities | Clear separation |

## FAQ

### Q: Do I need to migrate existing projects?

**A:** No. Existing projects continue to work. The changes affect new project creation and validation workflows.

### Q: Will the old scripts stop working?

**A:** Not immediately. They'll show deprecation warnings first, then be removed after a transition period.

### Q: Can I still use `setup-scripts/total_run.sh`?

**A:** Yes, but it's deprecated. Use `scripts/create-project.sh` for new projects.

### Q: Why does validation need to run from the project directory?

**A:** To test your **actual project files** instead of dummy test files. This gives real feedback on your code quality.

### Q: How do I fix Ruff errors on cookiecutter templates?

**A:** The templates are now excluded via `exclude` in `configs/python/ruff.toml`. You shouldn't see these errors anymore.

## See Also

- [Scripts README](scripts/README.md) - Detailed documentation of new structure
- [Setup Scripts README](setup-scripts/README.md) - Legacy documentation (deprecated)
- [Cookiecutter Templates](cookiecutters/README.md) - Project templates
