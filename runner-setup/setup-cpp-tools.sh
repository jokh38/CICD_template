#!/bin/bash
# C++ Development Tools Setup for GitHub Actions Runner

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

RUNNER_USER="github-runner"
SCCACHE_VERSION="0.7.7"

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root${NC}"
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/debian_version ]; then
        OS="debian"
        echo -e "${GREEN}Detected Debian/Ubuntu system${NC}"
    elif [ -f /etc/redhat-release ]; then
        OS="redhat"
        echo -e "${GREEN}Detected RHEL/CentOS system${NC}"
    else
        echo -e "${RED}Unsupported OS${NC}"
        exit 1
    fi
}

install_system_deps() {
    echo -e "${GREEN}Installing system dependencies...${NC}"

    if [ "$OS" = "debian" ]; then
        apt-get update
        apt-get install -y \
            build-essential cmake ninja-build \
            clang clang-format clang-tidy \
            gcc g++ gdb \
            libssl-dev libffi-dev \
            curl wget git jq \
            pkg-config autoconf automake \
            libgtest-dev libbenchmark-dev
    elif [ "$OS" = "redhat" ]; then
        yum groupinstall -y "Development Tools"
        yum install -y \
            cmake ninja-build \
            clang clang-tools-extra \
            gcc gcc-c++ gdb \
            openssl-devel libffi-devel \
            curl wget git jq \
            pkgconfig autoconf automake
    fi
}

install_sccache() {
    echo -e "${GREEN}Installing sccache for compilation caching...${NC}"

    # Download and install sccache
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        SCCACHE_ARCH="x86_64-unknown-linux-musl"
    else
        echo -e "${RED}Unsupported architecture: $ARCH${NC}"
        exit 1
    fi

    curl -L "https://github.com/mozilla/sccache/releases/download/v${SCCACHE_VERSION}/sccache-v${SCCACHE_VERSION}-${SCCACHE_ARCH}.tar.gz" | tar xz

    mv "sccache-v${SCCACHE_VERSION}-${SCCACHE_ARCH}/sccache" /usr/local/bin/
    chmod +x /usr/local/bin/sccache

    # Cleanup
    rm -rf "sccache-v${SCCACHE_VERSION}-${SCCACHE_ARCH}"

    echo -e "${GREEN}✅ sccache installed${NC}"
}

configure_sccache() {
    echo -e "${GREEN}Configuring sccache for $RUNNER_USER...${NC}"

    sudo -u "$RUNNER_USER" bash <<EOF
    # Create sccache directory
    mkdir -p ~/.cache/sccache

    # Configure sccache environment variables
    cat >> ~/.bashrc << 'BASHRC_EOF'

# sccache configuration
export SCCACHE_DIR="\$HOME/.cache/sccache"
export SCCACHE_CACHE_SIZE="10G"
export SCCACHE_MAX_FRAME_FILES="10000"
export SCCACHE_IDLE_TIMEOUT="7200"
export SCCACHE_START_SERVER="1"
export SCCACHE_NO_DAEMON="0"

# CMake integration
export CMAKE_C_COMPILER_LAUNCHER="sccache"
export CMAKE_CXX_COMPILER_LAUNCHER="sccache"
BASHRC_EOF

    # Create sccache config
    mkdir -p ~/.config/sccache
    cat > ~/.config/sccache/config << 'SCCACHE_CONFIG'
[cache]
dir = "${HOME}/.cache/sccache"
size = "10G"

[server]
start_server = true
idle_timeout = 7200
max_frame_files = 10000
SCCACHE_CONFIG

    echo "sccache configured for $RUNNER_USER"
EOF

    echo -e "${GREEN}✅ sccache configuration created${NC}"
}

install_cpp_testing_frameworks() {
    echo -e "${GREEN}Installing C++ testing frameworks...${NC}"

    if [ "$OS" = "debian" ]; then
        # Google Test is already installed via libgtest-dev, but we need to build it
        cd /tmp
        apt-get source -b libgtest-dev
        dpkg -i libgtest*.deb || true
        rm -f libgtest*.deb

        # Install Catch2 v3
        cd /tmp
        git clone https://github.com/catchorg/Catch2.git
        cd Catch2
        cmake -B build -DBUILD_TESTING=OFF
        cmake --build build
        cmake --install build
        cd /tmp
        rm -rf Catch2

        # Install Google Benchmark
        cd /tmp
        git clone https://github.com/google/benchmark.git
        cd benchmark
        cmake -B build -DBENCHMARK_ENABLE_TESTING=OFF
        cmake --build build
        cmake --install build
        cd /tmp
        rm -rf benchmark
    fi

    echo -e "${GREEN}✅ C++ testing frameworks installed${NC}"
}

setup_cpp_formatters() {
    echo -e "${GREEN}Setting up C++ code formatting configurations...${NC}"

    sudo -u "$RUNNER_USER" bash <<'EOF'
    # Create .clang-format configuration
    cat > ~/.clang-format << 'CLANG_FORMAT'
# clang-format configuration
BasedOnStyle: Google
Language: Cpp
Standard: c++17

ColumnLimit: 100
IndentWidth: 4
UseTab: Never
PointerAlignment: Left
ReferenceAlignment: Left

AllowShortFunctionsOnASingleLine: Inline
AllowShortIfStatementsOnASingleLine: Never
AllowShortLoopsOnASingleLine: false

BreakBeforeBraces: Attach
IndentCaseLabels: true
SpaceAfterCStyleCast: false
SpacesInParentheses: false
Clang_FORMAT

    # Create .clang-tidy configuration
    cat > ~/.clang-tidy << 'CLANG_TIDY'
# clang-tidy configuration
Checks: >
  *,
  -fuchsia-*,
  -google-*,
  -llvm-*,
  -modernize-use-trailing-return-type,
  -readability-magic-numbers,
  -cppcoreguidelines-avoid-magic-numbers

WarningsAsErrors: '*'

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
CLANG_TIDY

    # Create CMake presets template
    mkdir -p ~/.config/cmake
    cat > ~/.config/cmake/CMakePresets.json << 'CMAKE_PRESETS'
{
  "version": 6,
  "configurePresets": [
    {
      "name": "base",
      "hidden": true,
      "toolchain": {
        "file": "${sourceDir}/cmake/toolchains/default.cmake"
      },
      "cacheVariables": {
        "CMAKE_C_COMPILER_LAUNCHER": "sccache",
        "CMAKE_CXX_COMPILER_LAUNCHER": "sccache",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
      }
    },
    {
      "name": "debug",
      "inherits": "base",
      "displayName": "Debug",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "CMAKE_DEBUG_POSTFIX": "-d"
      }
    },
    {
      "name": "release",
      "inherits": "base",
      "displayName": "Release",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release",
        "CMAKE_INTERPROCEDURAL_OPTIMIZATION": "ON"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "debug",
      "configurePreset": "debug",
      "jobs": 4
    },
    {
      "name": "release",
      "configurePreset": "release",
      "jobs": 4
    }
  ],
  "testPresets": [
    {
      "name": "debug",
      "configurePreset": "debug",
      "execution": {
        "noTestsAction": "error",
        "timeout": 300
      }
    },
    {
      "name": "release",
      "configurePreset": "release",
      "execution": {
        "noTestsAction": "error",
        "timeout": 300
      }
    }
  ]
}
CMAKE_PRESETS

    # Add C++ aliases to bashrc
    cat >> ~/.bashrc << 'BASHRC_EOF'

# C++ development aliases
alias cmake-debug='cmake --preset debug'
alias cmake-release='cmake --preset release'
alias build-debug='cmake --build --preset debug'
alias build-release='cmake --build --preset release'
alias test-debug='ctest --preset debug'
alias test-release='ctest --preset release'
alias format-clang='find . -name "*.cpp" -o -name "*.hpp" | xargs clang-format -i'
alias lint-clang='find . -name "*.cpp" -o -name "*.hpp" | xargs clang-tidy'
alias sccache-stats='sccache --show-stats'
alias sccache-zero='sccache --zero-stats'
BASHRC_EOF

    echo "C++ formatting configurations created"
EOF

    echo -e "${GREEN}✅ C++ formatting configurations created${NC}"
}

create_test_project() {
    echo -e "${GREEN}Creating test C++ project to verify installation...${NC}"

    TEST_DIR="/tmp/cpp-test-project"
    sudo -u "$RUNNER_USER" bash <<EOF
    mkdir -p "$TEST_DIR"/{src,tests,cmake}
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

# Find packages
find_package(GTest REQUIRED)

# Library
add_library(calculator_lib
    src/calculator.cpp
)

target_include_directories(calculator_lib
    PUBLIC
        \${CMAKE_CURRENT_SOURCE_DIR}/src
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

    # Copy global configurations to project
    cp ~/.clang-format .
    cp ~/.clang-tidy .

    echo "Test project created at $TEST_DIR"
EOF

    echo -e "${GREEN}✅ Test project created${NC}"
}

run_validation_tests() {
    echo -e "${GREEN}Running validation tests...${NC}"

    TEST_DIR="/tmp/cpp-test-project"

    # Configure and build project
    sudo -u "$RUNNER_USER" bash -c "cd $TEST_DIR && cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release"
    sudo -u "$RUNNER_USER" bash -c "cd $TEST_DIR && cmake --build build"

    # Run tests
    sudo -u "$RUNNER_USER" bash -c "cd $TEST_DIR && ctest --test-dir build --output-on-failure"

    # Test sccache
    echo "Testing sccache..."
    sudo -u "$RUNNER_USER" bash -c "cd $TEST_DIR && sccache --zero-stats && cmake --build build --clean-first && sccache --show-stats"

    # Test formatting (dry run)
    echo "Testing clang-format..."
    sudo -u "$RUNNER_USER" bash -c "cd $TEST_DIR && clang-format --dry-run --Werror src/*.cpp src/*.hpp tests/*.cpp"

    # Test clang-tidy
    echo "Testing clang-tidy..."
    sudo -u "$RUNNER_USER" bash -c "cd $TEST_DIR && run-clang-tidy -p build src/*.cpp tests/*.cpp"

    # Cleanup
    rm -rf "$TEST_DIR"

    echo -e "${GREEN}✅ All validation tests passed${NC}"
}

print_success() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✅ C++ tools setup complete!${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo "Installed tools:"
    echo "  - GCC/G++ compilers"
    echo "  - Clang compiler suite"
    echo "  - CMake build system"
    echo "  - Ninja build tool"
    echo "  - sccache (compilation cache)"
    echo "  - Google Test framework"
    echo "  - Catch2 framework"
    echo "  - Google Benchmark"
    echo "  - clang-format (code formatting)"
    echo "  - clang-tidy (static analysis)"
    echo ""
    echo "Global configurations created:"
    echo "  - ~/.clang-format"
    echo "  - ~/.clang-tidy"
    echo "  - ~/.config/cmake/CMakePresets.json"
    echo "  - ~/.config/sccache/config"
    echo "  - ~/.bashrc (C++ aliases added)"
    echo ""
    echo "Available aliases for $RUNNER_USER:"
    echo "  - cmake-debug    : Configure debug build"
    echo "  - cmake-release  : Configure release build"
    echo "  - build-debug    : Build debug configuration"
    echo "  - build-release  : Build release configuration"
    echo "  - test-debug     : Run debug tests"
    echo "  - test-release   : Run release tests"
    echo "  - format-clang   : Format all C++ files"
    echo "  - lint-clang     : Run clang-tidy on all C++ files"
    echo "  - sccache-stats  : Show sccache statistics"
    echo "  - sccache-zero   : Reset sccache statistics"
    echo ""
    echo "The runner is now ready for C++ projects!"
}

main() {
    case "${1:-}" in
        --validate-only)
            run_validation_tests
            ;;
        *)
            check_root
            detect_os
            install_system_deps
            install_sccache
            configure_sccache
            install_cpp_testing_frameworks
            setup_cpp_formatters
            create_test_project
            run_validation_tests
            print_success
            ;;
    esac
}

main "$@"