#!/usr/bin/env python
"""Post-generation hook for Python project."""

import os
import subprocess
import sys

def run_command(cmd, check=True):
    """Run shell command."""
    try:
        result = subprocess.run(cmd, shell=True, check=check,
                                capture_output=True, text=True)
        return result.returncode == 0
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        return False

def setup_claude_context():
    """Copy entire .github/claude/ directory and customize CLAUDE.md
    for new projects."""
    print("• Setting up Claude AI context...")

    use_ai = "{{ cookiecutter.use_ai_workflow }}"

    if use_ai != "yes":
        print("   ⚠️  AI workflow disabled - skipping Claude context setup")
        return False

    # Ensure .github/claude directory exists
    claude_dir = ".github/claude"
    os.makedirs(claude_dir, exist_ok=True)

    # Define source directory paths - try multiple approaches
    script_dir = os.path.dirname(
        os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    )
    possible_source_dirs = [
        # Try from current working directory (most reliable after cookiecutter)
        os.path.join(os.getcwd(), "..", "..", ".github", "claude"),
        # Try from script directory
        os.path.join(script_dir, ".github", "claude"),
        # Try absolute path fallback
        "/home/jokh38/apps/CICD_template/.github/claude"
    ]

    source_claude_dir = None
    for path in possible_source_dirs:
        if os.path.exists(path):
            source_claude_dir = path
            break

    if not source_claude_dir:
        print("   ⚠️  Source .github/claude/ directory not found")
        return False

    # Copy entire .github/claude/ directory structure
    import shutil
    copied_files = []

    try:
        # Walk through source directory and copy all files
        for root, _dirs, files in os.walk(source_claude_dir):
            # Calculate relative path from source_claude_dir
            rel_path = os.path.relpath(root, source_claude_dir)
            if rel_path != '.':
                target_dir = os.path.join(claude_dir, rel_path)
            else:
                target_dir = claude_dir

            # Create target directory if it doesn't exist
            os.makedirs(target_dir, exist_ok=True)

            for file in files:
                source_file = os.path.join(root, file)
                target_file = os.path.join(target_dir, file)

                # Copy file
                shutil.copy2(source_file, target_file)
                copied_files.append(os.path.relpath(target_file))

                # Customize CLAUDE.md if this is the file
                if file == "CLAUDE.md":
                    customize_claude_md(target_file)

        print(f"   • Copied {len(copied_files)} AI workflow files to .github/claude/")
        return True

    except Exception as e:
        print(f"   ❌ Error copying .github/claude/ directory: {e}")
        return False

def customize_claude_md(claude_md_path):
    """Customize CLAUDE.md file with project-specific values."""
    try:
        # Read the file
        with open(claude_md_path, encoding='utf-8') as f:
            content = f.read()

        # Get actual cookiecutter values
        project_name = "{{ cookiecutter.project_name }}"
        project_description = "{{ cookiecutter.project_description }}"
        python_version = "{{ cookiecutter.python_version }}"

        # Replace cookiecutter variables with actual project values
        replacements = {
            '{{cookiecutter.project_name}}': project_name,
            '{{cookiecutter.project_description}}': project_description,
            '{{cookiecutter.python_version}}': python_version,
        }

        for template_var, actual_value in replacements.items():
            content = content.replace(template_var, actual_value)

        # Handle Jinja2 conditionals for Python projects
        conditional_str = (
            '{% if cookiecutter.python_version is defined %}Python '
            '{{cookiecutter.python_version}}{% else %}C++ '
            '{{cookiecutter.cpp_standard}}{% endif %}'
        )
        content = content.replace(conditional_str, f'Python {python_version}')

        # Write the customized file
        with open(claude_md_path, 'w', encoding='utf-8') as f:
            f.write(content)

        return True

    except Exception as e:
        print(f"   ⚠️  Error customizing CLAUDE.md: {e}")
        return False

def copy_claude_md():
    """Copy HIVE_CLAUDE.md from docs/ directory as CLAUDE.md to project root."""
    import shutil

    print("• Setting up CLAUDE.md documentation...")

    # Define possible source paths for HIVE_CLAUDE.md
    script_dir = os.path.dirname(
        os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    )
    possible_source_paths = [
        # Try from current working directory (most reliable after cookiecutter)
        os.path.join(os.getcwd(), "..", "..", "docs", "HIVE_CLAUDE.md"),
        # Try from script directory
        os.path.join(script_dir, "docs", "HIVE_CLAUDE.md"),
        # Try absolute path fallback
        "/home/jokh38/apps/CICD_template/docs/HIVE_CLAUDE.md"
    ]

    source_hive_claude = None
    for path in possible_source_paths:
        if os.path.exists(path):
            source_hive_claude = path
            break

    if not source_hive_claude:
        print("   ⚠️  Source HIVE_CLAUDE.md not found in docs/")
        return False

    try:
        # Copy HIVE_CLAUDE.md as CLAUDE.md to project root
        shutil.copy2(source_hive_claude, "CLAUDE.md")
        print("   • CLAUDE.md copied to project root")
        return True
    except Exception as e:
        print(f"   ❌ Error copying HIVE_CLAUDE.md: {e}")
        return False

def initialize_git():
    """Initialize git repository."""
    print("• Initializing git repository...")
    run_command("git init")

    # Configure git user if not already configured
    if not run_command("git config user.name", check=False):
        run_command('git config user.name "Template User"')
    if not run_command("git config user.email", check=False):
        run_command('git config user.email "template@example.com"')

    run_command("git add .")
    run_command('git commit -m "Initial commit from template"')

def create_venv():
    """Create virtual environment."""
    print("• Creating Python virtual environment...")
    python_version = "{{ cookiecutter.python_version }}"
    run_command(f"python{python_version} -m venv .venv")

def install_dependencies():
    """Install project dependencies including dev dependencies."""
    print("• Installing project dependencies...")
    venv_pip = ".venv/bin/pip"

    # Upgrade pip first
    run_command(f"{venv_pip} install --upgrade pip", check=False)

    # Install basic dev dependencies individually to avoid dependency conflicts
    dev_packages = ["pytest", "pytest-cov", "ruff", "mypy", "pre-commit"]
    installed_count = 0

    for package in dev_packages:
        if run_command(f"{venv_pip} install {package}", check=False):
            installed_count += 1

    # Try to install project with dev dependencies as fallback
    if installed_count < len(dev_packages):
        run_command(f"{venv_pip} install -e .[dev]", check=False)

    return installed_count > 0

def setup_serena_configuration():
    """Create Serena-specific configuration and memory system."""
    print("• Setting up Serena configuration...")

    use_ai = "{{ cookiecutter.use_ai_workflow }}"

    if use_ai != "yes":
        print("   ⚠️  AI workflow disabled - skipping Serena configuration")
        return False

    # Create .serena directory structure
    serena_dir = ".serena"
    memories_dir = os.path.join(serena_dir, "memories")

    try:
        os.makedirs(memories_dir, exist_ok=True)

        # Create project configuration file
        project_name = "{{ cookiecutter.project_name }}"
        project_description = "{{ cookiecutter.project_description }}"
        python_version = "{{ cookiecutter.python_version }}"

        config_content = f"""# Serena Project Configuration
# Generated by CICD Template for {project_name}

project:
  name: "{project_name}"
  description: "{project_description}"
  language: "python"
  version: "{python_version}"

# Recommended Serena settings for this project
serena_config:
  # Enable all tools for maximum value
  enable_shell_tools: true
  enable_editing_tools: true
  enable_web_access: true

  # Recommended context for Claude Desktop users
  context: "desktop-app"

  # Recommended modes for different tasks
  modes:
    planning_tasks: ["planning", "one-shot"]
    editing_tasks: ["editing", "interactive"]
    development_sessions: ["planning", "interactive"]

  # Project-specific settings
  test_command: ".venv/bin/pytest tests/ -v"
  lint_command: ".venv/bin/ruff check ."
  format_command: ".venv/bin/ruff format ."
  type_check_command: ".venv/bin/mypy src/"

  # Memory system enabled
  enable_memories: true

  # Quality integration
  respect_git_hooks: true
  auto_fix_linting: true
  run_tests_on_changes: true

# Development workflow integration
workflow:
  # Serena can use these commands for autonomous development
  build_command: ".venv/bin/pip install -e ."
  test_coverage: ".venv/bin/pytest tests/ --cov=src --cov-report=term-missing"
  security_check: ".venv/bin/safety check"

  # Pre-commit integration
  pre_commit_test: ".venv/bin/pre-commit run --all-files"
"""

        config_file = os.path.join(serena_dir, "config.yml")
        with open(config_file, 'w', encoding='utf-8') as f:
            f.write(config_content)

        print(f"   • Created Serena configuration: {config_file}")

        # Create initial memory file with project information
        memory_content = f"""# Project Memory: {project_name}
# Generated on project creation

## Project Overview
{project_description}

## Technical Stack
- **Language**: Python {python_version}
- **Testing**: pytest with coverage
- **Linting**: ruff (formatting + linting)
- **Type Checking**: mypy
- **Virtual Environment**: .venv/
- **Git Hooks**: Pre-commit hooks installed and configured

## Development Workflow
1. **Activate Environment**: `source .venv/bin/activate`
2. **Run Tests**: `pytest tests/ -v`
3. **Lint Code**: `ruff check . && ruff format .`
4. **Type Check**: `mypy src/`

## Common Commands
- Development setup: `source .venv/bin/activate`
- Install dependencies: `pip install -e .[dev]`
- Run tests: `pytest tests/ -v --cov=src`
- Format code: `ruff format .`
- Check linting: `ruff check .`
- Type checking: `mypy src/`
"""

        memory_file = os.path.join(memories_dir, "project_overview.md")
        with open(memory_file, 'w', encoding='utf-8') as f:
            f.write(memory_content)

        # Create Serena usage guide
        usage_guide = f"""# Serena Usage Guide for {project_name}

## Quick Start
1. Ensure Serena MCP is installed and enabled in Claude Code
2. Enable all tools (shell execution, editing, web access) for maximum value
3. Start with onboarding mode to let Serena analyze the codebase

## Capabilities
- **Test Execution**: Serena can run `pytest tests/` and fix failures
- **Code Quality**: Auto-fix ruff linting and formatting issues
- **Build Management**: Handle dependency installation and updates
- **Documentation**: Generate and update project documentation

## Best Practices
- Start with clean git state when using Serena
- Review Serena's changes with `git diff` before committing
- Allow Serena to complete onboarding on first use
"""

        guide_file = os.path.join(serena_dir, "USAGE_GUIDE.md")
        with open(guide_file, 'w', encoding='utf-8') as f:
            f.write(usage_guide)

        return True

    except Exception as e:
        print(f"   ❌ Error setting up Serena configuration: {e}")
        return False

def install_serena_mcp():
    """Install Serena MCP server for Claude Code with enhanced configuration."""
    print("• Setting up Serena MCP integration...")

    use_ai = "{{ cookiecutter.use_ai_workflow }}"

    if use_ai != "yes":
        print("   ⚠️  AI workflow disabled - skipping Serena MCP setup")
        return False

    # Setup Serena configuration first
    setup_serena_configuration()

    # Check if Claude Code CLI is available
    if not run_command("which claude", check=False):
        print("   ⚠️  Claude Code CLI not found - skipping Serena MCP setup")
        return False

    # Check if Serena MCP is already installed
    if run_command("claude mcp list | grep serena", check=False):
        print("   • Serena MCP already installed")
        return True

    # Install Serena MCP
    install_cmd = 'claude mcp add-json "serena" \'{"command":"uvx","args":["--from","git+https://github.com/oraios/serena","serena-mcp-server"]}\''

    if run_command(install_cmd, check=False):
        print("   • Serena MCP installed successfully")
        return True
    else:
        print("   ⚠️  Failed to install Serena MCP")
        return False

def install_pre_commit():
    """Install pre-commit hooks."""
    print("• Installing pre-commit hooks...")

    use_git_hooks = "{{ cookiecutter.use_git_hooks }}"

    if use_git_hooks == "no":
        print("   ⚠️  Git hooks disabled by configuration")
        return False

    # Check if pre-commit is available
    venv_pip = ".venv/bin/pip"
    pre_commit_cmd = ".venv/bin/pre-commit"

    # Install pre-commit if not available
    if not os.path.exists(pre_commit_cmd):
        run_command(f"{venv_pip} install pre-commit", check=False)

    # Install pre-commit hooks
    if os.path.exists(pre_commit_cmd):
        if run_command(pre_commit_cmd + " install", check=False):
            return True
    return False

def install_pre_push_hook():
    """Install custom pre-push hook for testing and dynamic analysis."""
    print("• Installing pre-push hook...")

    use_git_hooks = "{{ cookiecutter.use_git_hooks }}"

    if use_git_hooks == "no":
        print("   ⚠️  Git hooks disabled by configuration")
        return False

    # Copy the pre-push hook template to .git/hooks/
    hooks_dir = ".git/hooks"
    pre_push_source = "hooks/pre-push"
    pre_push_target = os.path.join(hooks_dir, "pre-push")

    if os.path.exists(pre_push_source):
        try:
            import shutil
            shutil.copy2(pre_push_source, pre_push_target)
            os.chmod(pre_push_target, 0o755)  # Make executable
            return True
        except Exception:
            return False
    return False

def print_next_steps():
    """Print next steps for user."""
    project_name = "{{ cookiecutter.project_name }}"
    use_git_hooks = "{{ cookiecutter.use_git_hooks }}"
    use_ai = "{{ cookiecutter.use_ai_workflow }}"

    print("\n" + "=" * 60)
    print("✅ Project created!")
    print("=" * 60)
    print(f"\n• Project: {project_name}")
    print(f"• Git Hooks: {use_git_hooks}")
    print(f"• AI Workflow: {use_ai}")

    if use_git_hooks == "yes":
        print("\n• Pre-commit hooks are installed and will run automatically")
        print("• Pre-push hooks are installed and will run tests/dynamic analysis")
        print("• Run 'pre-commit run --all-files' to check all files manually")
        print("• 🔴 IMPORTANT: Never use 'git commit --no-verify' - bypasses checks!")
        print("• 🔴 IMPORTANT: Never use 'git push --no-verify' - bypasses testing!")
    else:
        print("\n• Git hooks are disabled - manual quality checks required")

    if use_ai == "yes":
        print("• Serena MCP integration is configured for enhanced AI capabilities")

def main():
    """Main post-generation logic."""
    try:
        # Setup Claude AI context if enabled
        setup_claude_context()
        copy_claude_md()

        initialize_git()
        create_venv()
        install_dependencies()
        install_pre_commit()
        install_pre_push_hook()
        install_serena_mcp()

        # Remove AI workflow if not needed (but keep docs/CLAUDE.md for general use)
        ai_workflow_disabled = "{{ cookiecutter.use_ai_workflow }}" == "no"
        if ai_workflow_disabled and os.path.exists(".github/claude"):
            import shutil
            shutil.rmtree(".github/claude")
            run_command("git add .github/claude")

        # Remove license if None
        if "{{ cookiecutter.license }}" == "None" and os.path.exists("LICENSE"):
            os.remove("LICENSE")

        print_next_steps()

    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
