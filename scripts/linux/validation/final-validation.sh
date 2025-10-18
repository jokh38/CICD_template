#!/bin/bash
# Final Comprehensive Validation

set -e

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_UTILS="$(dirname "$(dirname "$SCRIPT_DIR")")/lib/common-utils.sh"

if [ -f "$COMMON_UTILS" ]; then
    source "$COMMON_UTILS"
else
    echo "Error: Cannot find common-utils.sh at $COMMON_UTILS"
    exit 1
fi

# Parse command line arguments
CPP_ONLY=false
PYTHON_ONLY=false
SYSTEM_ONLY=false

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
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validation counters
TOTAL_CATEGORIES=0
PASSED_CATEGORIES=0
TOTAL_TESTS=0
PASSED_TESTS=0
declare -a FAILED_TESTS

# Function to run a category of tests
run_category() {
    local category_name="$1"
    local category_tests=("$@")
    local category_total=0
    local category_passed=0

    TOTAL_CATEGORIES=$((TOTAL_CATEGORIES + 1))
    print_status "Validating: $category_name..."

    # Skip category name parameter for tests
    for test in "${category_tests[@]:1}"; do
        category_total=$((category_total + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))

        if eval "$test" > /dev/null 2>&1; then
            category_passed=$((category_passed + 1))
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            FAILED_TESTS+=("[$category_name] $test")
        fi
    done

    if [ $category_passed -eq $category_total ]; then
        print_success "✅ $category_name - PASSED ($category_passed/$category_total)"
        PASSED_CATEGORIES=$((PASSED_CATEGORIES + 1))
    else
        print_error "❌ $category_name - FAILED ($category_passed/$category_total)"
    fi
}

print_status "Starting final comprehensive validation..."

# System Tools Tests
run_category "System Tools Validation" \
    "git --version" \
    "cmake --version" \
    "ninja --version" \
    "make --version" \
    "python3 --version" \
    "pip3 --version"

# Compiler Tests
run_category "Compiler Tools Validation" \
    "gcc --version" \
    "g++ --version" \
    "clang --version" \
    "clang++ --version" \
    "clang-format --version" \
    "clang-tidy --version"

# Build Tools Tests
if [ "$PYTHON_ONLY" != "true" ]; then
    run_category "Build Tools Validation" \
        "sccache --version" \
        "conan --version" \
        "vcpkg version"
else
    print_header "Build Tools Validation"
    print_status "Skipping C++ build tools validation (Python only mode)"
fi

# Python Tools Tests
if [ "$CPP_ONLY" != "true" ]; then
    run_category "Python Development Tools Validation" \
        "ruff --version" \
        "python3 -c 'import black; print(black.__version__)'" \
        "pytest --version" \
        "mypy --version" \
        "bandit --version" \
        "pre-commit --version"
else
    print_header "Python Development Tools Validation"
    print_status "Skipping Python tools validation (C++ only mode)"
fi

# Configuration Tests
if [ "$CPP_ONLY" = "true" ]; then
    # C++ only configurations
    run_category "Configuration Files Validation" \
        "test -f ~/.gitignore_global" \
        "test -f ~/.clang-format" \
        "test -f ~/.clang-tidy" \
        "test -f ~/.config/cmake/CMakePresets.json" \
        "test -f ~/.config/sccache/config" \
        "test -d ~/.config/ai-workflows"
elif [ "$PYTHON_ONLY" = "true" ]; then
    # Python only configurations
    run_category "Configuration Files Validation" \
        "test -f ~/.gitignore_global" \
        "test -f ~/.config/ruff/ruff.toml" \
        "test -d ~/.config/ai-workflows"
else
    # Full installation configurations
    run_category "Configuration Files Validation" \
        "test -f ~/.gitignore_global" \
        "test -f ~/.clang-format" \
        "test -f ~/.clang-tidy" \
        "test -f ~/.config/ruff/ruff.toml" \
        "test -f ~/.config/cmake/CMakePresets.json" \
        "test -f ~/.config/sccache/config" \
        "test -d ~/.config/ai-workflows"
fi

# Git Configuration Tests
run_category "Git Configuration Validation" \
    "git config --global user.name" \
    "git config --global user.email" \
    "git config --global init.defaultBranch" \
    "git config --global core.autocrlf"

# C++ Compilation Tests
if [ "$PYTHON_ONLY" != "true" ]; then
    print_status "Validating: C++ Compilation..."

    cpp_tests_passed=0
    cpp_tests_total=8
    TOTAL_TESTS=$((TOTAL_TESTS + cpp_tests_total))

    # Test basic compilation
    cat > /tmp/test_cpp.cpp << 'EOF'
#include <iostream>
#include <string>
#include <vector>

int main() {
    std::vector<int> numbers = {1, 2, 3, 4, 5};
    int sum = 0;
    for (int num : numbers) {
        sum += num;
    }
    std::cout << "Sum: " << sum << std::endl;
    return 0;
}
EOF

    # GCC compilation
    if g++ -std=c++17 -o /tmp/test_gcc_cpp /tmp/test_cpp.cpp && /tmp/test_gcc_cpp > /tmp/gcc_output.txt 2>&1; then
        cpp_tests_passed=$((cpp_tests_passed + 1))
        if grep -q "Sum: 15" /tmp/gcc_output.txt; then
            cpp_tests_passed=$((cpp_tests_passed + 1))
        else
            FAILED_TESTS+=("[C++ Compilation] GCC program output incorrect")
        fi
    else
        FAILED_TESTS+=("[C++ Compilation] GCC compilation failed")
    fi

    # Clang compilation
    if clang++ -stdlib=libc++ -std=c++17 -o /tmp/test_clang_cpp /tmp/test_cpp.cpp && /tmp/test_clang_cpp > /tmp/clang_output.txt 2>&1; then
        cpp_tests_passed=$((cpp_tests_passed + 1))
        if grep -q "Sum: 15" /tmp/clang_output.txt; then
            cpp_tests_passed=$((cpp_tests_passed + 1))
        else
            FAILED_TESTS+=("[C++ Compilation] Clang program output incorrect")
        fi
    else
        FAILED_TESTS+=("[C++ Compilation] Clang compilation failed")
    fi

    # CMake build
    mkdir -p /tmp/cmake_test
    cat > /tmp/cmake_test/CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(CppTest VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(cpp_test /tmp/test_cpp.cpp)
EOF

    cd /tmp/cmake_test
    if cmake -S . -B build -DCMAKE_BUILD_TYPE=Release > /dev/null 2>&1; then
        cpp_tests_passed=$((cpp_tests_passed + 1))
        if cmake --build build --parallel > /dev/null 2>&1; then
            cpp_tests_passed=$((cpp_tests_passed + 1))
            if ./build/cpp_test > /tmp/cmake_output.txt 2>&1; then
                cpp_tests_passed=$((cpp_tests_passed + 1))
                if grep -q "Sum: 15" /tmp/cmake_output.txt; then
                    cpp_tests_passed=$((cpp_tests_passed + 1))
                else
                    FAILED_TESTS+=("[C++ Compilation] CMake program output incorrect")
                fi
            else
                FAILED_TESTS+=("[C++ Compilation] CMake built program execution failed")
            fi
        else
            FAILED_TESTS+=("[C++ Compilation] CMake build failed")
        fi
    else
        FAILED_TESTS+=("[C++ Compilation] CMake configuration failed")
    fi

    PASSED_TESTS=$((PASSED_TESTS + cpp_tests_passed))

    if [ $cpp_tests_passed -eq $cpp_tests_total ]; then
        print_success "✅ C++ Compilation - PASSED ($cpp_tests_passed/$cpp_tests_total)"
    else
        print_error "❌ C++ Compilation - FAILED ($cpp_tests_passed/$cpp_tests_total)"
    fi
else
    print_status "Skipping C++ compilation validation (Python only mode)"
fi

# Python Environment Tests
if [ "$CPP_ONLY" != "true" ]; then
    print_status "Validating: Python Environment..."

    python_tests_passed=0
    python_tests_total=6
    TOTAL_TESTS=$((TOTAL_TESTS + python_tests_total))

    # Test Python code execution
    cat > /tmp/test_python.py << 'EOF'
#!/usr/bin/env python3
"""Test Python script for validation."""

from typing import List

def calculate_sum(numbers: List[int]) -> int:
    """Calculate sum of numbers."""
    return sum(numbers)

def main() -> None:
    """Main function."""
    numbers = [1, 2, 3, 4, 5]
    result = calculate_sum(numbers)
    print(f"Sum: {result}")

if __name__ == "__main__":
    main()
EOF

    if python3 /tmp/test_python.py > /tmp/python_output.txt 2>&1; then
        python_tests_passed=$((python_tests_passed + 1))
        if grep -q "Sum: 15" /tmp/python_output.txt; then
            python_tests_passed=$((python_tests_passed + 1))
        else
            FAILED_TESTS+=("[Python Environment] Python script output incorrect")
        fi
    else
        FAILED_TESTS+=("[Python Environment] Python script execution failed")
    fi

    # Check if we're in a Python project directory
    if [ -d "src" ] || [ -d "tests" ] || [ -f "pyproject.toml" ]; then
        # Test on project files
        if [ -d "src" ]; then
            black --check src/ > /dev/null 2>&1 && python_tests_passed=$((python_tests_passed + 1)) || FAILED_TESTS+=("[Python Environment] Black formatting check failed")
            ruff check src/ > /dev/null 2>&1 && python_tests_passed=$((python_tests_passed + 1)) || FAILED_TESTS+=("[Python Environment] Ruff linting check failed")
            mypy src/ > /dev/null 2>&1 && python_tests_passed=$((python_tests_passed + 1)) || FAILED_TESTS+=("[Python Environment] MyPy type checking failed")
            bandit -r src/ > /dev/null 2>&1 && python_tests_passed=$((python_tests_passed + 1)) || FAILED_TESTS+=("[Python Environment] Bandit security analysis failed")
        else
            # Skip tests if no src directory
            python_tests_total=$((python_tests_total - 4))
            TOTAL_TESTS=$((TOTAL_TESTS - 4))
        fi
    else
        # Fallback to test file approach
        mkdir -p /tmp/python_test/src
        cp /tmp/test_python.py /tmp/python_test/src/
        black /tmp/python_test/src/ > /dev/null 2>&1

        black --check /tmp/python_test/src/ > /dev/null 2>&1 && python_tests_passed=$((python_tests_passed + 1)) || FAILED_TESTS+=("[Python Environment] Black formatting check failed")
        ruff check /tmp/python_test/src/ > /dev/null 2>&1 && python_tests_passed=$((python_tests_passed + 1)) || FAILED_TESTS+=("[Python Environment] Ruff linting check failed")
        mypy /tmp/python_test/src/ > /dev/null 2>&1 && python_tests_passed=$((python_tests_passed + 1)) || FAILED_TESTS+=("[Python Environment] MyPy type checking failed")
        bandit -r /tmp/python_test/src/ > /dev/null 2>&1 && python_tests_passed=$((python_tests_passed + 1)) || FAILED_TESTS+=("[Python Environment] Bandit security analysis failed")
    fi

    PASSED_TESTS=$((PASSED_TESTS + python_tests_passed))

    if [ $python_tests_passed -eq $python_tests_total ]; then
        print_success "✅ Python Environment - PASSED ($python_tests_passed/$python_tests_total)"
    else
        print_error "❌ Python Environment - FAILED ($python_tests_passed/$python_tests_total)"
    fi
else
    print_status "Skipping Python environment validation (C++ only mode)"
fi

# Performance Tests
if [ "$PYTHON_ONLY" != "true" ]; then
    print_status "Validating: Performance (sccache)..."

    perf_tests_passed=0
    perf_tests_total=1
    TOTAL_TESTS=$((TOTAL_TESTS + perf_tests_total))

    if sccache --show-stats > /tmp/sccache_stats.txt 2>&1; then
        perf_tests_passed=$((perf_tests_passed + 1))
    else
        FAILED_TESTS+=("[Performance] sccache is not working properly")
    fi

    PASSED_TESTS=$((PASSED_TESTS + perf_tests_passed))

    if [ $perf_tests_passed -eq $perf_tests_total ]; then
        print_success "✅ Performance - PASSED ($perf_tests_passed/$perf_tests_total)"
    else
        print_error "❌ Performance - FAILED ($perf_tests_passed/$perf_tests_total)"
    fi
else
    print_status "Skipping Performance validation (Python only mode)"
fi

# Cleanup
rm -f /tmp/test_cpp.cpp /tmp/test_gcc_cpp /tmp/test_clang_cpp /tmp/test_python.py
rm -rf /tmp/cmake_test /tmp/python_test
rm -f /tmp/gcc_output.txt /tmp/clang_output.txt /tmp/cmake_output.txt /tmp/python_output.txt /tmp/sccache_stats.txt /tmp/ruff_empty.toml

# Integration Tests
print_status "Validating: Integration Tests..."

integration_tests_passed=0
integration_tests_total=3
TOTAL_TESTS=$((TOTAL_TESTS + integration_tests_total))

TEST_PROJECT_DIR="/tmp/integration_test_$(date +%s)"
if mkdir -p "$TEST_PROJECT_DIR"; then
    cd "$TEST_PROJECT_DIR"

    # Initialize git repo
    if git init > /dev/null 2>&1 && git config user.name "Test User" && git config user.email "test@example.com"; then
        integration_tests_passed=$((integration_tests_passed + 1))

        # Create README
        if echo "# Test Project" > README.md; then
            integration_tests_passed=$((integration_tests_passed + 1))

            # Add and commit
            if git add . && git commit -m "Initial commit" > /dev/null 2>&1; then
                integration_tests_passed=$((integration_tests_passed + 1))
            else
                FAILED_TESTS+=("[Integration] Git commit failed")
            fi
        else
            FAILED_TESTS+=("[Integration] Project file creation failed")
        fi
    else
        FAILED_TESTS+=("[Integration] Git repository initialization failed")
    fi

    rm -rf "$TEST_PROJECT_DIR"
else
    FAILED_TESTS+=("[Integration] Test project directory creation failed")
fi

PASSED_TESTS=$((PASSED_TESTS + integration_tests_passed))

if [ $integration_tests_passed -eq $integration_tests_total ]; then
    print_success "✅ Integration Tests - PASSED ($integration_tests_passed/$integration_tests_total)"
else
    print_error "❌ Integration Tests - FAILED ($integration_tests_passed/$integration_tests_total)"
fi

# Final Summary
print_header "═══════════════════════════════════════════════════════════════"
print_header "                    VALIDATION SUMMARY                          "
print_header "═══════════════════════════════════════════════════════════════"

# Overall Status
if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    print_success "Overall Status: ✅ PASSED"
else
    print_error "Overall Status: ❌ FAILED"
fi
echo ""

# Results Summary
print_status "Test Results:"
echo "  - Categories: $PASSED_CATEGORIES passed out of $TOTAL_CATEGORIES"
echo "  - Total Checks: $PASSED_TESTS passed out of $TOTAL_TESTS"
echo ""

# Failed Tests Details
if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    print_error "Failure Details:"
    for failed_test in "${FAILED_TESTS[@]}"; do
        echo "  - $failed_test"
    done
    echo ""
fi

# Environment Information
print_status "Environment Information:"
echo "  - OS:         $(uname -s) $(uname -r)"
echo "  - Arch:       $(uname -m)"
echo "  - User:       $(whoami)"
echo "  - Git:        $(git --version 2>/dev/null | cut -d' ' -f3 || echo 'Not installed')"
echo "  - CMake:      $(cmake --version 2>/dev/null | head -n1 | cut -d' ' -f3 || echo 'Not installed')"
echo "  - Python:     $(python3 --version 2>/dev/null | cut -d' ' -f2 || echo 'Not installed')"
echo "  - GCC:        $(gcc --version 2>/dev/null | head -n1 | cut -d' ' -f4 || echo 'Not installed')"
echo "  - Clang:      $(clang --version 2>/dev/null | head -n1 | cut -d' ' -f3 || echo 'Not installed')"
echo ""

print_header "═══════════════════════════════════════════════════════════════"

# Final Message and Exit
if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    print_success "🎉 Your development environment is ready! 🎉"
    echo ""
    print_status "Next Steps:"
    echo "  1. Start developing your projects."
    echo "  2. Explore AI workflows in ~/.config/ai-workflows/"
    echo "  3. Customize configurations as needed."
    exit 0
else
    print_error "Validation failed. Please review the errors above."
    echo ""
    print_status "Troubleshooting:"
    echo "  1. Ensure all required packages are installed correctly."
    echo "  2. Verify that your environment variables are set properly."
    echo "  3. If issues persist, consider re-running the setup script."
    exit 1
fi