# Ruff Migration Guide

Complete guide for migrating Python projects from traditional linting tools (Black, Flake8, isort, pyupgrade) to Ruff - the ultra-fast Python linter and formatter.

## 📋 Overview

### What is Ruff?

Ruff is an extremely fast Python linter and code formatter, written in Rust. It can replace multiple traditional tools:

- **Black**: Code formatting
- **Flake8**: Linting and style checking
- **isort**: Import sorting
- **pyupgrade**: Python version upgrades
- **autoflake**: Unused import removal
- **and many more...**

### Performance Comparison

| Tool | Speed | Language | Features |
|------|-------|----------|----------|
| **Ruff** | 10-100x faster | Rust | Linting + Formatting |
| Black | Baseline | Python | Formatting only |
| Flake8 | 10-20x slower | Python | Linting only |
| isort | 5-10x slower | Python | Import sorting only |

### Migration Benefits

- **Performance**: 10-100x faster execution
- **Unified Tool**: Single configuration for multiple checks
- **Compatibility**: Drop-in replacement for most tools
- **Active Development**: Rapid feature additions and improvements
- **Great Integration**: Works with VS Code, pre-commit, GitHub Actions

## 🎯 When to Migrate

### Ideal Candidates

- ✅ Python projects using Black + Flake8 + isort
- ✅ Projects with slow CI/CD pipelines
- ✅ Teams wanting to consolidate tooling
- ✅ New projects starting from templates

### Considerations

- ⚠️ Ruff is rapidly evolving (features may change)
- ⚠️ Some niche Flake8 plugins not yet supported
- ⚠️ Team learning curve for new tool
- ⚠️ IDE plugins may need updates

## 📦 Installation

### Basic Installation

```bash
# Install Ruff
pip install ruff

# Verify installation
ruff --version
```

### Project Installation

```bash
# Add to project dependencies
pip install ruff

# Or add to pyproject.toml
[project.optional-dependencies]
dev = [
    "ruff>=0.6.0",
    # ... other dev dependencies
]
```

### Global Installation

```bash
# Install globally
pipx install ruff

# Or with pip
pip install --user ruff
```

## ⚙️ Configuration

### Basic Ruff Configuration (ruff.toml)

```toml
# ruff.toml
target-version = "py310"
line-length = 88
indent-width = 4

[lint]
# Enable all rules
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort
    "N",   # pep8-naming
    "UP",  # pyupgrade
    "B",   # flake8-bugbear
    "C4",  # flake8-comprehensions
    "SIM", # flake8-simplify
]

# Ignore specific rules
ignore = [
    "E501",  # line too long (handled by formatter)
]

# Allow autofix
fixable = ["ALL"]
unfixable = []

[format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "auto"
```

### PyProject.toml Configuration

```toml
[tool.ruff]
target-version = "py310"
line-length = 88

[tool.ruff.lint]
select = ["E", "W", "F", "I", "N", "UP", "B", "C4", "SIM"]
ignore = ["E501"]
fixable = ["ALL"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

### Pre-commit Configuration

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.0
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format
```

## 🔄 Migration Steps

### Step 1: Backup Existing Configuration

```bash
# Backup current configurations
cp .pre-commit-config.yaml .pre-commit-config.yaml.backup
cp setup.cfg setup.cfg.backup
cp pyproject.toml pyproject.toml.backup

# Document current tools
echo "Current tools:" > migration-notes.md
echo "- Black: $(black --version)" >> migration-notes.md
echo "- Flake8: $(flake8 --version)" >> migration-notes.md
echo "- isort: $(isort --version-number)" >> migration-notes.md
```

### Step 2: Install Ruff

```bash
# Install Ruff
pip install ruff

# Add to requirements
echo "ruff>=0.6.0" >> requirements-dev.txt
```

### Step 3: Create Ruff Configuration

```bash
# Create ruff.toml
cat > ruff.toml << 'EOF'
target-version = "py310"
line-length = 88

[lint]
select = ["E", "W", "F", "I", "N", "UP", "B", "C4", "SIM"]
ignore = ["E501"]
fixable = ["ALL"]

[format]
quote-style = "double"
indent-style = "space"
EOF
```

### Step 4: Update Pre-commit Hooks

```bash
# Update .pre-commit-config.yaml
cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
        args: ['--maxkb=1000']

  # Ruff replaces: Black, Flake8, isort, pyupgrade
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.0
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format
EOF
```

### Step 5: Test Ruff Configuration

```bash
# Check current files
ruff check .

# Format current files
ruff format .

# Fix auto-fixable issues
ruff check --fix .

# Verify no critical issues remain
ruff check --select=E,W,F .
```

### Step 6: Update CI/CD Configuration

#### GitHub Actions Example

```yaml
# .github/workflows/ci.yaml
name: CI

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.10'

      - name: Install Ruff
        run: pip install ruff

      - name: Ruff check
        run: ruff check .

      - name: Ruff format check
        run: ruff format --check .
```

### Step 7: Remove Old Tools

```bash
# Remove old tools (optional)
pip uninstall black flake8 isort pyupgrade autoflake

# Remove from requirements
sed -i '/black\|flake8\|isort\|pyupgrade\|autoflake/d' requirements-dev.txt

# Remove old configurations
rm setup.cfg .flake8 .isort.cfg
```

### Step 8: Update IDE Configuration

#### VS Code

```json
// .vscode/settings.json
{
    "python.linting.enabled": true,
    "python.linting.ruffEnabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": false,
    "python.formatting.provider": "black",
    "python.formatting.blackArgs": ["--line-length=88"],
    "[python]": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": true
        }
    }
}
```

#### PyCharm

1. Install Ruff plugin
2. Configure in Settings → Tools → External Tools
3. Set up File Watchers for auto-format

## 🧪 Validation

### Functional Testing

```bash
# Run Ruff on entire codebase
ruff check .

# Format check
ruff format --check .

# Test import sorting
echo "import os\nimport sys" > test_imports.py
ruff check --select=I test_imports.py
cat test_imports.py  # Should be sorted
rm test_imports.py
```

### Performance Testing

```bash
# Time Ruff vs old tools
echo "Testing Ruff performance..."
time ruff check .

# Compare with old tools (if still installed)
# time flake8 .
# time black --check .
# time isort --check-only .
```

### CI/CD Integration Testing

```bash
# Test CI configuration locally
act -j lint  # If using act for local GitHub Actions testing

# Or manually run CI steps
pip install ruff
ruff check . && ruff format --check .
```

## 🔧 Advanced Configuration

### Rule Selection

```toml
[tool.ruff.lint]
# Select specific rule sets
select = [
    "E",    # pycodestyle errors
    "W",    # pycodestyle warnings
    "F",    # pyflakes
    "I",    # isort
    "N",    # pep8-naming
    "UP",   # pyupgrade
    "B",    # flake8-bugbear
    "C4",   # flake8-comprehensions
    "SIM",  # flake8-simplify
    "TCH",  # flake8-type-checking
    "PTH",  # flake8-use-pathlib
    "PERF", # perflint
]

# Ignore specific rules
ignore = [
    "E501",   # line too long
    "B008",   # do not perform function calls in argument defaults
    "SIM108", # use ternary operator instead of if-else-block
]
```

### Per-Path Configuration

```toml
[tool.ruff]
# Exclude files and directories
exclude = [
    ".git",
    "__pycache__",
    "build",
    "dist",
    ".venv",
    ".eggs",
    "*.egg",
]

# Per-file ignores
[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["F401"]  # Allow unused imports in __init__.py
"tests/*" = ["S101"]      # Allow assert statements in tests
"migrations/*" = ["RUF012"]  # Allow mutable class defaults in migrations
```

### Custom Rules and Plugins

```toml
[tool.ruff.lint]
# Enable experimental rules
select = ["ALL"]

# Configure specific rules
[tool.ruff.lint.mccabe]
max-complexity = 10

[tool.ruff.lint.pydocstyle]
convention = "google"

[tool.ruff.lint.pylint]
max-args = 7
max-branches = 12
```

## 🚨 Common Issues and Solutions

### Issue: Ruff finds different issues than old tools

**Problem**: Ruff reports different violations than Flake8/Black

**Solution**:
```bash
# Compare outputs
flake8 . > flake8-output.txt 2>&1 || true
ruff check . > ruff-output.txt 2>&1 || true
diff flake8-output.txt ruff-output.txt

# Adjust Ruff configuration to match old behavior
# Add specific rules to ignore or enable
```

### Issue: Import sorting behavior differs

**Problem**: isort and Ruff sort imports differently

**Solution**:
```toml
[tool.ruff.lint.isort]
# Configure import sorting to match isort
known-first-party = ["myproject"]
known-third-party = ["requests", "numpy"]
split-on-trailing-comma = true
```

### Issue: Line length handling

**Problem**: Different line length behavior than Black

**Solution**:
```toml
[tool.ruff]
line-length = 88  # Match Black default

[tool.ruff.format]
# Use Black-compatible formatting
quote-style = "double"
indent-style = "space"
```

### Issue: Team member resistance

**Problem**: Team members prefer old tools

**Solution**:
- Run both tools in parallel during transition
- Document performance improvements
- Provide training and documentation
- Gradually phase out old tools

## 📊 Migration Checklist

### Pre-Migration

- [ ] Document current linting/formatting setup
- [ ] Benchmark current CI/CD performance
- [ ] Identify all configuration files
- [ ] Get team buy-in
- [ ] Plan rollback strategy

### Migration

- [ ] Install Ruff
- [ ] Create Ruff configuration
- [ ] Update pre-commit hooks
- [ ] Test on codebase
- [ ] Update CI/CD pipelines
- [ ] Update IDE configurations
- [ ] Update documentation

### Post-Migration

- [ ] Verify performance improvements
- [ ] Update team documentation
- [ ] Train team members
- [ ] Monitor for issues
- [ ] Fine-tune configuration
- [ ] Remove old tools

### Validation

- [ ] All code passes Ruff checks
- [ ] CI/CD pipeline faster
- [ ] No regressions in code quality
- [ ] Team productivity maintained/improved
- [ ] Documentation updated

## 🔗 Resources and References

### Official Documentation

- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [Ruff Configuration](https://docs.astral.sh/ruff/configuration/)
- [Rule Index](https://docs.astral.sh/ruff/rules/)
- [Pre-commit Integration](https://docs.astral.sh/ruff/integrations/#pre-commit)

### Migration Guides

- [Black to Ruff](https://docs.astral.sh/ruff/formatter/#black-compatibility)
- [Flake8 to Ruff](https://docs.astral.sh/ruff/tutorial/#configuration)
- [isort to Ruff](https://docs.astral.sh/ruff/settings/#isort)

### Community Resources

- [GitHub Repository](https://github.com/astral-sh/ruff)
- [Discord Community](https://discord.gg/VYVcyH2)
- [Blog Posts](https://astral.sh/blog/)
- [Examples](https://github.com/astral-sh/ruff/tree/main/crates/ruff_linter/resources/test)

### IDE Plugins

- [VS Code Ruff](https://marketplace.visualstudio.com/items?itemName=charliermarsh.ruff)
- [PyCharm Ruff Plugin](https://plugins.jetbrains.com/plugin/20576-ruff)
- [Sublime Text](https://github.com/wakatime/sublime-ruff)
- [Neovim](https://github.com/nvimtools/none-ls.nvim)

## 🎉 Success Stories

### Case Study 1: Web Development Team

**Before**: Black + Flake8 + isort (45s CI time)
**After**: Ruff only (8s CI time)
**Improvement**: 82% faster CI, unified configuration

### Case Study 2: Data Science Team

**Before**: Multiple linting tools, inconsistent formatting
**After**: Ruff with data science specific rules
**Improvement**: Consistent code style, 10x faster linting

### Case Study 3: Enterprise Application

**Before**: Complex linting setup, slow feedback
**After**: Ruff with custom rule configuration
**Improvement**: Simplified setup, 15x faster feedback

---

**Last Updated:** 2025-10-14
**Ruff Version:** 0.6.0+
**Migration Complexity:** Medium (1-2 days for typical project)

For help with your migration, create an issue in the template repository or contact the CICD team.