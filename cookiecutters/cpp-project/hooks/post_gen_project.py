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
    print("📦 Initializing git repository...")
    run_command("git init")

    # Configure git user if not already configured
    if not run_command("git config user.name", check=False):
        run_command('git config user.name "Template User"')
    if not run_command("git config user.email", check=False):
        run_command('git config user.email "template@example.com"')

    run_command("git add .")
    run_command('git commit -m "Initial commit from template"')

def install_precommit():
    """Install pre-commit tool and hooks."""
    print("🔧 Installing pre-commit...")

    # Try to install pre-commit via pip (user level)
    if not run_command("which pre-commit", check=False):
        print("   Installing pre-commit via pip...")
        if run_command("pip install --user pre-commit", check=False):
            print("   ✓ pre-commit installed")
        else:
            print("   ⚠️  Failed to install pre-commit. Please install manually:")
            print("      pip install pre-commit")
            return

    # Install pre-commit hooks
    if run_command("pre-commit install", check=False):
        print("   ✓ Pre-commit hooks installed")
    else:
        print("   ⚠️  Failed to install pre-commit hooks")

def setup_build_directory():
    print("🏗️  Creating build directory...")
    os.makedirs("build", exist_ok=True)

def print_next_steps():
    project_slug = "{{ cookiecutter.project_slug }}"
    build_system = "{{ cookiecutter.build_system }}"
    use_ninja = "{{ cookiecutter.use_ninja }}"

    print("\n" + "="*60)
    print("✅ Project created!")
    print("="*60)
    print(f"\n📁 Project: {project_slug}")
    print(f"🔨 Build: {build_system}")

    print("\n🚀 Quick Start - Validate Your Environment:")
    print("   bash setup-scripts/linux/validation/run-validation.sh")

    print("\n📋 Next Steps:")
    print("1. cd {{ cookiecutter.project_slug }}")

    if build_system == "cmake":
        gen = "-G Ninja" if use_ninja == "yes" else ""
        print(f"2. cmake -B build {gen}")
        print("3. cmake --build build")
        print("4. ctest --test-dir build")
    else:
        print("2. meson setup build")
        print("3. meson compile -C build")
        print("4. meson test -C build")

    print("\n🔧 Additional Validation Options:")
    print("   • Comprehensive: bash setup-scripts/total_run.sh --validate-only")
    print("   • Final: bash setup-scripts/total_run.sh --final-validation")

    print("\n✅ Pre-commit hooks are installed and ready to use!")
    print("\n🔗 Create GitHub repository and push:")
    print("   1. Create a new repository on GitHub")
    print("   2. git remote add origin <your-github-repo-url>")
    print("   3. git push -u origin main\n")

def main():
    try:
        # Copy the main CLAUDE.md from template docs
        copy_claude_md()

        # Remove the template CLAUDE.md if it exists
        if os.path.exists("CLAUDE.md"):
            os.remove("CLAUDE.md")

        initialize_git()
        install_precommit()
        setup_build_directory()

        # Cleanup
        if "{{ cookiecutter.use_ai_workflow }}" == "no":
            # Only remove AI workflow files, keep docs/CLAUDE.md for general use
            if os.path.exists(".github/workflows/ai-workflow.yaml"):
                os.remove(".github/workflows/ai-workflow.yaml")
                run_command("git add .github/workflows/ai-workflow.yaml")

        if "{{ cookiecutter.license }}" == "None":
            if os.path.exists("LICENSE"):
                os.remove("LICENSE")
                run_command("git add LICENSE")

        # Remove unused build system files
        if "{{ cookiecutter.build_system }}" == "cmake":
            if os.path.exists("meson.build"):
                os.remove("meson.build")
        else:
            if os.path.exists("CMakeLists.txt"):
                os.remove("CMakeLists.txt")

        print_next_steps()

    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
