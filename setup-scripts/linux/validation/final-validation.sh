#!/bin/bash
# Final Comprehensive Validation

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

print_header() {
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Validation counters
TOTAL_CATEGORIES=0
PASSED_CATEGORIES=0

# Function to run a category of tests
run_category() {
    local category_name="$1"
    local category_tests=("$@")
    local category_total=0
    local category_passed=0

    TOTAL_CATEGORIES=$((TOTAL_CATEGORIES + 1))
    print_header "$category_name"

    # Skip category name parameter for tests
    for test in "${category_tests[@]:1}"; do
        category_total=$((category_total + 1))
        print_status "Running: $test"

        if eval "$test" > /dev/null 2>&1; then
            print_success "✓ $test"
            category_passed=$((category_passed + 1))
        else
            print_error "✗ $test"
        fi
    done

    echo ""
    echo "Category Results: $category_passed/$category_total tests passed"

    if [ $category_passed -eq $category_total ]; then
        print_success "✅ $category_name - PASSED"
        PASSED_CATEGORIES=$((PASSED_CATEGORIES + 1))
    else
        print_error "❌ $category_name - FAILED"
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
run_category "Build Tools Validation" \
    "sccache --version" \
    "conan --version" \
    "vcpkg version"

# Python Tools Tests
run_category "Python Development Tools Validation" \
    "python3 -c 'import ruff; print(ruff.__version__)'" \
    "python3 -c 'import black; print(black.__version__)'" \
    "python3 -c 'import pytest; print(pytest.__version__)'" \
    "python3 -c 'import mypy; print(mypy.__version__)'" \
    "python3 -c 'import bandit; print(bandit.__version__)'" \
    "python3 -c 'import pre_commit; print(pre_commit.__version__)'"

# Configuration Tests
run_category "Configuration Files Validation" \
    "test -f ~/.gitignore_global" \
    "test -f ~/.clang-format" \
    "test -f ~/.clang-tidy" \
    "test -f ~/.config/ruff/ruff.toml" \
    "test -f ~/.config/cmake/CMakePresets.json" \
    "test -f ~/.config/sccache/config" \
    "test -d ~/.config/ai-workflows"

# Git Configuration Tests
run_category "Git Configuration Validation" \
    "git config --global user.name" \
    "git config --global user.email" \
    "git config --global init.defaultBranch" \
    "git config --global core.autocrlf"

# C++ Compilation Tests
print_header "C++ Compilation Validation"

# Test basic compilation
print_status "Testing C++ compilation with GCC..."
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

if g++ -std=c++17 -o /tmp/test_gcc_cpp /tmp/test_cpp.cpp && /tmp/test_gcc_cpp > /tmp/gcc_output.txt 2>&1; then
    print_success "✓ GCC compilation and execution"
    if grep -q "Sum: 15" /tmp/gcc_output.txt; then
        print_success "✓ GCC program output correct"
    else
        print_error "✗ GCC program output incorrect"
    fi
else
    print_error "✗ GCC compilation failed"
fi

# Test with Clang
print_status "Testing C++ compilation with Clang..."
if clang++ -std=c++17 -o /tmp/test_clang_cpp /tmp/test_cpp.cpp && /tmp/test_clang_cpp > /tmp/clang_output.txt 2>&1; then
    print_success "✓ Clang compilation and execution"
    if grep -q "Sum: 15" /tmp/clang_output.txt; then
        print_success "✓ Clang program output correct"
    else
        print_error "✗ Clang program output incorrect"
    fi
else
    print_error "✗ Clang compilation failed"
fi

# Test CMake build
print_status "Testing CMake build system..."
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
    print_success "✓ CMake configuration"
    if cmake --build build --parallel > /dev/null 2>&1; then
        print_success "✓ CMake build"
        if ./build/cpp_test > /tmp/cmake_output.txt 2>&1; then
            print_success "✓ CMake built program execution"
            if grep -q "Sum: 15" /tmp/cmake_output.txt; then
                print_success "✓ CMake program output correct"
            else
                print_error "✗ CMake program output incorrect"
            fi
        else
            print_error "✗ CMake built program execution failed"
        fi
    else
        print_error "✗ CMake build failed"
    fi
else
    print_error "✗ CMake configuration failed"
fi

# Python Environment Tests
print_header "Python Environment Validation"

# Test Python code execution
print_status "Testing Python code execution..."
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
    print_success "✓ Python script execution"
    if grep -q "Sum: 15" /tmp/python_output.txt; then
        print_success "✓ Python script output correct"
    else
        print_error "✗ Python script output incorrect"
    fi
else
    print_error "✗ Python script execution failed"
fi

# Test Python tools on sample code
print_status "Testing Python development tools..."
mkdir -p /tmp/python_test/src
cp /tmp/test_python.py /tmp/python_test/src/

# Test Black formatting
if black --check /tmp/python_test/src/ > /dev/null 2>&1; then
    print_success "✓ Black formatting check"
else
    print_error "✗ Black formatting check failed"
fi

# Test Ruff linting
if ruff check /tmp/python_test/src/ > /dev/null 2>&1; then
    print_success "✓ Ruff linting check"
else
    print_error "✗ Ruff linting check failed"
fi

# Test MyPy type checking
if mypy /tmp/python_test/src/ > /dev/null 2>&1; then
    print_success "✓ MyPy type checking"
else
    print_error "✗ MyPy type checking failed"
fi

# Test Bandit security analysis
if bandit -r /tmp/python_test/src/ > /dev/null 2>&1; then
    print_success "✓ Bandit security analysis"
else
    print_error "✗ Bandit security analysis failed"
fi

# Performance Tests
print_header "Performance Validation"

# Test compiler cache (sccache)
print_status "Testing sccache functionality..."
if sccache --show-stats > /tmp/sccache_stats.txt 2>&1; then
    print_success "✓ sccache is functional"
else
    print_error "✗ sccache is not working properly"
fi

# Cleanup
rm -f /tmp/test_cpp.cpp /tmp/test_gcc_cpp /tmp/test_clang_cpp /tmp/test_python.py
rm -rf /tmp/cmake_test /tmp/python_test
rm -f /tmp/gcc_output.txt /tmp/clang_output.txt /tmp/cmake_output.txt /tmp/python_output.txt /tmp/sccache_stats.txt

# Integration Tests
print_header "Integration Tests Validation"

# Test project creation capability
print_status "Testing project creation workflow..."
TEST_PROJECT_DIR="/tmp/integration_test_$(date +%s)"
if mkdir -p "$TEST_PROJECT_DIR"; then
    cd "$TEST_PROJECT_DIR"

    # Initialize git repo
    if git init > /dev/null 2>&1 && git config user.name "Test User" && git config user.email "test@example.com"; then
        print_success "✓ Git repository initialization"

        # Create README
        if echo "# Test Project" > README.md; then
            print_success "✓ Project file creation"

            # Add and commit
            if git add . && git commit -m "Initial commit" > /dev/null 2>&1; then
                print_success "✓ Git commit functionality"
            else
                print_error "✗ Git commit failed"
            fi
        else
            print_error "✗ Project file creation failed"
        fi
    else
        print_error "✗ Git repository initialization failed"
    fi

    rm -rf "$TEST_PROJECT_DIR"
else
    print_error "✗ Test project directory creation failed"
fi

# Final Summary
print_header "Final Validation Summary"

echo "Total Categories: $TOTAL_CATEGORIES"
echo "Passed Categories: $PASSED_CATEGORIES"
echo "Failed Categories: $((TOTAL_CATEGORIES - PASSED_CATEGORIES))"

echo ""
echo "Environment Information:"
echo "- OS: $(uname -s) $(uname -r)"
echo "- Architecture: $(uname -m)"
echo "- Shell: $SHELL"
echo "- User: $(whoami)"
echo "- Home Directory: $HOME"
echo "- Current Directory: $(pwd)"

echo ""
echo "Key Tool Versions:"
echo "- Git: $(git --version 2>/dev/null | cut -d' ' -f3 || echo 'Not installed')"
echo "- CMake: $(cmake --version 2>/dev/null | head -n1 | cut -d' ' -f3 || echo 'Not installed')"
echo "- Python: $(python3 --version 2>/dev/null | cut -d' ' -f2 || echo 'Not installed')"
echo "- GCC: $(gcc --version 2>/dev/null | head -n1 | cut -d' ' -f4 || echo 'Not installed')"
echo "- Clang: $(clang --version 2>/dev/null | head -n1 | cut -d' ' -f3 || echo 'Not installed')"

if [ $PASSED_CATEGORIES -eq $TOTAL_CATEGORIES ]; then
    echo ""
    print_success "🎉 ALL VALIDATION TESTS PASSED! 🎉"
    echo ""
    echo "Your development environment is fully configured and ready for use!"
    echo ""
    echo "Next Steps:"
    echo "1. Start developing your projects"
    echo "2. Use the provided AI workflow templates in ~/.config/ai-workflows/"
    echo "3. Test your tools with real projects"
    echo "4. Customize configurations as needed"
    echo ""
    echo "Helpful Resources:"
    echo "- Git configuration: ~/.gitconfig"
    echo "- Code formatting: ~/.clang-format, ~/.config/ruff/ruff.toml"
    echo "- Build presets: ~/.config/cmake/CMakePresets.json"
    echo "- AI workflows: ~/.config/ai-workflows/"
    exit 0
else
    echo ""
    print_error "❌ SOME VALIDATION TESTS FAILED"
    echo ""
    echo "Please review the failed tests above and resolve the issues."
    echo "You may need to reinstall or reconfigure certain tools."
    echo ""
    echo "Troubleshooting Tips:"
    echo "1. Check that all packages were installed correctly"
    echo "2. Verify environment variables are set correctly"
    echo "3. Ensure you have the necessary permissions"
    echo "4. Try running the setup script again"
    exit 1
fi