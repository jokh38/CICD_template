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
    """Copy entire .github/claude/ directory and customize CLAUDE.md for new projects."""
    print("• Setting up Claude AI context...")

    # Ensure .github/claude directory exists
    claude_dir = ".github/claude"
    os.makedirs(claude_dir, exist_ok=True)

    # Define source directory paths - try multiple approaches
    possible_source_dirs = [
        # Try from current working directory (most reliable after cookiecutter)
        os.path.join(os.getcwd(), "..", "..", ".github", "claude"),
        # Try from script directory
        os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), ".github", "claude"),
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
        print(f"   Tried paths: {possible_source_dirs}")
        return False

    # Copy entire .github/claude/ directory structure
    import shutil
    copied_files = []

    try:
        # Walk through source directory and copy all files
        for root, dirs, files in os.walk(source_claude_dir):
            # Calculate relative path from source_claude_dir
            rel_path = os.path.relpath(root, source_claude_dir)
            target_dir = os.path.join(claude_dir, rel_path) if rel_path != '.' else claude_dir

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
        print("   • Commands, prompts, and documentation ready")
        return True

    except Exception as e:
        print(f"   ❌ Error copying .github/claude/ directory: {e}")
        return False

def customize_claude_md(claude_md_path):
    """Customize CLAUDE.md file with project-specific values."""
    try:
        # Read the file
        with open(claude_md_path, 'r', encoding='utf-8') as f:
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
        content = content.replace(
            '{% if cookiecutter.python_version is defined %}Python {{cookiecutter.python_version}}{% else %}C++ {{cookiecutter.cpp_standard}}{% endif %}',
            f'Python {python_version}'
        )

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
    possible_source_paths = [
        # Try from current working directory (most reliable after cookiecutter)
        os.path.join(os.getcwd(), "..", "..", "docs", "HIVE_CLAUDE.md"),
        # Try from script directory
        os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "docs", "HIVE_CLAUDE.md"),
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
        print(f"   Tried paths: {possible_source_paths}")
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
    print("• Creating virtual environment...")
    python_version = "{{ cookiecutter.python_version }}"
    run_command(f"python{python_version} -m venv .venv")

def install_dependencies():
    """Install project dependencies including dev dependencies."""
    print("• Installing project dependencies...")
    venv_pip = ".venv/bin/pip"

    # Upgrade pip first
    if run_command(f"{venv_pip} install --upgrade pip", check=False):
        print("   • pip upgraded")

    # Install basic dev dependencies individually to avoid dependency conflicts
    dev_packages = ["pytest", "pytest-cov", "ruff", "mypy", "pre-commit"]
    installed_packages = []

    for package in dev_packages:
        if run_command(f"{venv_pip} install {package}", check=False):
            print(f"   • {package} installed")
            installed_packages.append(package)
        else:
            print(f"   ⚠️  Failed to install {package}")

    # Try to install project with dev dependencies as fallback
    if len(installed_packages) < len(dev_packages):
        print("   • Attempting to install project dependencies...")
        if run_command(f"{venv_pip} install -e .[dev]", check=False):
            print("   • Project dependencies installed")

    return len(installed_packages) > 0

def install_precommit():
    """Install pre-commit hooks."""
    print("• Installing pre-commit hooks...")
    venv_precommit = ".venv/bin/pre-commit"

    if os.path.exists(venv_precommit):
        run_command(f"{venv_precommit} install")
        pass  # Success, no message needed
    else:
        print("   ⚠️  pre-commit not found in virtual environment")

def print_next_steps():
    """Print next steps for user."""
    project_name = "{{ cookiecutter.project_name }}"
    project_slug = "{{ cookiecutter.project_slug }}"
    runner_type = "{{ cookiecutter.runner_type }}"
    use_ai = "{{ cookiecutter.use_ai_workflow }}"

    print("\n" + "="*60)
    print("✅ Project created!")
    print("="*60)
    print(f"\n• Project: {project_name}")
    print(f"• Runner: {runner_type}")
    print(f"• AI Workflow: {use_ai}")

    print("\n• Next Steps:")
    print(f"  1. cd {project_slug}")
    print("  2. source .venv/bin/activate")
    print("  3. pytest  # Run tests")
    print("  4. ruff check .  # Lint code")

    if use_ai == "yes":
        print("  5. Review .github/claude/CLAUDE.md for AI assistant")

    print("\n• All dependencies are installed and ready to use!")
    print("\n• Create GitHub repository and push:")
    print("  1. Create a new repository on GitHub")
    print("  2. git remote add origin <your-github-repo-url>")
    print("  3. git push -u origin main")

def main():
    """Main post-generation logic."""
    try:
        # Setup Claude AI context with template variables
        setup_claude_context()

        # Copy HIVE_CLAUDE.md as CLAUDE.md to project root
        copy_claude_md()

        initialize_git()
        create_venv()
        install_dependencies()
        install_precommit()

        # Remove AI workflow if not needed (but keep docs/CLAUDE.md for general use)
        if "{{ cookiecutter.use_ai_workflow }}" == "no":
            if os.path.exists(".github/workflows/ai-workflow.yaml"):
                os.remove(".github/workflows/ai-workflow.yaml")
                run_command("git add .github/workflows/ai-workflow.yaml")

        # Remove license if None
        if "{{ cookiecutter.license }}" == "None":
            if os.path.exists("LICENSE"):
                os.remove("LICENSE")

        print_next_steps()

    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
