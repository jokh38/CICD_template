#!/bin/bash
# Complete Development Environment Setup Orchestration Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINUX_DIR="$SCRIPT_DIR/linux"
DEVELOPER_USER="developer"

# Function to print colored output (with timestamps for consistency)
print_status() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root"
        exit 1
    fi
}

# Function to detect project type from current directory or recent projects
detect_project_type() {
    local detected_type=""

    # Check if we're in a project directory
    if [ -n "$PWD" ] && [ "$PWD" != "/" ]; then
        # Check for Python project indicators
        if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ] || ([ -d "src/" ] && [ -d "tests/" ] && [ -d ".venv" ]); then
            detected_type="python"
            echo "Detected Python project in current directory" >&2
        # Check for C++ project indicators
        elif [ -f "CMakeLists.txt" ] || [ -f "Makefile" ] || [ -f "configure.ac" ] || ([ -d "src/" ] && (ls src/*.cpp src/*.hpp >/dev/null 2>&1)); then
            detected_type="cpp"
            echo "Detected C++ project in current directory" >&2
        fi
    fi

    # If no project detected in current directory, check for recently created projects
    if [ -z "$detected_type" ]; then
        # Look for recent project directories in user's home or common locations
        local recent_projects=$(find /home -maxdepth 3 -name "pyproject.toml" -o -name "CMakeLists.txt" 2>/dev/null | head -5)

        if echo "$recent_projects" | grep -q "pyproject.toml"; then
            detected_type="python"
            echo "Detected recent Python projects" >&2
        elif echo "$recent_projects" | grep -q "CMakeLists.txt"; then
            detected_type="cpp"
            echo "Detected recent C++ projects" >&2
        fi
    fi

    echo "$detected_type"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Complete development environment setup for local development with git hooks

OPTIONS:
    --help, -h              Show this help message
    --basic                 Install only basic tools (system deps, compilers, build tools)
    --cpp-only              Install only C++ development tools
    --python-only           Install only Python development tools
    --no-validation         Skip validation tests
    --validate-only         Run validation tests only
    --final-validation      Run final comprehensive validation only
    --cleanup               Clean up test projects
    --dry-run               Show what would be executed without running

EXAMPLES:
    $0                      # Full installation with validation
    $0 --basic              # Basic tools only
    $0 --cpp-only           # C++ tools only
    $0 --python-only        # Python tools only
    $0 --validate-only      # Run validation tests
    $0 --final-validation   # Run final comprehensive validation only
    $0 --cleanup            # Clean up test projects

EOF
}

# Function to run a script with error handling and output suppression
run_script() {
    local script_path="$1"
    local description="$2"
    shift 2
    local script_args=("$@")

    if [ ! -f "$script_path" ]; then
        print_error "Script not found: $script_path"
        return 1
    fi

    print_status "Running: $description"

    if [ "$DRY_RUN" = "true" ]; then
        print_status "[DRY RUN] Would execute: $script_path ${script_args[*]}"
        return 0
    fi

    # Run script with suppressed output, only show success/failure
    if bash "$script_path" "${script_args[@]}" > /dev/null 2>&1; then
        print_success "✓ $description"
        return 0
    else
        print_error "✗ $description"
        return 1
    fi
}

# Function to install basic tools
install_basic_tools() {
    print_status "Installing basic development tools..."

    run_script "$LINUX_DIR/core/install-system-deps.sh" "System Dependencies"
    run_script "$LINUX_DIR/tools/install-build-tools.sh" "Build Tools"
}

# Function to install C++ tools
install_cpp_tools() {
    print_status "Installing C++ development tools..."

    run_script "$LINUX_DIR/tools/install-compilers.sh" "Compiler Tools"
    run_script "$LINUX_DIR/tools/install-sccache.sh" "sccache"
    run_script "$LINUX_DIR/tools/install-cpp-frameworks.sh" "C++ Testing Frameworks"
    run_script "$LINUX_DIR/tools/install-cpp-pkg-managers.sh" "C++ Package Managers"
    run_script "$LINUX_DIR/config/setup-code-formatting.sh" "C++ Code Formatting"
}

# Function to install Python tools
install_python_tools() {
    print_status "Installing Python development tools..."

    run_script "$LINUX_DIR/tools/install-python-tools.sh" "Python Development Tools"
}

# Function to setup configurations
setup_configurations() {
    print_status "Setting up configurations..."

    run_script "$LINUX_DIR/config/setup-git-config.sh" "Git Configuration"
    run_script "$LINUX_DIR/config/setup-code-formatting.sh" "Code Formatting Configurations"
    run_script "$LINUX_DIR/config/setup-ai-workflows.sh" "AI Workflow Templates"
}

# Function to create test projects
create_test_projects() {
    if [ "$VALIDATE" = "true" ]; then
        print_status "Creating test projects..."

        if [ "$INSTALL_CPP" = "true" ] || [ "$INSTALL_ALL" = "true" ]; then
            run_script "$LINUX_DIR/validation/create-test-projects.sh" "C++ Test Project" --cpp-only
        fi

        if [ "$INSTALL_PYTHON" = "true" ] || [ "$INSTALL_ALL" = "true" ]; then
            run_script "$LINUX_DIR/validation/create-test-projects.sh" "Python Test Project" --python-only
        fi
    fi
}

# Function to run validation
run_validation() {
    if [ "$VALIDATE" = "true" ]; then
        print_status "Running validation tests..."

        local validation_args=""
        if [ "$INSTALL_CPP" = "true" ] && [ "$INSTALL_PYTHON" = "false" ]; then
            validation_args="--cpp-only"
        elif [ "$INSTALL_PYTHON" = "true" ] && [ "$INSTALL_CPP" = "false" ]; then
            validation_args="--python-only"
        elif [ "$INSTALL_BASIC" = "true" ] && [ "$INSTALL_ALL" = "false" ]; then
            validation_args="--system-only"
        fi

        run_script "$LINUX_DIR/validation/run-validation.sh" "Validation Tests" $validation_args
    fi
}

# Function to run final comprehensive validation
run_final_validation() {
    print_status "Running final comprehensive validation..."

    if [ "$DRY_RUN" = "true" ]; then
        print_status "[DRY RUN] Would run final validation"
        return 0
    fi

    # Determine validation arguments
    local validation_args=""
    if [ "$INSTALL_CPP" = "true" ] && [ "$INSTALL_PYTHON" = "false" ]; then
        validation_args="--cpp-only"
    elif [ "$INSTALL_PYTHON" = "true" ] && [ "$INSTALL_CPP" = "false" ]; then
        validation_args="--python-only"
    elif [ "$INSTALL_BASIC" = "true" ] && [ "$INSTALL_ALL" = "false" ]; then
        validation_args="--system-only"
    fi

    # Run final validation script without output suppression to show detailed results
    if bash "$LINUX_DIR/validation/final-validation.sh" $validation_args; then
        print_success "✅ Final validation completed successfully"
        return 0
    else
        print_error "❌ Final validation failed"
        return 1
    fi
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    run_script "$LINUX_DIR/validation/run-validation.sh" "Cleanup" --cleanup
}

# Function to print summary
print_summary() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✅ Setup Complete!${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""

    echo "Installation Summary:"
    if [ "$INSTALL_BASIC" = "true" ] || [ "$INSTALL_ALL" = "true" ]; then
        echo "  ✓ System dependencies"
        echo "  ✓ Compiler tools (GCC, Clang)"
        echo "  ✓ Build tools (CMake, Ninja)"
    fi

    if [ "$INSTALL_CPP" = "true" ] || [ "$INSTALL_ALL" = "true" ]; then
        echo "  ✓ C++ tools (sccache, testing frameworks)"
        echo "  ✓ C++ formatting configurations"
    fi

    if [ "$INSTALL_PYTHON" = "true" ] || [ "$INSTALL_ALL" = "true" ]; then
        echo "  ✓ Python tools (ruff, pytest, mypy)"
        echo "  ✓ Python formatting configurations"
    fi

    if [ "$INSTALL_ALL" = "true" ] || [ "$INSTALL_CPP" = "true" ] || [ "$INSTALL_PYTHON" = "true" ]; then
        echo "  ✓ AI workflow templates"
    fi

    echo ""
    echo "Next Steps:"
    echo "  1. Log out and log back in to apply environment changes"
    echo "  2. Set up git hooks: ln -s ../../git-hooks/pre-commit .git/hooks/ && ln -s ../../git-hooks/prepare-commit-msg .git/hooks/"
    echo "  3. Test the installation with your projects"
    echo "  4. Use the provided aliases for common tasks"
    echo "  5. Git is configured and ready for use with automated hooks"
    echo "  🔴 IMPORTANT: Never use 'git commit --no-verify' - it bypasses all quality checks!"
    echo ""
    echo "Configuration files created in:"
    echo "  - ~/.gitconfig (Git configuration)"
    echo "  - ~/.gitignore_global (Global gitignore)"
    echo "  - ~/.config/git/commit.template (Commit template)"
    echo "  - ~/.clang-format, ~/.clang-tidy (C++)"
    echo "  - ~/.config/ruff/ruff.toml (Python)"
    echo "  - ~/.config/cmake/CMakePresets.json"
    echo "  - ~/.config/sccache/config"
    echo ""
    echo "Git user configured: Kwanghyun Jo <jokh38@gmail.com>"
    echo ""
}

# Main execution function
main() {
    local INSTALL_ALL="true"
    local INSTALL_BASIC="false"
    local INSTALL_CPP="false"
    local INSTALL_PYTHON="false"
    local VALIDATE="true"
    local DRY_RUN="false"

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_usage
                exit 0
                ;;
            --basic)
                INSTALL_ALL="false"
                INSTALL_BASIC="true"
                INSTALL_CPP="false"
                INSTALL_PYTHON="false"
                shift
                ;;
            --cpp-only)
                INSTALL_ALL="false"
                INSTALL_BASIC="false"
                INSTALL_CPP="true"
                INSTALL_PYTHON="false"
                shift
                ;;
            --python-only)
                INSTALL_ALL="false"
                INSTALL_BASIC="false"
                INSTALL_CPP="false"
                INSTALL_PYTHON="true"
                shift
                ;;
            --no-validation)
                VALIDATE="false"
                shift
                ;;
            --validate-only)
                INSTALL_ALL="false"
                INSTALL_BASIC="false"
                INSTALL_CPP="false"
                INSTALL_PYTHON="false"
                VALIDATE="true"
                shift
                ;;
            --final-validation)
                INSTALL_ALL="false"
                INSTALL_BASIC="false"
                INSTALL_CPP="false"
                INSTALL_PYTHON="false"
                VALIDATE="false"
                run_final_validation
                exit $?
                ;;
            --cleanup)
                cleanup
                exit 0
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Auto-detect project type if no specific installation flags are set
    if [ "$INSTALL_ALL" = "true" ] && [ "$INSTALL_BASIC" = "false" ] && [ "$INSTALL_CPP" = "false" ] && [ "$INSTALL_PYTHON" = "false" ]; then
        local detected_project=$(detect_project_type 2>/dev/null)
        if [ "$detected_project" = "python" ]; then
            print_status "Auto-detected Python environment - installing Python tools only"
            INSTALL_ALL="false"
            INSTALL_PYTHON="true"
        elif [ "$detected_project" = "cpp" ]; then
            print_status "Auto-detected C++ environment - installing C++ tools only"
            INSTALL_ALL="false"
            INSTALL_CPP="true"
        else
            print_status "No specific project type detected - installing all development tools"
        fi
    fi

    print_status "Starting development environment setup..."
    print_status "Script directory: $SCRIPT_DIR"
    print_status "Linux directory: $LINUX_DIR"

    if [ "$DRY_RUN" = "true" ]; then
        print_status "Running in DRY RUN mode - no actual changes will be made"
    fi

    # Check prerequisites
    if [ "$DRY_RUN" != "true" ]; then
        check_root
    fi

    # Validate directory structure
    if [ ! -d "$LINUX_DIR" ]; then
        print_error "Linux directory not found: $LINUX_DIR"
        exit 1
    fi

    # Execute installation steps
    trap cleanup EXIT

    if [ "$VALIDATE" != "true" ] || [ "$INSTALL_ALL" = "true" ] || [ "$INSTALL_BASIC" = "true" ] || [ "$INSTALL_CPP" = "true" ] || [ "$INSTALL_PYTHON" = "true" ]; then
        if [ "$INSTALL_BASIC" = "true" ] || [ "$INSTALL_ALL" = "true" ]; then
            install_basic_tools
        fi

        if [ "$INSTALL_CPP" = "true" ] || [ "$INSTALL_ALL" = "true" ]; then
            install_cpp_tools
        fi

        if [ "$INSTALL_PYTHON" = "true" ] || [ "$INSTALL_ALL" = "true" ]; then
            install_python_tools
        fi

        if [ "$INSTALL_ALL" = "true" ] || [ "$INSTALL_CPP" = "true" ] || [ "$INSTALL_PYTHON" = "true" ]; then
            setup_configurations
        fi

        create_test_projects
    fi

    run_validation

    # Run final comprehensive validation if not in dry-run mode
    if [ "$DRY_RUN" != "true" ]; then
        run_final_validation
    fi

    # Remove the cleanup trap if we reached here successfully
    trap - EXIT

    if [ "$DRY_RUN" != "true" ]; then
        print_summary
    else
        print_status "DRY RUN completed successfully"
        print_status "Run without --dry-run to execute the installation"
    fi
}

# Execute main function with all arguments
main "$@"