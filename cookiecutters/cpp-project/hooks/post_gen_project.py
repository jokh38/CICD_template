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

def initialize_git():
    print("📦 Initializing git repository...")
    run_command("git init")
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

    print("\n✅ Pre-commit hooks are installed and ready to use!")
    print("\n🔗 Add remote:")
    print("   git remote add origin <repo-url>\n")

def main():
    try:
        initialize_git()
        install_precommit()
        setup_build_directory()

        # Cleanup
        if "{{ cookiecutter.use_ai_workflow }}" == "no":
            for f in ["CLAUDE.md", ".github/workflows/ai-workflow.yaml"]:
                if os.path.exists(f):
                    os.remove(f)

        if "{{ cookiecutter.license }}" == "None":
            if os.path.exists("LICENSE"):
                os.remove("LICENSE")

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
