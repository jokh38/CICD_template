#!/usr/bin/env python
"""Post-generation hook for C++ project."""

import os
import subprocess
import sys

def run_command(cmd, check=True):
    try:
        result = subprocess.run(cmd, shell=True, check=check,
                                capture_output=True, text=True)
        return result.returncode == 0
    except subprocess.CalledProcessError as e:
        print("Error: {}".format(e))
        return False

def initialize_git():
    print("• Initializing git repository...")
    run_command("git init")

    # Configure git user if not already configured
    if not run_command("git config user.name", check=False):
        run_command('git config user.name "Template User"')
    if not run_command("git config user.email", check=False):
        run_command('git config user.email "template@example.com"')

    run_command("git add .")
    run_command('git commit -m "Initial commit from template"')

def setup_build_directory():
    print("• Creating build directory...")
    os.makedirs("build", exist_ok=True)

def install_pre_commit():
    """Install pre-commit hooks for C++ projects."""
    print("• Installing pre-commit hooks...")

    use_git_hooks = "{{ cookiecutter.use_git_hooks }}"

    if use_git_hooks == "no":
        print("   ⚠️  Git hooks disabled by configuration")
        return False

    # Check if pre-commit is available in the system
    if not run_command("which pre-commit", check=False):
        print("   • Installing pre-commit...")
        # Try to install pre-commit using pip
        if not run_command("pip install pre-commit", check=False):
            print("   ❌ Failed to install pre-commit. Please install it manually:")
            print("      pip install pre-commit")
            return False

    # Install pre-commit hooks
    print("   • Installing pre-commit hooks...")
    if run_command("pre-commit install", check=False):
        print("   • Pre-commit hooks installed successfully")
        return True
    else:
        print("   ❌ Failed to install pre-commit hooks")
        print("   ⚠️  You can install manually later with: pre-commit install")
        return False

def print_next_steps():
    project_name = "{{ cookiecutter.project_name }}"
    project_slug = "{{ cookiecutter.project_slug }}"
    build_system = "{{ cookiecutter.build_system }}"
    use_git_hooks = "{{ cookiecutter.use_git_hooks }}"

    print("\n" + "="*60)
    print("✅ Project created!")
    print("="*60)
    print("\n• Project: {}".format(project_name))
    print("• Build: {}".format(build_system))
    print("• Git Hooks: {}".format(use_git_hooks))

    print("\n• Quick Start:")
    print("  1. cd {}".format(project_slug))
    print("  2. mkdir build && cd build")
    if build_system == "cmake":
        print("  3. cmake ..")
        print("  4. make")
    else:
        print("  3. meson setup")
        print("  4. ninja")
    print("  5. ctest  # Run tests")

    if use_git_hooks == "yes":
        print("\n• Pre-commit hooks are installed and will run automatically on commit")
        print("• Run 'pre-commit run --all-files' to check all files manually")
    else:
        print("\n• Pre-commit hooks are disabled - manual quality checks required")

def main():
    try:
        initialize_git()
        setup_build_directory()
        install_pre_commit()
        print_next_steps()
    except Exception as e:
        print("\n❌ Error: {}".format(e))
        sys.exit(1)

if __name__ == "__main__":
    main()