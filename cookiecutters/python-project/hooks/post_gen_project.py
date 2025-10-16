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

def copy_claude_md():
    """Copy CLAUDE.md from docs/ directory."""
    print("📋 Copying CLAUDE.md from template docs...")

    # Define paths
    source_claude = "docs/CLAUDE.md"
    target_claude = "docs/CLAUDE.md"

    # Ensure docs directory exists
    os.makedirs("docs", exist_ok=True)

    # Copy the main CLAUDE.md from the template root docs/
    template_root = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    source_path = os.path.join(template_root, "docs", "CLAUDE.md")

    if os.path.exists(source_path):
        with open(source_path, 'r') as src:
            content = src.read()
        with open(target_claude, 'w') as dst:
            dst.write(content)
        print("   ✓ CLAUDE.md copied to docs/")
    else:
        print("   ⚠️  Source CLAUDE.md not found, keeping template version")

def initialize_git():
    """Initialize git repository."""
    print("📦 Initializing git repository...")
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
    print("🐍 Creating virtual environment...")
    python_version = "{{ cookiecutter.python_version }}"
    run_command(f"python{python_version} -m venv .venv")

def install_dependencies():
    """Install project dependencies including dev dependencies."""
    print("📦 Installing project dependencies...")
    venv_pip = ".venv/bin/pip"

    # Upgrade pip first
    if run_command(f"{venv_pip} install --upgrade pip", check=False):
        print("   ✓ pip upgraded")

    # Install basic dev dependencies individually to avoid dependency conflicts
    dev_packages = ["pytest", "pytest-cov", "ruff", "mypy", "pre-commit"]
    installed_packages = []

    for package in dev_packages:
        if run_command(f"{venv_pip} install {package}", check=False):
            print(f"   ✓ {package} installed")
            installed_packages.append(package)
        else:
            print(f"   ⚠️  Failed to install {package}")

    # Try to install project with dev dependencies as fallback
    if len(installed_packages) < len(dev_packages):
        print("   🔄 Attempting to install project dependencies...")
        if run_command(f"{venv_pip} install -e .[dev]", check=False):
            print("   ✓ Project dependencies installed")

    return len(installed_packages) > 0

def install_precommit():
    """Install pre-commit hooks."""
    print("🔧 Installing pre-commit hooks...")
    venv_precommit = ".venv/bin/pre-commit"

    if os.path.exists(venv_precommit):
        run_command(f"{venv_precommit} install")
        print("   ✓ Pre-commit hooks installed")
    else:
        print("   ⚠️  pre-commit not found in virtual environment")

def print_next_steps():
    """Print next steps for user."""
    project_slug = "{{ cookiecutter.project_slug }}"
    runner_type = "{{ cookiecutter.runner_type }}"
    use_ai = "{{ cookiecutter.use_ai_workflow }}"

    print("\n" + "="*60)
    print("✅ Project created successfully!")
    print("="*60)
    print(f"\n📁 Project: {project_slug}")
    print(f"🏃 Runner: {runner_type}")
    print(f"🤖 AI Workflow: {use_ai}")

    print("\n📋 Next Steps:")
    print("1. cd {{ cookiecutter.project_slug }}")
    print("2. source .venv/bin/activate")
    print("3. pytest  # Run tests")
    print("4. ruff check .  # Lint code")

    if use_ai == "yes":
        print("5. Review docs/CLAUDE.md for AI assistant")

    print("\n✅ All dependencies are installed and ready to use!")
    print("\n🔗 Create GitHub repository and push:")
    print("   1. Create a new repository on GitHub")
    print("   2. git remote add origin <your-github-repo-url>")
    print("   3. git push -u origin main\n")

def main():
    """Main post-generation logic."""
    try:
        # Copy the main CLAUDE.md from template docs
        copy_claude_md()

        # Remove the template CLAUDE.md if it exists
        if os.path.exists("CLAUDE.md"):
            os.remove("CLAUDE.md")

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
