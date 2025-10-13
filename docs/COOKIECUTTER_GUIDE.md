# Cookiecutter Guide

A comprehensive guide to using Cookiecutter with the CI/CD template system.

---

## Table of Contents

- [What is Cookiecutter?](#what-is-cookiecutter)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Template Variables](#template-variables)
- [Advanced Usage](#advanced-usage)
- [Customizing Templates](#customizing-templates)
- [Creating Your Own Templates](#creating-your-own-templates)
- [Tips & Tricks](#tips--tricks)

---

## What is Cookiecutter?

Cookiecutter is a command-line utility that creates projects from project templates. It:

- Asks you questions about your project
- Generates a complete project structure
- Replaces template variables with your answers
- Runs post-generation hooks (optional)

**Why use Cookiecutter?**
- **Consistency:** All projects follow the same structure
- **Speed:** Create new projects in seconds, not hours
- **Best practices:** Templates encode organizational standards
- **Automation:** Post-generation hooks set up git, venv, etc.

---

## Installation

### Using pip

```bash
pip install cookiecutter
# Verify
cookiecutter --version
```

### Using pipx (Recommended)

```bash
# Install pipx if not already installed
python3 -m pip install --user pipx
python3 -m pipx ensurepath

# Install cookiecutter
pipx install cookiecutter

# Verify
cookiecutter --version
```

### Using System Package Manager

**Ubuntu/Debian:**
```bash
sudo apt-get install cookiecutter
```

**macOS:**
```bash
brew install cookiecutter
```

---

## Basic Usage

### Using Our Project Templates

**Python Project:**
```bash
# Navigate to template directory
cd /path/to/CICD_template

# Run cookiecutter
cookiecutter cookiecutters/python-project
```

**C++ Project:**
```bash
cookiecutter cookiecutters/cpp-project
```

### Using the Helper Script

The easier way:
```bash
bash scripts/create-project.sh python my-project
bash scripts/create-project.sh cpp my-library
```

### From GitHub (If Template is Published)

```bash
cookiecutter gh:YOUR-ORG/github-cicd-templates \
  --directory="cookiecutters/python-project"
```

---

## Template Variables

### Python Template Variables

When you run Cookiecutter for a Python project, you'll be prompted for:

| Variable | Description | Example | Default |
|----------|-------------|---------|---------|
| `project_name` | Display name | `My Awesome API` | - |
| `project_slug` | Package name | `my-awesome-api` | Auto-generated |
| `project_description` | Short description | `A fast API server` | `A Python project` |
| `author_name` | Your name | `John Doe` | - |
| `author_email` | Your email | `john@example.com` | - |
| `python_version` | Python version | `3.11` | `3.10` |
| `use_ai_workflow` | Include AI prompts | `yes` / `no` | `no` |
| `runner_type` | CI runner type | `github-hosted` / `self-hosted` | `github-hosted` |
| `include_docker` | Add Dockerfile | `yes` / `no` | `no` |
| `license` | License type | `MIT`, `Apache-2.0`, etc. | `MIT` |

**Variable relationships:**
- `project_slug` is auto-generated from `project_name`
- Converts to lowercase
- Replaces spaces and underscores with hyphens

---

### C++ Template Variables

For C++ projects:

| Variable | Description | Example | Default |
|----------|-------------|---------|---------|
| `project_name` | Display name | `My Fast Library` | - |
| `project_slug` | Library name | `my-fast-library` | Auto-generated |
| `project_description` | Short description | `High performance library` | `A C++ project` |
| `author_name` | Your name | `Jane Smith` | - |
| `author_email` | Your email | `jane@example.com` | - |
| `cpp_standard` | C++ standard | `17`, `20`, `23` | `17` |
| `build_system` | Build system | `cmake` / `meson` | `cmake` |
| `use_ai_workflow` | Include AI prompts | `yes` / `no` | `no` |
| `runner_type` | CI runner type | `github-hosted` / `self-hosted` | `github-hosted` |
| `enable_cache` | Enable sccache | `yes` / `no` | `yes` |
| `use_ninja` | Use Ninja | `yes` / `no` | `yes` |
| `testing_framework` | Test framework | `gtest`, `catch2`, `doctest` | `gtest` |
| `license` | License type | `MIT`, `Apache-2.0`, etc. | `MIT` |

---

## Advanced Usage

### Non-Interactive Mode

Provide all variables via command line or config file.

**Using command-line arguments:**
```bash
cookiecutter cookiecutters/python-project \
  --no-input \
  project_name="My API" \
  author_name="John Doe" \
  python_version="3.11" \
  use_ai_workflow="yes"
```

**Using a configuration file:**

Create `my-project-config.yaml`:
```yaml
default_context:
  project_name: "My Awesome Project"
  author_name: "John Doe"
  author_email: "john@example.com"
  python_version: "3.11"
  license: "MIT"
```

Run with config:
```bash
cookiecutter cookiecutters/python-project \
  --no-input \
  --config-file my-project-config.yaml
```

---

### Overwriting Existing Directory

By default, Cookiecutter errors if directory exists:

```bash
# Force overwrite (CAUTION: deletes existing directory)
cookiecutter cookiecutters/python-project --overwrite-if-exists

# Or delete first
rm -rf my-project
cookiecutter cookiecutters/python-project
```

---

### Replay Mode

Cookiecutter saves your previous answers. Replay to use same values:

```bash
# Use previous answers
cookiecutter cookiecutters/python-project --replay

# Check replay file
cat ~/.cookiecutter_replay/cookiecutters-python-project.json
```

---

### Checkout Specific Version

For templates in git repos:

```bash
cookiecutter gh:YOUR-ORG/templates \
  --checkout v1.2.0 \
  --directory="python-project"
```

---

### Output Directory

Generate in specific location:

```bash
cookiecutter cookiecutters/python-project \
  --output-dir /path/to/projects
```

---

## Template Variables in Files

### Variable Syntax

In template files, use Jinja2 syntax:

```python
# In templates: {{cookiecutter.project_slug}}/__init__.py
"""{{cookiecutter.project_description}}"""

__version__ = "0.1.0"
__author__ = "{{cookiecutter.author_name}}"
```

### Conditional Content

```yaml
# In workflow templates
name: CI for {{cookiecutter.project_name}}

jobs:
  test:
    runs-on: {{cookiecutter.runner_type}}
    
    {% if cookiecutter.use_ai_workflow == 'yes' %}
    # AI workflow steps
    - name: Run AI checks
      run: ...
    {% endif %}
```

### Filters

```jinja2
# Convert to different case
project_slug: "{{ cookiecutter.project_name.lower().replace(' ', '-') }}"

# Conditional replacement
{% if cookiecutter.license != 'None' %}
license: {{ cookiecutter.license }}
{% endif %}
```

---

## Customizing Templates

### Modifying Existing Templates

1. **Clone or copy the template repository**
   ```bash
   cp -r cookiecutters/python-project my-custom-python-template
   ```

2. **Edit `cookiecutter.json`**
   Add, remove, or modify variables:
   ```json
   {
     "project_name": "My Project",
     "my_custom_var": "default value",
     "database": ["postgresql", "mysql", "sqlite"]
   }
   ```

3. **Update template files**
   Use your new variables:
   ```python
   # {{cookiecutter.project_slug}}/config.py
   DATABASE = "{{cookiecutter.database}}"
   ```

4. **Test your template**
   ```bash
   cookiecutter my-custom-python-template
   ```

---

### Adding New Files

Add any file to the template directory:

```bash
cd cookiecutters/python-project/{{cookiecutter.project_slug}}
touch new_file.py
```

Content will be templated:
```python
# new_file.py
"""{{cookiecutter.project_description}} - New Module"""

def hello():
    return "Hello from {{cookiecutter.project_name}}"
```

---

### Post-Generation Hooks

Hooks run after generation. Located in `hooks/` directory:

**`hooks/post_gen_project.py`:**
```python
#!/usr/bin/env python
"""Post-generation hook."""

import os
import subprocess

def main():
    # Initialize git
    subprocess.run(["git", "init"])
    subprocess.run(["git", "add", "."])
    subprocess.run(["git", "commit", "-m", "Initial commit"])
    
    # Create virtual environment
    subprocess.run(["python3", "-m", "venv", ".venv"])
    
    # Install pre-commit
    subprocess.run(["pre-commit", "install"])
    
    # Print next steps
    print("\n✅ Project created!")
    print("Next steps:")
    print("  1. cd {{cookiecutter.project_slug}}")
    print("  2. source .venv/bin/activate")
    print("  3. pip install -e .[dev]")

if __name__ == "__main__":
    main()
```

**Make executable:**
```bash
chmod +x hooks/post_gen_project.py
```

---

### Pre-Generation Hooks

Run before generation (for validation):

**`hooks/pre_gen_project.py`:**
```python
#!/usr/bin/env python
"""Pre-generation hook for validation."""

import re
import sys

project_slug = "{{ cookiecutter.project_slug }}"

# Validate project slug
if not re.match(r'^[a-z][a-z0-9-]+$', project_slug):
    print(f"ERROR: '{project_slug}' is not a valid project slug.")
    print("Must start with letter, contain only lowercase, digits, and hyphens.")
    sys.exit(1)

# Check Python version
python_version = "{{ cookiecutter.python_version }}"
if python_version not in ['3.10', '3.11', '3.12']:
    print(f"ERROR: Python {python_version} is not supported.")
    sys.exit(1)
```

---

## Creating Your Own Templates

### Step 1: Create Directory Structure

```bash
my-template/
├── cookiecutter.json           # Variables definition
├── hooks/                      # Optional
│   ├── pre_gen_project.py
│   └── post_gen_project.py
└── {{cookiecutter.project_slug}}/  # Template content
    ├── README.md
    ├── src/
    └── tests/
```

---

### Step 2: Define Variables

**`cookiecutter.json`:**
```json
{
  "project_name": "My Project",
  "project_slug": "{{ cookiecutter.project_name.lower().replace(' ', '-') }}",
  "description": "A new project",
  "author": "Your Name",
  "version": "0.1.0",
  "python_version": ["3.11", "3.10", "3.12"],
  "use_feature_x": ["yes", "no"]
}
```

---

### Step 3: Create Template Files

**`{{cookiecutter.project_slug}}/README.md`:**
```markdown
# {{cookiecutter.project_name}}

{{cookiecutter.description}}

## Author

{{cookiecutter.author}}

## Version

{{cookiecutter.version}}
```

---

### Step 4: Add Conditional Content

```yaml
# {{cookiecutter.project_slug}}/config.yml
name: {{cookiecutter.project_name}}
version: {{cookiecutter.version}}

{% if cookiecutter.use_feature_x == 'yes' %}
feature_x:
  enabled: true
  settings:
    timeout: 30
{% endif %}
```

---

### Step 5: Test Your Template

```bash
cookiecutter /path/to/my-template

# Or from current directory
cookiecutter .
```

---

### Step 6: Share Your Template

**Publish to GitHub:**
```bash
cd my-template
git init
git add .
git commit -m "Initial template"
git remote add origin git@github.com:username/my-template.git
git push -u origin main
```

**Use from GitHub:**
```bash
cookiecutter gh:username/my-template
```

---

## Tips & Tricks

### Use Default Values Wisely

```json
{
  "author_name": "{% if cookiecutter.get('author_name') %}{{ cookiecutter.author_name }}{% else %}Your Name{% endif %}",
  "author_email": "{{ cookiecutter.get('author_email', 'you@example.com') }}"
}
```

---

### Computed Variables

```json
{
  "project_name": "My Project",
  "project_slug": "{{ cookiecutter.project_name.lower().replace(' ', '-').replace('_', '-') }}",
  "package_name": "{{ cookiecutter.project_slug.replace('-', '_') }}"
}
```

Example:
- `project_name` = "My Cool Project"
- `project_slug` = "my-cool-project"
- `package_name` = "my_cool_project"

---

### Choice Variables

```json
{
  "database": {
    "default": "postgresql",
    "choices": ["postgresql", "mysql", "sqlite", "mongodb"]
  }
}
```

---

### Directory Names

Use variables in directory names too:

```
{{cookiecutter.project_slug}}/
└── {{cookiecutter.package_name}}/
    └── __init__.py
```

---

### Exclude Files

Create `.cookiecutterrc` to exclude patterns:

```yaml
# Don't copy these to generated project
skip_if_file_exists:
  - .git/
  - __pycache__/
  - "*.pyc"
```

---

### Environment Variables

Access environment variables in hooks:

```python
import os

github_username = os.getenv('GITHUB_USERNAME', 'unknown')
```

---

### Validation in Hooks

```python
# hooks/pre_gen_project.py
import sys

# Check dependencies
try:
    import git
except ImportError:
    print("ERROR: Git is required")
    sys.exit(1)

# Validate input
version = "{{ cookiecutter.version }}"
if not version.count('.') == 2:
    print("ERROR: Version must be in format X.Y.Z")
    sys.exit(1)
```

---

### Interactive Confirmation

```python
# hooks/post_gen_project.py
response = input("Install dependencies now? (y/n): ")
if response.lower() == 'y':
    subprocess.run(["pip", "install", "-e", ".[dev]"])
```

---

### Colored Output

```python
# hooks/post_gen_project.py
GREEN = '\033[0;32m'
RED = '\033[0;31m'
NC = '\033[0m'  # No Color

print(f"{GREEN}✅ Project created successfully!{NC}")
print(f"{RED}⚠️  Remember to install dependencies{NC}")
```

---

### Debug Mode

```bash
# See what Cookiecutter is doing
cookiecutter cookiecutters/python-project --verbose

# Keep replay file
cookiecutter cookiecutters/python-project --replay --verbose
```

---

## Troubleshooting

### Template Not Found

```bash
# Use absolute path
cookiecutter /full/path/to/template

# Or relative from current directory
cookiecutter ./cookiecutters/python-project
```

---

### Invalid JSON

```bash
# Validate cookiecutter.json
python3 -c "import json; print(json.load(open('cookiecutter.json')))"

# Or use jq
jq . cookiecutter.json
```

---

### Hook Failures

```bash
# Check hook permissions
ls -l hooks/post_gen_project.py

# Make executable
chmod +x hooks/post_gen_project.py

# Test hook manually
cd generated-project
python3 ../hooks/post_gen_project.py
```

---

### Variable Not Replaced

Check:
1. Variable exists in `cookiecutter.json`
2. Syntax is correct: `{{cookiecutter.var_name}}`
3. No typos in variable name
4. File is in template directory (not hooks/)

---

## Best Practices

1. **Use descriptive variable names**
   - Good: `python_version`, `enable_docker`
   - Bad: `ver`, `docker`

2. **Provide sensible defaults**
   ```json
   {
     "python_version": "3.11",
     "license": "MIT"
   }
   ```

3. **Validate in pre-generation hook**
   - Check required tools are installed
   - Validate variable format
   - Fail early with clear messages

4. **Keep post-generation hooks simple**
   - Basic setup only (git init, venv)
   - Don't do heavy installations
   - Print clear next steps

5. **Document your variables**
   Add README.md to template explaining each variable

6. **Test thoroughly**
   - Test with default values
   - Test with all different options
   - Test hooks both succeed and fail paths

7. **Version your templates**
   - Use git tags: `v1.0.0`, `v1.1.0`
   - Maintain CHANGELOG
   - Support stable and development versions

---

## Resources

- **Cookiecutter Documentation:** https://cookiecutter.readthedocs.io/
- **Jinja2 Template Documentation:** https://jinja.palletsprojects.com/
- **Example Templates:** https://github.com/cookiecutter/cookiecutter#python
- **Our Templates:** See `cookiecutters/` directory

---

## Quick Reference

### Common Commands

```bash
# Create from local template
cookiecutter cookiecutters/python-project

# Create from GitHub
cookiecutter gh:org/repo --directory="path/to/template"

# Non-interactive
cookiecutter template --no-input var1="value" var2="value"

# Replay previous answers
cookiecutter template --replay

# Overwrite existing
cookiecutter template --overwrite-if-exists

# Verbose output
cookiecutter template --verbose
```

### Variable Syntax

```jinja2
# Simple variable
{{ cookiecutter.project_name }}

# With filter
{{ cookiecutter.project_name.lower() }}

# Conditional
{% if cookiecutter.use_docker == 'yes' %}
...
{% endif %}

# Loop
{% for item in cookiecutter.items %}
- {{ item }}
{% endfor %}
```

---

**Last Updated:** 2025-10-13
**Version:** 1.0
