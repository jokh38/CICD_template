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

def install_serena_mcp():
    """Install Serena MCP server for Claude Code."""
    print("• Setting up Serena MCP integration...")

    use_ai = "{{ cookiecutter.use_ai_workflow }}"

    if use_ai != "yes":
        print("   ⚠️  AI workflow disabled - skipping Serena MCP setup")
        return False

    # Check if Claude Code CLI is available
    if not run_command("which claude", check=False):
        print("   ⚠️  Claude Code CLI not found - skipping Serena MCP setup")
        print("   To install Claude Code: https://claude.ai/cli")
        return False

    # Check if Serena MCP is already installed
    if run_command("claude mcp list | grep serena", check=False):
        print("   • Serena MCP already installed")
        return True

    # Install Serena MCP
    print("   • Installing Serena MCP server...")
    install_cmd = 'claude mcp add-json "serena" \'{"command":"uvx","args":["--from","git+https://github.com/oraios/serena","serena-mcp-server"]}\''

    if run_command(install_cmd, check=False):
        print("   • Serena MCP installed successfully")

        # Verify installation
        if run_command("claude mcp list", check=False):
            print("   • MCP servers listed successfully")

        return True
    else:
        print("   ⚠️  Failed to install Serena MCP")
        print("   You can install manually later:")
        print("   claude mcp add-json \"serena\" '{\"command\":\"uvx\",\"args\":[\"--from\",\"git+https://github.com/oraios/serena\",\"serena-mcp-server\"]}'")
        return False

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

    if use_ai == "yes":
        print("  6. Review .github/claude/CLAUDE.md for AI assistant")
        print("  7. claude mcp list  # Verify Serena MCP installation")

    if use_git_hooks == "yes":
        print("\n• Pre-commit hooks are installed and will run automatically on commit")
        print("• Run 'pre-commit run --all-files' to check all files manually")
        print("• 🔴 IMPORTANT: Never use 'git commit --no-verify' - it bypasses quality checks!")
    else:
        print("\n• Pre-commit hooks are disabled - manual quality checks required")

    if use_ai == "yes":
        print("• Serena MCP integration is configured for enhanced AI capabilities")

    print("\n• Create GitHub repository and push:")
    print("  1. Create a new repository on GitHub")
    print("  2. git remote add origin <your-github-repo-url>")
    print("  3. git push -u origin main")

def setup_claude_context():
    """Copy entire .github/claude/ directory and customize CLAUDE.md for new projects."""
    print("• Setting up Claude AI context...")

    use_ai = "{{ cookiecutter.use_ai_workflow }}"

    if use_ai != "yes":
        print("   ⚠️  AI workflow disabled - skipping Claude context setup")
        return False

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
        content = content.replace(
            '{% if cookiecutter.python_version is defined %}Python {{cookiecutter.python_version}}{% else %}C++ {{cookiecutter.cpp_standard}}{% endif %}',
            f'C++ {cpp_standard}'
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

def main():
    try:
        # Setup Claude AI context if enabled
        setup_claude_context()
        copy_claude_md()

        initialize_git()
        setup_build_directory()
        install_pre_commit()
        install_serena_mcp()
        print_next_steps()
    except Exception as e:
        print("\n❌ Error: {}".format(e))
        sys.exit(1)

if __name__ == "__main__":
    main()