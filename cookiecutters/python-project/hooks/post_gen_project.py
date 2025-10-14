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

def initialize_git():
    """Initialize git repository."""
    print("📦 Initializing git repository...")
    run_command("git init")
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

    # Install project with dev dependencies
    if run_command(f"{venv_pip} install -e .[dev]", check=False):
        print("   ✓ Project and dev dependencies installed")
        return True
    else:
        print("   ⚠️  Failed to install dependencies")
        return False

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
        print("5. Review CLAUDE.md for AI assistant")

    print("\n✅ All dependencies are installed and ready to use!")
    print("\n🔗 Add remote:")
    print("   git remote add origin <your-repo-url>")
    print("   git push -u origin main\n")

def main():
    """Main post-generation logic."""
    try:
        initialize_git()
        create_venv()
        install_dependencies()
        install_precommit()

        # Remove AI workflow if not needed (but keep CLAUDE.md for general use)
        if "{{ cookiecutter.use_ai_workflow }}" == "no":
            if os.path.exists(".github/workflows/ai-workflow.yaml"):
                os.remove(".github/workflows/ai-workflow.yaml")

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
