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

def process_workflow_files():
    """Process GitHub workflow files to handle GitHub Actions syntax conflicts."""
    print("• Processing GitHub workflow files...")

    workflows_dir = ".github/workflows"
    if not os.path.exists(workflows_dir):
        print("   • No workflows directory found")
        return True

    import re
    processed_files = []

    try:
        for root, dirs, files in os.walk(workflows_dir):
            for file in files:
                if file.endswith(('.yaml', '.yml')):
                    workflow_file = os.path.join(root, file)

                    # Read the workflow file
                    with open(workflow_file, 'r', encoding='utf-8') as f:
                        content = f.read()

                    # Fix GitHub Actions expressions that were escaped for Jinja2
                    # Convert {{'{{'}} ... {{'}}'}} back to ${{ ... }}
                    # Do this replacement in multiple steps to avoid regex complexity
                    content = content.replace("{{'{{'}}", "${{")
                    content = content.replace("{{'}}'}}", "}}")

                    # Also handle any other escaped expressions
                    content = content.replace("{{'{{' ", "${{")
                    content = content.replace(" {{'}}'}}", " }}")

                    # Handle any remaining cookiecutter variables
                    content = content.replace('{{cookiecutter.cpp_standard}}', '{{ cookiecutter.cpp_standard }}')
                    content = content.replace('{{cookiecutter.build_system}}', '{{ cookiecutter.build_system }}')
                    content = content.replace('{{cookiecutter.use_ninja}}', '{{ cookiecutter.use_ninja }}')
                    content = content.replace('{{cookiecutter.project_name}}', '{{ cookiecutter.project_name }}')
                    content = content.replace('{{cookiecutter.testing_framework}}', '{{ cookiecutter.testing_framework }}')

                    # Write the processed file back
                    with open(workflow_file, 'w', encoding='utf-8') as f:
                        f.write(content)

                    processed_files.append(workflow_file)

        print("   • Processed {} workflow files".format(len(processed_files)))
        return True

    except Exception as e:
        print("   ❌ Error processing workflow files: {}".format(e))
        return False

def setup_claude_context():
    """Copy entire .github/claude/ directory and customize CLAUDE.md for new projects."""
    print("• Setting up Claude AI context...")

    # Ensure .github/claude directory exists
    claude_dir = ".github/claude"
    os.makedirs(claude_dir, exist_ok=True)

    # Define source directory paths - use multiple possible paths
    possible_source_dirs = [
        # Try relative path from current directory (most reliable)
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
        print("   Tried paths: {}".format(possible_source_dirs))
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

        print("   • Copied {} AI workflow files to .github/claude/".format(len(copied_files)))
        print("   • Commands, prompts, and documentation ready")
        return True

    except Exception as e:
        print("   ❌ Error copying .github/claude/ directory: {}".format(e))
        return False

def customize_claude_md(claude_md_path):
    """Customize CLAUDE.md file with project-specific values."""
    try:
        # Read the file
        with open(claude_md_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Replace cookiecutter variables with actual project values
        # These should be already replaced by cookiecutter, but handle any remaining ones
        replacements = {
            '{{cookiecutter.project_name}}': '{{ cookiecutter.project_name }}',
            '{{cookiecutter.project_description}}': '{{ cookiecutter.project_description }}',
            '{{cookiecutter.cpp_standard}}': '{{ cookiecutter.cpp_standard }}',
            '{{cookiecutter.build_system}}': '{{ cookiecutter.build_system }}',
            '{{cookiecutter.testing_framework}}': '{{ cookiecutter.testing_framework }}',
            '{{cookiecutter.use_ninja}}': '{{ cookiecutter.use_ninja }}',
        }

        for template_var, actual_value in replacements.items():
            content = content.replace(template_var, actual_value)

        # Write the customized file
        with open(claude_md_path, 'w', encoding='utf-8') as f:
            f.write(content)

        return True

    except Exception as e:
        print("   ⚠️  Error customizing CLAUDE.md: {}".format(e))
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
        print("   Tried paths: {}".format(possible_source_paths))
        return False

    try:
        # Copy HIVE_CLAUDE.md as CLAUDE.md to project root
        shutil.copy2(source_hive_claude, "CLAUDE.md")
        print("   • CLAUDE.md copied to project root")
        return True
    except Exception as e:
        print("   ❌ Error copying HIVE_CLAUDE.md: {}".format(e))
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

def install_git_hooks():
    """Install Git hooks instead of pre-commit."""
    print("• Installing Git hooks...")

    use_git_hooks = "{{ cookiecutter.use_git_hooks }}"

    if use_git_hooks == "no":
        print("   ⚠️  Git hooks disabled by configuration")
        return False

    # Create .git/hooks directory if it doesn't exist
    os.makedirs(".git/hooks", exist_ok=True)

    # Define possible source paths for git hooks
    possible_source_paths = [
        os.path.join(os.getcwd(), "..", "..", "git-hooks"),
        os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "git-hooks"),
        "/home/jokh38/apps/CICD_template/git-hooks"
    ]

    source_hooks_dir = None
    for path in possible_source_paths:
        if os.path.exists(path):
            source_hooks_dir = path
            break

    if not source_hooks_dir:
        print("   ⚠️  Source git hooks directory not found")
        return False

    import shutil

    # Copy prepare-commit-msg hook
    prepare_commit_msg_src = os.path.join(source_hooks_dir, "prepare-commit-msg")
    prepare_commit_msg_dst = ".git/hooks/prepare-commit-msg"
    if os.path.exists(prepare_commit_msg_src):
        shutil.copy2(prepare_commit_msg_src, prepare_commit_msg_dst)
        os.chmod(prepare_commit_msg_dst, 0o755)
        print("   • prepare-commit-msg hook installed")
    else:
        print("   ⚠️  prepare-commit-msg hook not found")

    # Copy pre-commit hook
    pre_commit_src = os.path.join(source_hooks_dir, "pre-commit")
    pre_commit_dst = ".git/hooks/pre-commit"
    if os.path.exists(pre_commit_src):
        shutil.copy2(pre_commit_src, pre_commit_dst)
        os.chmod(pre_commit_dst, 0o755)
        print("   • pre-commit hook installed")
    else:
        print("   ⚠️  pre-commit hook not found")

    return True

def setup_build_directory():
    print("• Creating build directory...")
    os.makedirs("build", exist_ok=True)

def print_next_steps():
    project_name = "{{ cookiecutter.project_name }}"
    project_slug = "{{ cookiecutter.project_slug }}"
    build_system = "{{ cookiecutter.build_system }}"
    use_ninja = "{{ cookiecutter.use_ninja }}"
    use_git_hooks = "{{ cookiecutter.use_git_hooks }}"
    use_ai = "{{ cookiecutter.use_ai_workflow }}"

    print("\n" + "="*60)
    print("✅ Project created!")
    print("="*60)
    print("\n• Project: {}".format(project_name))
    print("• Build: {}".format(build_system))
    print("• Git Hooks: {}".format(use_git_hooks))
    print("• AI Workflow: {}".format(use_ai))

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

    print("  6. git commit -m 'Initial changes'  # Git hooks will run automatically")

    if use_ai == "yes":
        print("  7. Review .github/claude/CLAUDE.md for AI assistant")

    print("\n• Environment Setup:")
    print("  Note: Install required development tools:")
    print("  - C++ compiler (g++ or clang++)")
    print("  - CMake or Meson")
    print("  - clang-format, clang-tidy")

    if use_git_hooks == "yes":
        print("• Git hooks are installed and will run automatically on commit")
    else:
        print("• Git hooks are disabled - manual quality checks required")

    print("\n• Create GitHub repository and push:")
    print("  1. Create a new repository on GitHub")
    print("  2. git remote add origin <your-github-repo-url>")
    print("  3. git push -u origin main")

def main():
    try:
        # Setup Claude AI context with template variables
        setup_claude_context()

        # Copy HIVE_CLAUDE.md as CLAUDE.md to project root
        copy_claude_md()

        initialize_git()
        install_git_hooks()
        setup_build_directory()

        # Cleanup
        if "{{ cookiecutter.use_ai_workflow }}" == "no":
            # Only remove AI workflow files, keep docs/CLAUDE.md for general use
            if os.path.exists(".github/claude"):
                import shutil
                shutil.rmtree(".github/claude")
                run_command("git add .github/claude")

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
        print("\n❌ Error: {}".format(e))
        sys.exit(1)

if __name__ == "__main__":
    main()
