# GitHub Label Automation for CICD Template

This document explains how GitHub labels are automatically configured for projects created from the CICD template.

## Overview

The CICD template automatically creates GitHub labels that are essential for AI automation workflows. This resolves issues where labels referenced in workflows (like `claude` and `ai-assist`) were missing, causing workflow failures.

## Problem Solved

**Before**: Creating a project from the template didn't automatically set up required labels, causing errors like:
```
could not add label: 'claude' not found
```

**After**: Labels are automatically created when new projects are generated from templates.

## Implementation

### 1. Template-Based Label Configuration

Labels are defined in `.github/labels.yml` files within the cookiecutter templates:

- **Python Template**: `cookiecutters/python-project/{{cookiecutter.project_slug}}/.github/labels.yml`
- **C++ Template**: `cookiecutters/cpp-project/{{cookiecutter.project_slug}}/.github/labels.yml`

When a new project is created using cookiecutter, these files are copied to the new repository and GitHub automatically creates the labels.

### 2. Manual Label Setup Script

For existing projects or manual setup, use the `scripts/setup-labels.sh` script:

```bash
# Setup all labels
bash scripts/setup-labels.sh

# Setup only AI labels
bash scripts/setup-labels.sh --ai-only

# Setup only default labels
bash scripts/setup-labels.sh --defaults
```

## Available Labels

### AI & Automation Labels
- **`claude`** - Issues and PRs related to Claude AI automation (yellow)
- **`ai-assist`** - Issues requiring AI assistance or automation (orange)
- **`ai-automation`** - Automated tasks performed by AI assistants (purple)
- **`claude-code-review`** - Code reviews performed by Claude AI (pink)
- **`automated-pr`** - Pull requests created automatically by AI (deep purple)

### Enhanced Default Labels
All standard GitHub labels with improved descriptions:
- `bug`, `documentation`, `enhancement`, `good first issue`, `help wanted`, etc.

### Workflow Labels
- `dependencies` - Dependency updates
- `security` - Security vulnerabilities
- `performance` - Performance improvements
- `refactor` - Code refactoring
- `tests` - Test coverage improvements
- `build/ci` - Build and CI/CD related

### Priority Labels
- `priority/low`, `priority/medium`, `priority/high`, `priority/critical`

### Size Labels
- `size/xs` (1-10 lines), `size/s` (10-50 lines), `size/m` (50-200 lines),
- `size/l` (200-500 lines), `size/xl` (500+ lines)

### Project-Specific Labels
- `python` - Python-specific issues (blue)
- `cpp` - C++ specific issues (dark red)
- `cmake` - CMake build system (navy)
- `meson` - Meson build system (green)
- `github-actions` - GitHub Actions workflows (black)

## Usage Examples

### Creating Issues with Labels
```bash
# Create an issue with AI automation label
gh issue create --title "Feature: Add user authentication" --label "enhancement,claude"

# Create a bug report
gh issue create --title "Fix memory leak in parser" --label "bug,cpp,priority/high"

# Request AI assistance
gh issue create --title "AI: Refactor authentication module" --label "refactor,ai-assist,python"
```

### Creating Pull Requests with Labels
```bash
# Create PR with labels
gh pr create --title "Add new feature" --label "enhancement,python,size/m"

# Create AI-automated PR
gh pr create --title "Automated: Fix security vulnerability" --label "security,automated-pr"
```

### Using Labels in Workflows

Labels are used throughout the AI automation workflows:

```yaml
# Example: Trigger AI workflow based on labels
if: contains(github.event.label.name, 'ai-assist') || github.event_name == 'workflow_dispatch'
```

## Integration with AI Workflows

The labels integrate seamlessly with the AI automation features:

1. **`claude` label**: Used for triggering Claude AI workflows
2. **`ai-assist` label**: Marks issues that need AI assistance
3. **`automated-pr` label**: Applied to PRs created by AI
4. **Priority labels**: Help AI prioritize tasks
5. **Size labels**: Provide context for AI about task complexity

## For Existing Projects

If you have an existing project created from the template before this feature was added:

1. **Option 1**: Use the setup script
   ```bash
   bash path/to/CICD_template/scripts/setup-labels.sh
   ```

2. **Option 2**: Copy the label file manually
   ```bash
   # For Python projects
   cp path/to/CICD_template/cookiecutters/python-project/project_slug/.github/labels.yml .github/

   # For C++ projects
   cp path/to/CICD_template/cookiecutters/cpp-project/project_slug/.github/labels.yml .github/
   ```

3. **Option 3**: Create labels manually with GitHub CLI
   ```bash
   gh label create claude --color f1e05a --description "Issues and PRs related to Claude AI automation"
   gh label create ai-assist --color ff9800 --description "Issues requiring AI assistance or automation"
   ```

## Validation

After setup, verify labels are created:

```bash
# List all labels
gh label list

# Check for AI labels
gh label list --search "claude"

# Check total count
gh label list --limit 1000 | wc -l
```

## Troubleshooting

### Label Creation Fails
- Ensure you have repository admin permissions
- Check that GitHub CLI is authenticated: `gh auth status`
- Verify you're in the correct repository

### Labels Not Applied in Workflows
- Check workflow YAML syntax
- Ensure label names match exactly (case-sensitive)
- Verify GitHub Actions permissions allow label manipulation

### Template Generation Issues
- Ensure cookiecutter is installed and updated
- Check template file permissions
- Verify template directory structure

## Future Enhancements

Potential improvements to the label system:

1. **Dynamic Label Creation**: Automatically create project-specific labels based on configuration
2. **Label Workflows**: Automation to apply labels based on file changes or content
3. **Label Analytics**: Track label usage patterns for project insights
4. **Integration with Project Management**: Sync labels with external project tools