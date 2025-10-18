#!/bin/bash
# Create Test Projects for Validation

set -e

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_UTILS="$SCRIPT_DIR/../../lib/common-utils.sh"

if [ -f "$COMMON_UTILS" ]; then
    source "$COMMON_UTILS"
else
    echo "Error: Cannot find common-utils.sh at $COMMON_UTILS"
    exit 1
fi

# Parse command line arguments
CPP_ONLY=false
PYTHON_ONLY=false

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
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to detect conda environment
detect_conda() {
    if command -v conda >/dev/null 2>&1; then
        echo "conda"
    else
        echo "pip3"
    fi
}

# Function to get the appropriate pip command
get_pip_command() {
    if [ "$(detect_conda)" = "conda" ]; then
        echo "pip"
    else
        echo "pip3"
    fi
}

# Function to get current user (not root)
get_current_user() {
    if [ "$EUID" -eq 0 ]; then
        # If running as root, try to find the original user
        if [ -n "$SUDO_USER" ]; then
            echo "$SUDO_USER"
        elif [ -n "$USER" ] && [ "$USER" != "root" ]; then
            echo "$USER"
        else
            # Fallback to nobody user
            echo "nobody"
        fi
    else
        echo "$USER"
    fi
}

# Create base test directory with correct user permissions
CURRENT_USER=$(get_current_user)
TEST_BASE="/tmp/test-projects-$(date +%s)"
mkdir -p "$TEST_BASE"

# Change ownership if we're running as root
if [ "$EUID" -eq 0 ] && [ "$CURRENT_USER" != "root" ]; then
    chown -R "$CURRENT_USER:$CURRENT_USER" "$TEST_BASE"
fi

cd "$TEST_BASE"
print_status "Creating test projects in: $TEST_BASE (user: $CURRENT_USER)"

# Create C++ test project
if [ "$PYTHON_ONLY" != "true" ]; then
    print_status "Creating C++ test project..."

    mkdir -p cpp-test-project/{src,include,tests,build}

    # Set ownership for the C++ project directory
    if [ "$EUID" -eq 0 ] && [ "$CURRENT_USER" != "root" ]; then
        chown -R "$CURRENT_USER:$CURRENT_USER" cpp-test-project
    fi

    cd cpp-test-project

    # Create main source file
    cat > src/main.cpp << 'EOF'
#include <iostream>
#include <string>
#include <vector>
#include "calculator.h"

int main() {
    Calculator calc;

    // Test basic operations
    std::cout << "Testing Calculator class:\n";
    std::cout << "2 + 3 = " << calc.add(2, 3) << std::endl;
    std::cout << "5 - 2 = " << calc.subtract(5, 2) << std::endl;
    std::cout << "4 * 3 = " << calc.multiply(4, 3) << std::endl;
    std::cout << "10 / 2 = " << calc.divide(10, 2) << std::endl;

    // Test vector operations
    std::vector<int> numbers = {1, 2, 3, 4, 5};
    int sum = calc.sum(numbers);
    std::cout << "Sum of [1,2,3,4,5] = " << sum << std::endl;

    return 0;
}
EOF

    # Create header file
    cat > include/calculator.h << 'EOF'
#ifndef CALCULATOR_H
#define CALCULATOR_H

#include <vector>

class Calculator {
public:
    // Basic arithmetic operations
    double add(double a, double b);
    double subtract(double a, double b);
    double multiply(double a, double b);
    double divide(double a, double b);

    // Vector operations
    int sum(const std::vector<int>& numbers);
    double average(const std::vector<int>& numbers);
    int max(const std::vector<int>& numbers);
    int min(const std::vector<int>& numbers);
};

#endif // CALCULATOR_H
EOF

    # Create implementation file
    cat > src/calculator.cpp << 'EOF'
#include "calculator.h"
#include <stdexcept>
#include <algorithm>

double Calculator::add(double a, double b) {
    return a + b;
}

double Calculator::subtract(double a, double b) {
    return a - b;
}

double Calculator::multiply(double a, double b) {
    return a * b;
}

double Calculator::divide(double a, double b) {
    if (b == 0.0) {
        throw std::runtime_error("Division by zero");
    }
    return a / b;
}

int Calculator::sum(const std::vector<int>& numbers) {
    int result = 0;
    for (int num : numbers) {
        result += num;
    }
    return result;
}

double Calculator::average(const std::vector<int>& numbers) {
    if (numbers.empty()) {
        throw std::runtime_error("Cannot calculate average of empty vector");
    }
    return static_cast<double>(sum(numbers)) / numbers.size();
}

int Calculator::max(const std::vector<int>& numbers) {
    if (numbers.empty()) {
        throw std::runtime_error("Cannot find max of empty vector");
    }
    return *std::max_element(numbers.begin(), numbers.end());
}

int Calculator::min(const std::vector<int>& numbers) {
    if (numbers.empty()) {
        throw std::runtime_error("Cannot find min of empty vector");
    }
    return *std::min_element(numbers.begin(), numbers.end());
}
EOF

    # Create test file
    cat > tests/test_calculator.cpp << 'EOF'
#include <gtest/gtest.h>
#include "calculator.h"
#include <vector>
#include <stdexcept>

class CalculatorTest : public ::testing::Test {
protected:
    void SetUp() override {
        calc = std::make_unique<Calculator>();
    }

    std::unique_ptr<Calculator> calc;
};

TEST_F(CalculatorTest, BasicOperations) {
    EXPECT_EQ(calc->add(2, 3), 5);
    EXPECT_EQ(calc->subtract(5, 2), 3);
    EXPECT_EQ(calc->multiply(4, 3), 12);
    EXPECT_EQ(calc->divide(10, 2), 5);
}

TEST_F(CalculatorTest, DivisionByZero) {
    EXPECT_THROW(calc->divide(10, 0), std::runtime_error);
}

TEST_F(CalculatorTest, VectorOperations) {
    std::vector<int> numbers = {1, 2, 3, 4, 5};

    EXPECT_EQ(calc->sum(numbers), 15);
    EXPECT_EQ(calc->average(numbers), 3.0);
    EXPECT_EQ(calc->max(numbers), 5);
    EXPECT_EQ(calc->min(numbers), 1);
}

TEST_F(CalculatorTest, EmptyVectorOperations) {
    std::vector<int> empty;

    EXPECT_THROW(calc->average(empty), std::runtime_error);
    EXPECT_THROW(calc->max(empty), std::runtime_error);
    EXPECT_THROW(calc->min(empty), std::runtime_error);
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
EOF

    # Create CMakeLists.txt
    cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(CalculatorTest VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(GTest REQUIRED)
find_package(PkgConfig REQUIRED)

# Include directories
include_directories(include)

# Add calculator library
add_library(calculator src/calculator.cpp)

# Add executable
add_executable(calculator_app src/main.cpp)
target_link_libraries(calculator_app calculator)

# Add tests
enable_testing()
add_executable(calculator_tests tests/test_calculator.cpp)
target_link_libraries(calculator_tests calculator GTest::gtest GTest::gtest_main)

# Add test to CTest
add_test(NAME CalculatorTests COMMAND calculator_tests)

# Compiler-specific options
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_compile_options(calculator PRIVATE -Wall -Wextra -Wpedantic)
    target_compile_options(calculator_app PRIVATE -Wall -Wextra -Wpedantic)
    target_compile_options(calculator_tests PRIVATE -Wall -Wextra -Wpedantic)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_options(calculator PRIVATE -Wall -Wextra -Wpedantic)
    target_compile_options(calculator_app PRIVATE -Wall -Wextra -Wpedantic)
    target_compile_options(calculator_tests PRIVATE -Wall -Wextra -Wpedantic)
endif()
EOF

    # Create .clang-format for project
    cat > .clang-format << 'EOF'
BasedOnStyle: LLVM
IndentWidth: 4
TabWidth: 4
UseTab: Never
ColumnLimit: 100
BreakBeforeBraces: Linux
EOF

    cd "$TEST_BASE"
    print_success "C++ test project created"
fi

# Create Python test project
if [ "$CPP_ONLY" != "true" ]; then
    print_status "Creating Python test project..."

    mkdir -p python-test-project/{src,tests,docs}

    # Set ownership for the Python project directory
    if [ "$EUID" -eq 0 ] && [ "$CURRENT_USER" != "root" ]; then
        chown -R "$CURRENT_USER:$CURRENT_USER" python-test-project
    fi

    cd python-test-project

    # Create main source file
    mkdir -p src/calculator
    cat > src/calculator/__init__.py << 'EOF'
"""Calculator package for arithmetic operations."""

from .calculator import Calculator

__all__ = ["Calculator"]
__version__ = "1.0.0"
EOF

    cat > src/calculator/calculator.py << 'EOF'
"""Calculator class with basic arithmetic operations."""

from typing import Sequence, Union


class Calculator:
    """A simple calculator for performing arithmetic operations."""

    def add(self, a: Union[int, float], b: Union[int, float]) -> Union[int, float]:
        """Add two numbers."""
        return a + b

    def subtract(self, a: Union[int, float], b: Union[int, float]) -> Union[int, float]:
        """Subtract two numbers."""
        return a - b

    def multiply(self, a: Union[int, float], b: Union[int, float]) -> Union[int, float]:
        """Multiply two numbers."""
        return a * b

    def divide(self, a: Union[int, float], b: Union[int, float]) -> Union[int, float]:
        """Divide two numbers.

        Args:
            a: Dividend
            b: Divisor

        Returns:
            Result of division

        Raises:
            ZeroDivisionError: If b is zero
        """
        if b == 0:
            raise ZeroDivisionError("Cannot divide by zero")
        return a / b

    def sum(self, numbers: Sequence[Union[int, float]]) -> Union[int, float]:
        """Calculate sum of a list of numbers."""
        return sum(numbers)

    def average(self, numbers: Sequence[Union[int, float]]) -> float:
        """Calculate average of a list of numbers.

        Args:
            numbers: List of numbers

        Returns:
            Average value

        Raises:
            ValueError: If list is empty
        """
        if not numbers:
            raise ValueError("Cannot calculate average of empty list")
        return sum(numbers) / len(numbers)

    def max(self, numbers: Sequence[Union[int, float]]) -> Union[int, float]:
        """Find maximum value in a list of numbers.

        Args:
            numbers: List of numbers

        Returns:
            Maximum value

        Raises:
            ValueError: If list is empty
        """
        if not numbers:
            raise ValueError("Cannot find max of empty list")
        return max(numbers)

    def min(self, numbers: Sequence[Union[int, float]]) -> Union[int, float]:
        """Find minimum value in a list of numbers.

        Args:
            numbers: List of numbers

        Returns:
            Minimum value

        Raises:
            ValueError: If list is empty
        """
        if not numbers:
            raise ValueError("Cannot find min of empty list")
        return min(numbers)
EOF

    # Create main application
    cat > src/main.py << 'EOF'
"""Main application for calculator demonstration."""

from calculator import Calculator


def main() -> None:
    """Demonstrate calculator functionality."""
    calc = Calculator()

    print("Testing Calculator class:")
    print(f"2 + 3 = {calc.add(2, 3)}")
    print(f"5 - 2 = {calc.subtract(5, 2)}")
    print(f"4 * 3 = {calc.multiply(4, 3)}")
    print(f"10 / 2 = {calc.divide(10, 2)}")

    # Test vector operations
    numbers = [1, 2, 3, 4, 5]
    print(f"Sum of {numbers} = {calc.sum(numbers)}")
    print(f"Average of {numbers} = {calc.average(numbers)}")
    print(f"Max of {numbers} = {calc.max(numbers)}")
    print(f"Min of {numbers} = {calc.min(numbers)}")


if __name__ == "__main__":
    main()
EOF

    # Create test files
    cat > tests/test_calculator.py << 'EOF'
"""Tests for calculator module."""

import pytest

from calculator import Calculator


class TestCalculator:
    """Test cases for Calculator class."""

    def setup_method(self):
        """Set up test fixtures before each test method."""
        self.calc = Calculator()

    def test_add(self):
        """Test addition method."""
        assert self.calc.add(2, 3) == 5
        assert self.calc.add(-1, 1) == 0
        assert self.calc.add(0, 0) == 0
        assert self.calc.add(2.5, 3.5) == 6.0

    def test_subtract(self):
        """Test subtraction method."""
        assert self.calc.subtract(5, 2) == 3
        assert self.calc.subtract(1, 1) == 0
        assert self.calc.subtract(5.5, 2.5) == 3.0

    def test_multiply(self):
        """Test multiplication method."""
        assert self.calc.multiply(4, 3) == 12
        assert self.calc.multiply(0, 5) == 0
        assert self.calc.multiply(2.5, 2) == 5.0

    def test_divide(self):
        """Test division method."""
        assert self.calc.divide(10, 2) == 5
        assert self.calc.divide(5, 2) == 2.5
        assert self.calc.divide(-4, 2) == -2

    def test_divide_by_zero(self):
        """Test division by zero raises exception."""
        with pytest.raises(ZeroDivisionError, match="Cannot divide by zero"):
            self.calc.divide(10, 0)

    def test_sum(self):
        """Test sum method."""
        assert self.calc.sum([1, 2, 3, 4, 5]) == 15
        assert self.calc.sum([0, 0, 0]) == 0
        assert self.calc.sum([-1, 1, 0]) == 0
        assert self.calc.sum([1.5, 2.5]) == 4.0

    def test_average(self):
        """Test average method."""
        assert self.calc.average([1, 2, 3, 4, 5]) == 3.0
        assert self.calc.average([2, 4]) == 3.0
        assert self.calc.average([0]) == 0

    def test_average_empty_list(self):
        """Test average of empty list raises exception."""
        with pytest.raises(ValueError, match="Cannot calculate average of empty list"):
            self.calc.average([])

    def test_max(self):
        """Test max method."""
        assert self.calc.max([1, 2, 3, 4, 5]) == 5
        assert self.calc.max([5, 3, 5, 2]) == 5
        assert self.calc.max([-1, -2, -3]) == -1

    def test_max_empty_list(self):
        """Test max of empty list raises exception."""
        with pytest.raises(ValueError, match="Cannot find max of empty list"):
            self.calc.max([])

    def test_min(self):
        """Test min method."""
        assert self.calc.min([1, 2, 3, 4, 5]) == 1
        assert self.calc.min([5, 3, 5, 2]) == 2
        assert self.calc.min([-1, -2, -3]) == -3

    def test_min_empty_list(self):
        """Test min of empty list raises exception."""
        with pytest.raises(ValueError, match="Cannot find min of empty list"):
            self.calc.min([])
EOF

    cat > tests/__init__.py << 'EOF'
"""Test package for calculator."""
EOF

    # Create requirements files
    cat > requirements.txt << 'EOF'
# Production dependencies
# (None for this simple project)
EOF

    cat > requirements-dev.txt << 'EOF'
# Development dependencies
-r requirements.txt

# Testing
pytest>=7.0.0
pytest-cov>=4.0.0
pytest-mock>=3.10.0

# Code quality
black>=23.0.0
ruff>=0.0.260
mypy>=1.0.0
bandit>=1.7.0

# Documentation
sphinx>=5.0.0
sphinx-rtd-theme>=1.2.0
EOF

    # Create pyproject.toml
    cat > pyproject.toml << 'EOF'
[build-system]
requires = ["setuptools>=45", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "calculator"
version = "1.0.0"
description = "A simple calculator for arithmetic operations"
authors = [
    {name = "Test User", email = "test@example.com"}
]
readme = "README.md"
requires-python = ">=3.8"
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.8",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
]

[tool.black]
line-length = 88
target-version = ['py38']

[tool.ruff]
line-length = 88
target-version = "py38"

[tool.ruff.lint]
select = ["E", "F", "UP", "B", "SIM", "I"]
ignore = ["F405", "F403", "F841"]

[tool.mypy]
python_version = "3.10"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true

[tool.pytest.ini_options]
minversion = "6.0"
addopts = "-ra -q --strict-markers --strict-config"
testpaths = ["tests"]
EOF

    # Create README
    cat > README.md << 'EOF'
# Calculator Project

A simple calculator package for performing arithmetic operations.

## Features

- Basic arithmetic operations (add, subtract, multiply, divide)
- Vector operations (sum, average, max, min)
- Type hints for better code clarity
- Comprehensive test coverage

## Installation

```bash
pip install -r requirements-dev.txt
```

## Usage

```python
from calculator import Calculator

calc = Calculator()
result = calc.add(2, 3)  # Returns 5
```

## Testing

```bash
pytest tests/ --cov=src
```

## Code Quality

```bash
# Format code
black src/ tests/

# Lint code
ruff check src/ tests/

# Type checking
mypy src/
```
EOF

    # Create .gitignore
    cat > .gitignore << 'EOF'
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# C extensions
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# PyInstaller
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
.hypothesis/
.pytest_cache/

# Translations
*.mo
*.pot

# Django stuff:
*.log
local_settings.py
db.sqlite3

# Flask stuff:
instance/
.webassets-cache

# Scrapy stuff:
.scrapy

# Sphinx documentation
docs/_build/

# PyBuilder
target/

# Jupyter Notebook
.ipynb_checkpoints

# pyenv
.python-version

# celery beat schedule file
celerybeat-schedule

# SageMath parsed files
*.sage.py

# Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Spyder project settings
.spyderproject
.spyproject

# Rope project settings
.ropeproject

# mkdocs documentation
/site

# mypy
.mypy_cache/
.dmypy.json
dmypy.json
EOF

    cd "$TEST_BASE"
    print_success "Python test project created"
fi

print_success "Test projects created successfully in: $TEST_BASE"
print_status "You can now test the setup by running validation scripts"