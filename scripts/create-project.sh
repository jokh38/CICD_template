#!/bin/bash
# Project creation wrapper for Cookiecutter

set -e

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_UTILS="$SCRIPT_DIR/lib/common-utils.sh"

if [ -f "$COMMON_UTILS" ]; then
    source "$COMMON_UTILS"
else
    echo "Error: Cannot find common-utils.sh at $COMMON_UTILS"
    exit 1
fi

TEMPLATES_DIR="$SCRIPT_DIR/../cookiecutters"

usage() {
    cat <<EOF
Usage: $0 <language> [project-name] [--github]

Languages:
  python    - Python project template
  cpp       - C++ project template

Arguments:
  language       Language template to use (python/cpp)
  project-name   Optional project name or absolute path (e.g., /home/user/my-project)
  --github       Optional flag to create GitHub repository automatically

Examples:
  $0 python my-awesome-project
  $0 python /home/user/my-awesome-project --github
  $0 cpp my-fast-library --github

Note: If --github flag is used, you must have gh CLI installed and authenticated.
Install gh CLI: https://cli.github.com/

EOF
    exit 1
}

check_dependencies() {
    local deps=("cookiecutter" "git")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "$dep not found"
            echo "Install with: pip install cookiecutter"
            exit 1
        fi
    done

    # Check for gh CLI (optional)
    if ! command -v "gh" &> /dev/null; then
        print_warning "gh CLI not found. Install it to auto-create GitHub repositories: https://cli.github.com/"
        GH_AVAILABLE=false
    else
        GH_AVAILABLE=true
    fi
}

create_project() {
    local language=$1
    local project_name=$2
    local create_repo=${3:-false}

    local template_dir="$TEMPLATES_DIR/${language}-project"

    if [ ! -d "$template_dir" ]; then
        print_error "Template not found for $language"
        exit 1
    fi

    print_success "Creating $language project..."

    if [ -n "$project_name" ]; then
        # Expand tilde and extract just the directory name from full path for project_name
        local expanded_path="${project_name/#\~/$HOME}"
        local basename_project=$(basename "$expanded_path")
        local output_dir=$(dirname "$expanded_path")

        # Create output directory if it doesn't exist
        mkdir -p "$output_dir"

        # Generate the package name that cookiecutter will use for the directory name
        # cookiecutter uses package_name which converts spaces to underscores
        local package_name=$(echo "$basename_project" | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g; s/-/_/g')
        local actual_project_dir="$output_dir/$package_name"

        print_status "Expected project directory: $actual_project_dir"
        cookiecutter "$template_dir" --no-input project_name="$basename_project" -o "$output_dir"

        # Find the actual directory that was created
        if [ -d "$actual_project_dir" ]; then
            local project_dir="$actual_project_dir"
            print_success "Found expected project directory: $project_dir"
        else
            print_warning "Expected directory not found, searching for created project..."
            # Fallback: find the most recently created directory in output_dir
            local project_dir=$(find "$output_dir" -maxdepth 1 -type d -mmin -2 -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2-)
            print_success "Found project directory: $project_dir"
        fi
    else
        cookiecutter "$template_dir"
        # Get the created project directory from cookiecutter output
        print_warning "Enter the project directory that was created:"
        read -p "Project path: " project_dir
    fi

    # Change to the project directory for GitHub operations
    cd "$project_dir"


    # GitHub repository creation
    if [ "$create_repo" = true ] && [ "$GH_AVAILABLE" = true ]; then
        create_github_repo "$(basename "$project_dir")"
    elif [ "$create_repo" = true ]; then
        print_warning "GitHub repository creation skipped (gh CLI not available)"
        echo "Install gh CLI: https://cli.github.com/"
    fi

    # Find the absolute path to setup-scripts directory
    local setup_scripts_path=""
    local current_dir="$project_dir"

    # Search up the directory tree to find setup-scripts
    while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/setup-scripts" ]; then
            setup_scripts_path="$current_dir/setup-scripts"
            break
        fi
        current_dir="$(dirname "$current_dir")"
    done

    # If not found by searching, try to find it relative to the script location
    if [ -z "$setup_scripts_path" ]; then
        local script_dir_setup="$(dirname "$SCRIPT_DIR")/setup-scripts"
        if [ -d "$script_dir_setup" ]; then
            setup_scripts_path="$script_dir_setup"
        fi
    fi

    # Find the scripts directory path
    local scripts_path=""
    local current_search_dir="$SCRIPT_DIR"

    # The scripts directory should be in the same parent as this script
    if [ -d "$SCRIPT_DIR/linux" ]; then
        scripts_path="$SCRIPT_DIR"
    elif [ -d "$(dirname "$SCRIPT_DIR")/scripts" ]; then
        scripts_path="$(dirname "$SCRIPT_DIR")/scripts"
    fi

    echo ""
    print_warning "Project created successfully!"
    echo ""
    print_status "Next: Install development tools"

    if [ -n "$scripts_path" ] && [ -f "$scripts_path/linux/tools/install-python-tools.sh" ]; then
        print_warning "Installing development tools for this project..."

        # Determine project type
        local install_type=""
        if [ -f "$project_dir/pyproject.toml" ] || [ -f "$project_dir/requirements.txt" ]; then
            install_type="python"
        elif [ -f "$project_dir/CMakeLists.txt" ]; then
            install_type="cpp"
        fi

        # Run installation based on project type
        if [ "$install_type" = "python" ]; then
            print_success "Detected Python project - installing Python tools..."
            if [ "$EUID" -eq 0 ]; then
                bash "$scripts_path/linux/tools/install-python-tools.sh"
                bash "$scripts_path/linux/config/setup-git-config.sh"
                bash "$scripts_path/linux/config/setup-code-formatting.sh"
                bash "$scripts_path/linux/config/setup-ai-workflows.sh"
            else
                print_warning "Note: Some tools may require sudo privileges"
                sudo bash "$scripts_path/linux/tools/install-python-tools.sh" || print_error "Failed to install Python tools"
                bash "$scripts_path/linux/config/setup-git-config.sh" || print_error "Failed to setup git config"
                bash "$scripts_path/linux/config/setup-code-formatting.sh" || print_error "Failed to setup code formatting"
                bash "$scripts_path/linux/config/setup-ai-workflows.sh" || print_error "Failed to setup AI workflows"
            fi
        elif [ "$install_type" = "cpp" ]; then
            print_success "Detected C++ project - installing C++ tools..."
            if [ "$EUID" -eq 0 ]; then
                bash "$scripts_path/linux/core/install-system-deps.sh"
                bash "$scripts_path/linux/tools/install-compilers.sh"
                bash "$scripts_path/linux/tools/install-build-tools.sh"
                bash "$scripts_path/linux/tools/install-sccache.sh"
                bash "$scripts_path/linux/tools/install-cpp-frameworks.sh"
                bash "$scripts_path/linux/tools/install-cpp-pkg-managers.sh"
                bash "$scripts_path/linux/config/setup-git-config.sh"
                bash "$scripts_path/linux/config/setup-code-formatting.sh"
                bash "$scripts_path/linux/config/setup-ai-workflows.sh"
            else
                print_warning "Note: C++ tools installation requires sudo privileges"
                sudo bash "$scripts_path/linux/core/install-system-deps.sh" || print_error "Failed to install system deps"
                sudo bash "$scripts_path/linux/tools/install-compilers.sh" || print_error "Failed to install compilers"
                sudo bash "$scripts_path/linux/tools/install-build-tools.sh" || print_error "Failed to install build tools"
                sudo bash "$scripts_path/linux/tools/install-sccache.sh" || print_error "Failed to install sccache"
                sudo bash "$scripts_path/linux/tools/install-cpp-frameworks.sh" || print_error "Failed to install C++ frameworks"
                sudo bash "$scripts_path/linux/tools/install-cpp-pkg-managers.sh" || print_error "Failed to install C++ package managers"
                bash "$scripts_path/linux/config/setup-git-config.sh" || print_error "Failed to setup git config"
                bash "$scripts_path/linux/config/setup-code-formatting.sh" || print_error "Failed to setup code formatting"
                bash "$scripts_path/linux/config/setup-ai-workflows.sh" || print_error "Failed to setup AI workflows"
            fi
        fi

        echo ""
        print_success "Development tools installed!"
        echo ""
        print_warning "Next Steps:"
        echo "  1. Navigate to your project: cd $project_dir"
        echo "  2. Validate installation: bash $scripts_path/total_validation.sh"
        echo "  3. Start developing!"
        echo "  4. Check .github/claude/CLAUDE.md for AI assistant integration"
    else
        echo ""
        print_warning "Next Steps:"
        echo "  1. Navigate to your project directory: cd $project_dir"
        echo "  2. Install development tools manually"
        echo "  3. Check .github/claude/CLAUDE.md for AI assistant integration details"
        print_error "Warning: Could not locate scripts directory automatically"
    fi
}

create_github_repo() {
    local repo_name=$1
    print_status "Creating GitHub repository '$repo_name'..."

    if gh repo create "$repo_name" --public --source=. --remote=origin --push; then
        print_success "GitHub repository created and pushed successfully!"
        print_warning "Repository URL: https://github.com/$(gh api user --jq '.login')/$repo_name"
    else
        print_error "Failed to create GitHub repository"
        print_warning "You can create it manually:"
        echo "  1. Go to https://github.com/new"
        echo "  2. Create repository named '$repo_name'"
        echo "  3. Add remote and push:"
        echo "     git remote add origin https://github.com/YOUR-USERNAME/$repo_name.git"
        echo "     git push -u origin main"
    fi
}

main() {
    if [ $# -lt 1 ]; then
        usage
    fi

    # Handle help flags
    case $1 in
        -h|--help)
            usage
            ;;
    esac

    check_dependencies

    local language="$1"
    local project_name=""
    local create_repo=false

    # Parse arguments
    shift
    while [ $# -gt 0 ]; do
        case $1 in
            --github)
                create_repo=true
                shift
                ;;
            *)
                if [ -z "$project_name" ]; then
                    project_name="$1"
                else
                    print_error "Unexpected argument '$1'"
                    usage
                fi
                shift
                ;;
        esac
    done

    create_project "$language" "$project_name" "$create_repo"
}

main "$@"
