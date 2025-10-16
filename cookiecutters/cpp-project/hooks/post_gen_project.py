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

def setup_claude_context():
    """Copy and customize CLAUDE.md for new projects."""
    print("📋 Setting up Claude AI context...")

    # Ensure .github/claude directory exists
    claude_dir = ".github/claude"
    os.makedirs(claude_dir, exist_ok=True)

    # Define source and target paths
    template_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
    source_path = os.path.join(template_root, ".github", "claude", "CLAUDE.md")
    target_path = os.path.join(claude_dir, "CLAUDE.md")

    if os.path.exists(source_path):
        # Read the template
        with open(source_path, 'r', encoding='utf-8') as src:
            content = src.read()

        # Get actual cookiecutter values
        project_name = "{{ cookiecutter.project_name }}"
        project_description = "{{ cookiecutter.project_description }}"
        cpp_standard = "{{ cookiecutter.cpp_standard }}"

        # Replace cookiecutter variables with actual project values
        replacements = {
            '{{cookiecutter.project_name}}': project_name,
            '{{cookiecutter.project_description}}': project_description,
            '{{cookiecutter.cpp_standard}}': cpp_standard,
        }

        for template_var, actual_value in replacements.items():
            content = content.replace(template_var, actual_value)

        # Handle Jinja2 conditionals for C++ projects
        # Replace the conditional block with C++ specific content
        content = content.replace(
            '{% if cookiecutter.python_version is defined %}Python {{cookiecutter.python_version}}{% else %}C++ {{cookiecutter.cpp_standard}}{% endif %}',
            f'C++ {cpp_standard}'
        )

        # Write the customized file
        with open(target_path, 'w', encoding='utf-8') as dst:
            dst.write(content)

        print("   ✓ CLAUDE.md customized and placed in .github/claude/")
        return True
    else:
        print("   ⚠️  Source CLAUDE.md template not found")
        return False

def copy_claude_md():
    """Copy CLAUDE.md from docs/ directory (legacy function - deprecated)."""
    # This function is deprecated since docs/CLAUDE.md was moved to .github/claude/CLAUDE.md
    # No output needed to avoid user confusion
    pass

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
    project_name = "{{ cookiecutter.project_name }}"
    project_slug = "{{ cookiecutter.project_slug }}"
    build_system = "{{ cookiecutter.build_system }}"
    use_ninja = "{{ cookiecutter.use_ninja }}"

    print("\n" + "="*60)
    print("✅ Project created!")
    print("="*60)
    print(f"\n📁 Project: {project_name}")
    print(f"🔨 Build: {build_system}")

    print("\n🚀 Quick Start - Validate Your Environment:")
    print("   bash setup-scripts/linux/validation/run-validation.sh")

    print("\n📋 Next Steps:")
    print(f"1. cd {project_slug}")

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
    print("   • Comprehensive: bash setup-scripts/total_run.sh --validate-only (requires sudo)")
    print("   • Final: bash setup-scripts/total_run.sh --final-validation (requires sudo)")

    print("\n✅ Pre-commit hooks are installed and ready to use!")
    print("\n🔗 Create GitHub repository and push:")
    print("   1. Create a new repository on GitHub")
    print("   2. git remote add origin <your-github-repo-url>")
    print("   3. git push -u origin main")

    print("\n📋 Environment Setup:")
    print("⚠️  Note: Full development environment setup requires sudo privileges")
    print("   Run: sudo bash setup-scripts/total_run.sh")

def main():
    try:
        # Setup Claude AI context with template variables
        setup_claude_context()

        # Copy the main CLAUDE.md from template docs (legacy)
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
