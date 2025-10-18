#!/bin/bash
# Run Validation Tests

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARNING]${NC} $1"
}

# Parse command line arguments
CPP_ONLY=false
PYTHON_ONLY=false
SYSTEM_ONLY=false
CLEANUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --cpp-only)
            CPP_ONLY=true
            shift
            ;;
        --python-only)
            PYTHON_ONLY=true
            shift
            ;;
        --system-only)
            SYSTEM_ONLY=true
            shift
            ;;
        --cleanup)
            CLEANUP=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Cleanup function
if [ "$CLEANUP" = "true" ]; then
    print_status "Cleaning up test projects..."
    rm -rf /tmp/test-projects-*
    print_success "Cleanup completed"
    exit 0
fi

# Validation counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run validation test
run_test() {
    local test_name="$1"
    local test_command="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_status "Running test: $test_name"

    if eval "$test_command" > /dev/null 2>&1; then
        print_success "✓ $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        print_error "✗ $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_status "Starting validation tests..."

# System dependency validation
if [ "$PYTHON_ONLY" != "true" ] && [ "$CPP_ONLY" != "true" ]; then
    print_status "Validating system dependencies..."

    run_test "Git installation" "command_exists git"
    run_test "CMake installation" "command_exists cmake"
    run_test "Ninja installation" "command_exists ninja"
    run_test "Make installation" "command_exists make"
    run_test "Python3 installation" "command_exists python3"
    run_test "Pip installation" "command_exists pip3"

    # Compiler validation
    run_test "GCC installation" "command_exists gcc"
    run_test "G++ installation" "command_exists g++"
    run_test "Clang installation" "command_exists clang"
    run_test "Clang++ installation" "command_exists clang++"
fi

# C++ tool validation
if [ "$PYTHON_ONLY" != "true" ] && [ "$SYSTEM_ONLY" != "true" ]; then
    print_status "Validating C++ development tools..."

    run_test "sccache installation" "command_exists sccache"
    run_test "clang-format installation" "command_exists clang-format"
    run_test "clang-tidy installation" "command_exists clang-tidy"
    run_test "Conan installation" "command_exists conan"
    run_test "vcpkg installation" "command_exists vcpkg"

    # Test C++ compilation
    run_test "GCC compilation test" "echo 'int main(){return 0;}' | gcc -x c++ - -o \$HOME/test_gcc"
    run_test "Clang compilation test" "echo 'int main(){return 0;}' | clang++ -stdlib=libc++ -x c++ - -o \$HOME/test_clang"

    # Cleanup test files
    rm -f $HOME/test_gcc $HOME/test_clang
elif [ "$PYTHON_ONLY" = "true" ]; then
    print_status "Skipping C++ development tools validation (Python only mode)"
fi

# Python tool validation
if [ "$CPP_ONLY" != "true" ] && [ "$SYSTEM_ONLY" != "true" ]; then
    print_status "Validating Python development tools..."

    # Check Python packages
    run_test "ruff installation" "python3 -c 'import ruff'"
    run_test "black installation" "python3 -c 'import black'"
    run_test "pytest installation" "python3 -c 'import pytest'"
    run_test "mypy installation" "python3 -c 'import mypy'"
    run_test "bandit installation" "python3 -c 'import bandit'"
    run_test "pre-commit installation" "python3 -c 'import pre_commit'"
elif [ "$CPP_ONLY" = "true" ]; then
    print_status "Skipping Python development tools validation (C++ only mode)"
fi

# Test projects validation
print_status "Validating test projects..."

# Find the most recent test project directory
TEST_DIR=$(find /tmp -name "test-projects-*" -type d | sort | tail -1)

if [ -z "$TEST_DIR" ]; then
    print_warning "No test projects found. Skipping project validation."
else
    print_status "Found test projects in: $TEST_DIR"

    # Determine which test projects exist and should be validated
    CPP_PROJECT_EXISTS=false
    PYTHON_PROJECT_EXISTS=false

    if [ -d "$TEST_DIR/cpp-test-project" ]; then
        CPP_PROJECT_EXISTS=true
    fi

    if [ -d "$TEST_DIR/python-test-project" ]; then
        PYTHON_PROJECT_EXISTS=true
    fi

    # If no flags specified and only one project type exists, validate that type only
    if [ "$PYTHON_ONLY" != "true" ] && [ "$CPP_ONLY" != "true" ] && [ "$SYSTEM_ONLY" != "true" ]; then
        if [ "$CPP_PROJECT_EXISTS" = "true" ] && [ "$PYTHON_PROJECT_EXISTS" = "false" ]; then
            # Only C++ project exists
            CPP_ONLY=true
        elif [ "$PYTHON_PROJECT_EXISTS" = "true" ] && [ "$CPP_PROJECT_EXISTS" = "false" ]; then
            # Only Python project exists
            PYTHON_ONLY=true
        fi
    fi

    # Validate C++ test project
    if [ "$PYTHON_ONLY" != "true" ] && [ "$CPP_PROJECT_EXISTS" = "true" ]; then
        print_status "Validating C++ test project..."

        cd "$TEST_DIR/cpp-test-project"

        # Configure and build
        run_test "CMake configuration" "cmake -S . -B build -DCMAKE_BUILD_TYPE=Release"
        run_test "CMake build" "cmake --build build --parallel"

        # Run tests
        if [ -f "build/calculator_tests" ]; then
            run_test "C++ test execution" "./build/calculator_tests"
        fi

        # Run application
        if [ -f "build/calculator_app" ]; then
            run_test "C++ application execution" "./build/calculator_app"
        fi
    fi

    # Validate Python test project
    if [ "$CPP_ONLY" != "true" ] && [ "$PYTHON_PROJECT_EXISTS" = "true" ]; then
        print_status "Validating Python test project..."

        cd "$TEST_DIR/python-test-project"

        # Install package in development mode
        run_test "Python package installation" "pip3 install -e ."

        # Run code formatting checks
        run_test "Black format check" "python3 -m black --check src/ tests/"
        run_test "Ruff lint check" "python3 -m ruff check src/ tests/"

        # Run type checking
        run_test "MyPy type check" "python3 -m mypy src/"

        # Run security analysis
        run_test "Bandit security check" "python3 -m bandit -r src/"

        # Run tests
        run_test "Python test execution" "python3 -m pytest tests/ --cov=src --cov-report=term-missing"

        # Run application
        run_test "Python application execution" "python3 src/main.py"
    fi
fi

# Configuration validation
if [ "$SYSTEM_ONLY" != "true" ]; then
    print_status "Validating configurations..."

    # Check Git configuration
    run_test "Git user name configured" "git config --global user.name"
    run_test "Git user email configured" "git config --global user.email"
    run_test "Git global ignore file exists" "test -f ~/.gitignore_global"

    # Check code formatting configurations based on installation type
    if [ "$PYTHON_ONLY" != "true" ]; then
        run_test "Clang-format config exists" "test -f ~/.clang-format"
    fi

    if [ "$CPP_ONLY" != "true" ]; then
        run_test "Ruff config exists" "test -f ~/.config/ruff/ruff.toml"
    fi

    if [ "$PYTHON_ONLY" != "true" ]; then
        run_test "CMake presets config exists" "test -f ~/.config/cmake/CMakePresets.json"
    fi

    # Check AI workflow templates
    run_test "AI workflow templates exist" "test -d ~/.config/ai-workflows"
fi

# Print summary
echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Validation Summary${NC}"
echo -e "${BLUE}================================${NC}"
echo "Total tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    print_success "🎉 All validation tests passed!"
    echo ""
    echo "Development environment is ready for use!"
    exit 0
else
    echo ""
    print_error "❌ Some validation tests failed."
    echo ""
    echo "Please check the failed tests and resolve the issues."
    exit 1
fi