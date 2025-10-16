#!/bin/bash
# Test Project Creation for Validation

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

RUNNER_USER="github-runner"

create_cpp_test_project() {
    echo -e "${GREEN}Creating test C++ project to verify installation...${NC}"

    TEST_DIR="/tmp/cpp-test-project"

    # Create test project directory structure
    mkdir -p "$TEST_DIR"/{src,tests,cmake,.github/workflows}
    cd "$TEST_DIR"

    # Create main library source
    cat > src/calculator.cpp << 'CPP_FILE'
#include "calculator.h"

int Calculator::add(int a, int b) {
    return a + b;
}

int Calculator::multiply(int a, int b) {
    return a * b;
}

double Calculator::divide(double a, double b) {
    if (b == 0.0) {
        throw std::invalid_argument("Division by zero");
    }
    return a / b;
}
CPP_FILE

    cat > src/calculator.h << 'CPP_HEADER'
#pragma once
#include <stdexcept>

class Calculator {
public:
    int add(int a, int b);
    int multiply(int a, int b);
    double divide(double a, double b);
};
CPP_HEADER

    # Create main executable
    cat > src/main.cpp << 'CPP_MAIN'
#include <iostream>
#include "calculator.h"

int main() {
    Calculator calc;

    std::cout << "5 + 3 = " << calc.add(5, 3) << std::endl;
    std::cout << "5 * 3 = " << calc.multiply(5, 3) << std::endl;

    try {
        std::cout << "10 / 3 = " << calc.divide(10.0, 3.0) << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
    }

    return 0;
}
CPP_MAIN

    # Create test file
    cat > tests/test_calculator.cpp << 'CPP_TEST'
#include <gtest/gtest.h>
#include "calculator.h"

class CalculatorTest : public ::testing::Test {
protected:
    Calculator calc;
};

TEST_F(CalculatorTest, Add) {
    EXPECT_EQ(calc.add(2, 3), 5);
    EXPECT_EQ(calc.add(-1, 1), 0);
    EXPECT_EQ(calc.add(0, 0), 0);
}

TEST_F(CalculatorTest, Multiply) {
    EXPECT_EQ(calc.multiply(2, 3), 6);
    EXPECT_EQ(calc.multiply(-1, 5), -5);
    EXPECT_EQ(calc.multiply(0, 10), 0);
}

TEST_F(CalculatorTest, Divide) {
    EXPECT_DOUBLE_EQ(calc.divide(10.0, 2.0), 5.0);
    EXPECT_DOUBLE_EQ(calc.divide(7.0, 2.0), 3.5);

    EXPECT_THROW(calc.divide(1.0, 0.0), std::invalid_argument);
}
CPP_TEST

    # Create CMakeLists.txt
    cat > CMakeLists.txt << 'CMAKE_FILE'
cmake_minimum_required(VERSION 3.20)
project(calculator VERSION 1.0.0 LANGUAGES CXX)

# C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Export compile commands for clang-tidy
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Compiler options
if(MSVC)
    add_compile_options(/W4)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Add system include directories explicitly for clang-tidy (from g++ -E -v)
include_directories(SYSTEM "/usr/include/c++/11")
include_directories(SYSTEM "/usr/include/x86_64-linux-gnu/c++/11")
include_directories(SYSTEM "/usr/include/c++/11/backward")
include_directories(SYSTEM "/usr/include/x86_64-linux-gnu")
include_directories(SYSTEM "/usr/include")

# Find packages
find_package(GTest REQUIRED)

# Library
add_library(calculator_lib
    src/calculator.cpp
)

target_include_directories(calculator_lib
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Executable
add_executable(calculator
    src/main.cpp
)

target_link_libraries(calculator
    PRIVATE calculator_lib
)

# Tests
enable_testing()
add_executable(test_calculator
    tests/test_calculator.cpp
)

target_link_libraries(test_calculator
    PRIVATE calculator_lib
    GTest::gtest
    GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(test_calculator)
CMAKE_FILE

    # Copy AI workflow from template
    if [ -d ~/.config/templates/cpp/.github/workflows ]; then
        cp ~/.config/templates/cpp/.github/workflows/ai-workflow.yaml .github/workflows/
    fi

    # Copy HIVE_CLAUDE.md as CLAUDE.md to project root
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TEMPLATE_ROOT="$(dirname "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")")"
    HIVE_CLAUDE_SOURCE="$TEMPLATE_ROOT/docs/HIVE_CLAUDE.md"

    if [ -f "$HIVE_CLAUDE_SOURCE" ]; then
        cp "$HIVE_CLAUDE_SOURCE" CLAUDE.md
        echo "Copied HIVE_CLAUDE.md as CLAUDE.md to project root"
    else
        echo "Warning: HIVE_CLAUDE.md not found at $HIVE_CLAUDE_SOURCE"
    fi

    # Initialize git repository
    echo "Initializing git repository..."
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"

    # Create .gitignore
    cat > .gitignore << 'GITIGNORE'
# Build directories
build/
cmake-build-*/

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Compiled output
*.o
*.a
*.so
*.dylib
*.exe

# Test output
*.out
*.log

# CMake files
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
Makefile

# sccache
.sccache/

# clang-tidy database
compile_commands.json
GITIGNORE

    # Add initial files to git
    git add .
    git commit -m "Initial project setup with AI workflow

- Created basic C++ project structure
- Added AI workflow integration (.github/workflows/ai-workflow.yaml)
- Included source files, tests, and CMake configuration
- Added code formatting configurations (.clang-format, .clang-tidy)
- Set up .gitignore for C++ development

🤖 Generated with C++ development tools setup
    "

    # Copy global configurations to project
    if [ -f ~/.clang-format ]; then
        cp ~/.clang-format .
    fi
    if [ -f ~/.clang-tidy ]; then
        cp ~/.clang-tidy .
    fi

    # Create project-specific .clang-tidy for test project
    cat > .clang-tidy << 'CLANG_TIDY_CONFIG'
# clang-tidy configuration for test project
Checks: >
  *,
  -fuchsia-*,
  -google-*,
  -llvm-*,
  -modernize-use-trailing-return-type,
  -readability-magic-numbers,
  -cppcoreguidelines-avoid-magic-numbers,
  -clang-diagnostic-error

WarningsAsErrors: ''
HeaderFilterRegex: '.*'

CheckOptions:
  - key: readability-identifier-naming.ClassCase
    value: CamelCase
  - key: readability-identifier-naming.FunctionCase
    value: camelBack
  - key: readability-identifier-naming.VariableCase
    value: lower_case
  - key: readability-identifier-naming.ConstantCase
    value: UPPER_CASE
CLANG_TIDY_CONFIG

    echo "Test project created at $TEST_DIR"

    echo -e "${GREEN}✅ C++ test project created${NC}"
}

create_python_test_project() {
    echo -e "${GREEN}Creating test Python project to verify installation...${NC}"

    TEST_DIR="/tmp/python-test-project"

    # Create test project
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"

    # Create simple Python package
    mkdir -p src/test_project tests .github/workflows

    # Create __init__.py
    echo '"""Test project."""' > src/test_project/__init__.py

    # Create simple module
    cat > src/test_project/main.py << 'PY_FILE'
def hello(name: str) -> str:
    """Return a greeting message."""
    return f"Hello, {name}!"

def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b
PY_FILE

    # Create test file
    cat > tests/test_main.py << 'PY_TEST'
from test_project.main import hello, add

def test_hello() -> None:
    assert hello("World") == "Hello, World!"

def test_add() -> None:
    assert add(2, 3) == 5
    assert add(-1, 1) == 0
PY_TEST

    # Create pyproject.toml
    cat > pyproject.toml << 'PYPROJECT'
[build-system]
requires = ["setuptools>=68.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "test-project"
version = "0.1.0"
description = "Test project for runner validation"
authors = [{name = "Test User"}]
requires-python = ">=3.10"

[project.optional-dependencies]
dev = [
    "pytest>=7.4",
    "pytest-cov>=4.1",
    "ruff>=0.6.0",
    "mypy>=1.11",
]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]

[tool.ruff]
target-version = "py310"
line-length = 88

[tool.mypy]
python_version = "3.10"
strict = true
PYPROJECT

    # Copy AI workflow from template
    if [ -d ~/.config/templates/python/.github/workflows ]; then
        cp ~/.config/templates/python/.github/workflows/ai-workflow.yaml .github/workflows/
    fi

    # Copy HIVE_CLAUDE.md as CLAUDE.md to project root
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TEMPLATE_ROOT="$(dirname "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")")"
    HIVE_CLAUDE_SOURCE="$TEMPLATE_ROOT/docs/HIVE_CLAUDE.md"

    if [ -f "$HIVE_CLAUDE_SOURCE" ]; then
        cp "$HIVE_CLAUDE_SOURCE" CLAUDE.md
        echo "Copied HIVE_CLAUDE.md as CLAUDE.md to project root"
    else
        echo "Warning: HIVE_CLAUDE.md not found at $HIVE_CLAUDE_SOURCE"
    fi

    # Initialize git repository
    echo "Initializing git repository..."
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"

    # Create .gitignore
    cat > .gitignore << 'GITIGNORE'
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
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.py,cover
.hypothesis/
.pytest_cache/
cover/

# Translations
*.mo
*.pot

# Django stuff:
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal

# Flask stuff:
instance/
.webassets-cache

# Scrapy stuff:
.scrapy

# Sphinx documentation
docs/_build/

# PyBuilder
.pybuilder/
target/

# Jupyter Notebook
.ipynb_checkpoints

# IPython
profile_default/
ipython_config.py

# pyenv
.python-version

# pipenv
Pipfile.lock

# poetry
poetry.lock

# pdm
.pdm.toml

# PEP 582
__pypackages__/

# Celery stuff
celerybeat-schedule
celerybeat.pid

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

# Pyre type checker
.pyre/

# pytype static type analyzer
.pytype/

# Cython debug symbols
cython_debug/

# PyCharm
.idea/

# VS Code
.vscode/
GITIGNORE

    # Add initial files to git
    git add .
    git commit -m "Initial project setup with AI workflow

- Created basic Python project structure
- Added AI workflow integration (.github/workflows/ai-workflow.yaml)
- Included source files, tests, and pyproject.toml configuration
- Set up .gitignore for Python development
- Configured ruff, pytest, and mypy

🤖 Generated with Python development tools setup
    "

    echo "Test project created at $TEST_DIR"

    echo -e "${GREEN}✅ Python test project created${NC}"
}

main() {
    case "${1:-}" in
        --cpp-only)
            create_cpp_test_project
            ;;
        --python-only)
            create_python_test_project
            ;;
        *)
            create_cpp_test_project
            create_python_test_project
            ;;
    esac
}

main "$@"