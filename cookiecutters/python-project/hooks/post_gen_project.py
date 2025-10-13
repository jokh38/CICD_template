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

def install_precommit():
    """Install pre-commit hooks."""
    print("🔧 Installing pre-commit hooks...")
    if run_command("which pre-commit", check=False):
        run_command("pre-commit install")
    else:
        print("⚠️  pre-commit not found. Install: pip install pre-commit")

def create_venv():
    """Create virtual environment."""
    print("🐍 Creating virtual environment...")
    python_version = "{{ cookiecutter.python_version }}"
    run_command(f"python{python_version} -m venv .venv")

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
    print("3. pip install -e .[dev]")

    if use_ai == "yes":
        print("4. Review CLAUDE.md for AI assistant")

    print("\n🔗 Add remote:")
    print("   git remote add origin <your-repo-url>")
    print("   git push -u origin main\n")

def main():
    """Main post-generation logic."""
    try:
        initialize_git()
        install_precommit()
        create_venv()

        # Remove AI workflow if not needed
        if "{{ cookiecutter.use_ai_workflow }}" == "no":
            for f in ["CLAUDE.md", ".github/workflows/ai-workflow.yaml"]:
                if os.path.exists(f):
                    os.remove(f)

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
