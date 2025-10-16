#!/bin/bash
# Final Comprehensive Validation Script
# Tests all installed development tools and provides clean success/failure output

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VALIDATION_PASSED=true
FAILED_TESTS=()

# Function to detect the best Python command to use
detect_python_cmd() {
    if [ -n "$CONDA_DEFAULT_ENV" ]; then
        echo "python"
        return 0
    fi

    if command -v python &> /dev/null; then
        echo "python"
    elif command -v python3 &> /dev/null; then
        echo "python3"
    else
        echo "python3"
    fi
}

# Function to run validation test with expected result
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"

    echo -n "Testing $test_name... "

    # Run test and capture output
    if output=$(eval "$test_command" 2>&1); then
        if [ -n "$expected_pattern" ]; then
            if echo "$output" | grep -q "$expected_pattern"; then
                echo -e "${GREEN}✓ PASS${NC}"
                return 0
            else
                echo -e "${RED}✗ FAIL${NC}"
                echo "  Expected pattern: $expected_pattern"
                echo "  Got: $output"
                FAILED_TESTS+=("$test_name")
                VALIDATION_PASSED=false
                return 1
            fi
        else
            echo -e "${GREEN}✓ PASS${NC}"
            return 0
        fi
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "  Command failed: $test_command"
        FAILED_TESTS+=("$test_name")
        VALIDATION_PASSED=false
        return 1
    fi
}

validate_system_tools() {
    echo -e "${BLUE}=== System Tools Validation ===${NC}"

    # Test compilers
    run_test "GCC compiler" "gcc --version | head -n1" "gcc"
    run_test "G++ compiler" "g++ --version | head -n1" "g\+\+"
    run_test "Clang compiler" "clang --version | head -n1" "clang"
    run_test "Clang++ compiler" "clang++ --version | head -n1" "clang\+\+"

    # Test build tools
    run_test "CMake" "cmake --version | head -n1" "cmake"
    run_test "Ninja" "ninja --version" "[0-9]"

    # Test git
    run_test "Git" "git --version | head -n1" "git"

    echo
}

validate_cpp_tools() {
    echo -e "${BLUE}=== C++ Development Tools Validation ===${NC}"

    # Test sccache
    run_test "sccache" "sccache --version | head -n1" "sccache"

    # Test clang-format
    run_test "clang-format" "clang-format --version | head -n1" "clang-format"

    # Test clang-tidy
    run_test "clang-tidy" "clang-tidy --version" "LLVM"

    # Test C++ test project if it exists
    if [ -d "/tmp/cpp-test-project" ]; then
        echo -n "Testing C++ project build... "
        if (
            cd /tmp/cpp-test-project &&
            cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release > /dev/null 2>&1 &&
            cmake --build build > /dev/null 2>&1
        ); then
            echo -e "${GREEN}✓ PASS${NC}"
        else
            echo -e "${RED}✗ FAIL${NC}"
            FAILED_TESTS+=("C++ project build")
            VALIDATION_PASSED=false
        fi

        echo -n "Testing C++ project tests... "
        if (
            cd /tmp/cpp-test-project &&
            ctest --test-dir build --output-on-failure > /dev/null 2>&1
        ); then
            echo -e "${GREEN}✓ PASS${NC}"
        else
            echo -e "${RED}✗ FAIL${NC}"
            FAILED_TESTS+=("C++ project tests")
            VALIDATION_PASSED=false
        fi
    else
        echo -e "${YELLOW}⚠ C++ test project not found - skipping build tests${NC}"
    fi

    echo
}

validate_python_tools() {
    echo -e "${BLUE}=== Python Development Tools Validation ===${NC}"

    PYTHON_CMD=$(detect_python_cmd)

    # Test Python
    run_test "Python interpreter" "$PYTHON_CMD --version | head -n1" "Python"

    # Test ruff
    run_test "ruff linter" "$PYTHON_CMD -m ruff --version | head -n1" "ruff"
    run_test "ruff formatter" "$PYTHON_CMD -m ruff format --version | head -n1" "ruff"

    # Test pytest
    run_test "pytest" "$PYTHON_CMD -m pytest --version | head -n1" "pytest"

    # Test mypy
    run_test "mypy" "$PYTHON_CMD -m mypy --version | head -n1" "mypy"

    # Test Python test project if it exists
    if [ -d "/tmp/python-test-project" ]; then
        echo -n "Testing Python project linting... "
        if (
            cd /tmp/python-test-project &&
            $PYTHON_CMD -m ruff check . > /dev/null 2>&1 &&
            $PYTHON_CMD -m ruff format --check . > /dev/null 2>&1
        ); then
            echo -e "${GREEN}✓ PASS${NC}"
        else
            echo -e "${RED}✗ FAIL${NC}"
            FAILED_TESTS+=("Python project linting")
            VALIDATION_PASSED=false
        fi

        echo -n "Testing Python project tests... "
        if (
            cd /tmp/python-test-project &&
            $PYTHON_CMD -m pytest tests/ -v > /dev/null 2>&1
        ); then
            echo -e "${GREEN}✓ PASS${NC}"
        else
            echo -e "${RED}✗ FAIL${NC}"
            FAILED_TESTS+=("Python project tests")
            VALIDATION_PASSED=false
        fi

        echo -n "Testing Python project type checking... "
        if (
            cd /tmp/python-test-project &&
            $PYTHON_CMD -m mypy . > /dev/null 2>&1
        ); then
            echo -e "${GREEN}✓ PASS${NC}"
        else
            echo -e "${RED}✗ FAIL${NC}"
            FAILED_TESTS+=("Python project type checking")
            VALIDATION_PASSED=false
        fi
    else
        echo -e "${YELLOW}⚠ Python test project not found - skipping build tests${NC}"
    fi

    echo
}

validate_configuration_files() {
    echo -e "${BLUE}=== Configuration Files Validation ===${NC}"

    # Test git config (check if configured, not specific value)
    echo -n "Testing Git configuration... "
    if git config --global user.name > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
    else
        echo -e "${YELLOW}⚠ WARNING${NC} - Git user name not configured"
    fi

    # Test config files existence (as warnings since they may not exist in all environments)
    echo -n "Testing Git config file... "
    if [ -f ~/.gitconfig ]; then
        echo -e "${GREEN}✓ PASS${NC}"
    else
        echo -e "${YELLOW}⚠ WARNING${NC} - ~/.gitconfig not found"
    fi

    echo -n "Testing Clang format config... "
    if [ -f ~/.clang-format ]; then
        echo -e "${GREEN}✓ PASS${NC}"
    else
        echo -e "${YELLOW}⚠ WARNING${NC} - ~/.clang-format not found"
    fi

    echo -n "Testing Ruff config... "
    if [ -f ~/.config/ruff/ruff.toml ]; then
        echo -e "${GREEN}✓ PASS${NC}"
    else
        echo -e "${YELLOW}⚠ WARNING${NC} - ~/.config/ruff/ruff.toml not found"
    fi

    echo
}

print_final_summary() {
    echo -e "${BLUE}================================${NC}"
    if [ "$VALIDATION_PASSED" = true ]; then
        echo -e "${GREEN}✅ ALL VALIDATIONS PASSED!${NC}"
        echo -e "${GREEN}   Development environment is ready for use.${NC}"
    else
        echo -e "${RED}❌ VALIDATION FAILED!${NC}"
        echo -e "${RED}   The following tests failed:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "${RED}   - $test${NC}"
        done
        echo ""
        echo -e "${YELLOW}   Please check the installation and re-run validation.${NC}"
    fi
    echo -e "${BLUE}================================${NC}"
    echo ""
}

main() {
    case "${1:-}" in
        --system-only)
            validate_system_tools
            ;;
        --cpp-only)
            validate_cpp_tools
            ;;
        --python-only)
            validate_python_tools
            ;;
        --config-only)
            validate_configuration_files
            ;;
        --quick)
            validate_system_tools
            validate_configuration_files
            ;;
        *)
            validate_system_tools
            validate_cpp_tools
            validate_python_tools
            validate_configuration_files
            ;;
    esac

    print_final_summary

    # Exit with appropriate code
    if [ "$VALIDATION_PASSED" = true ]; then
        exit 0
    else
        exit 1
    fi
}

main "$@"