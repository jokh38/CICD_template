#!/bin/bash
# Complete Development Environment Validation Script
# This script validates the development environment setup in the current project directory

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINUX_DIR="$SCRIPT_DIR/linux"

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

# Function to detect project type from current directory
detect_project_type() {
    local detected_type=""

    # Check for Python project indicators
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
        detected_type="python"
        print_status "Detected Python project in current directory"
    # Check for C++ project indicators
    elif [ -f "CMakeLists.txt" ] || [ -f "Makefile" ] || [ -f "configure.ac" ]; then
        detected_type="cpp"
        print_status "Detected C++ project in current directory"
    else
        print_warning "No specific project type detected in current directory"
    fi

    echo "$detected_type"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Validate development environment setup in the current project directory

OPTIONS:
    --help, -h              Show this help message
    --cpp-only              Validate only C++ development tools
    --python-only           Validate only Python development tools
    --system-only           Validate only system tools

EXAMPLES:
    $0                      # Auto-detect and validate current project
    $0 --python-only        # Validate Python tools only
    $0 --cpp-only           # Validate C++ tools only

NOTE:
    This script should be run from within a project directory.
    It will validate the tools and setup for that specific project.

EOF
}

# Main execution function
main() {
    local CPP_ONLY="false"
    local PYTHON_ONLY="false"
    local SYSTEM_ONLY="false"
    local AUTO_DETECT="true"

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_usage
                exit 0
                ;;
            --cpp-only)
                AUTO_DETECT="false"
                CPP_ONLY="true"
                PYTHON_ONLY="false"
                SYSTEM_ONLY="false"
                shift
                ;;
            --python-only)
                AUTO_DETECT="false"
                CPP_ONLY="false"
                PYTHON_ONLY="true"
                SYSTEM_ONLY="false"
                shift
                ;;
            --system-only)
                AUTO_DETECT="false"
                CPP_ONLY="false"
                PYTHON_ONLY="false"
                SYSTEM_ONLY="true"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    print_status "Starting development environment validation..."
    print_status "Current directory: $(pwd)"
    print_status "Script directory: $SCRIPT_DIR"

    # Validate directory structure
    if [ ! -d "$LINUX_DIR" ]; then
        print_error "Linux validation directory not found: $LINUX_DIR"
        exit 1
    fi

    # Auto-detect project type if not specified
    if [ "$AUTO_DETECT" = "true" ]; then
        local detected_project=$(detect_project_type)
        if [ "$detected_project" = "python" ]; then
            PYTHON_ONLY="true"
        elif [ "$detected_project" = "cpp" ]; then
            CPP_ONLY="true"
        else
            print_warning "Running full validation (all tools)"
        fi
    fi

    # Determine validation arguments
    local validation_args=""
    if [ "$CPP_ONLY" = "true" ]; then
        validation_args="--cpp-only"
        print_status "Validation mode: C++ only"
    elif [ "$PYTHON_ONLY" = "true" ]; then
        validation_args="--python-only"
        print_status "Validation mode: Python only"
    elif [ "$SYSTEM_ONLY" = "true" ]; then
        validation_args="--system-only"
        print_status "Validation mode: System tools only"
    else
        print_status "Validation mode: Full (all tools)"
    fi

    # Run validation script
    if bash "$LINUX_DIR/validation/final-validation.sh" $validation_args; then
        print_success "✅ Validation completed successfully"
        echo ""
        echo "Your development environment is ready!"
        echo ""
        echo "Next Steps:"
        echo "  1. Start developing in this project directory"
        echo "  2. Use git hooks for automated quality checks"
        echo "  3. Run tests regularly to ensure code quality"
        echo ""
        return 0
    else
        print_error "❌ Validation failed"
        echo ""
        echo "Some validation tests failed. Please check the output above."
        echo ""
        echo "Troubleshooting:"
        echo "  1. Ensure all required tools are installed"
        echo "  2. Check that project files are properly set up"
        echo "  3. Verify that configurations are correct"
        echo "  4. Re-run the create-project script if needed"
        echo ""
        return 1
    fi
}

# Execute main function with all arguments
main "$@"
