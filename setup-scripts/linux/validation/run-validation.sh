#!/bin/bash
# Validation Tests for All Tools

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

RUNNER_USER="github-runner"

validate_cpp_tools() {
    echo -e "${GREEN}Running C++ tools validation...${NC}"

    TEST_DIR="/tmp/cpp-test-project"

    if [ ! -d "$TEST_DIR" ]; then
        echo -e "${RED}C++ test project not found. Run create-test-projects.sh first.${NC}"
        return 1
    fi

    # Configure and build project
    cd $TEST_DIR && cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
    cd $TEST_DIR && cmake --build build

    # Run tests
    cd $TEST_DIR && ctest --test-dir build --output-on-failure

    # Test sccache
    echo "Testing sccache..."
    cd $TEST_DIR && sccache --zero-stats && cmake --build build --clean-first && sccache --show-stats

    # Test formatting (dry run)
    echo "Testing clang-format..."
    cd $TEST_DIR && clang-format --dry-run --Werror src/*.cpp src/*.hpp tests/*.cpp

    # Test clang-tidy
    echo "Testing clang-tidy..."
    cd $TEST_DIR && run-clang-tidy -p build src/*.cpp tests/*.cpp

    echo -e "${GREEN}✅ C++ validation tests passed${NC}"
}

validate_python_tools() {
    echo -e "${GREEN}Running Python tools validation...${NC}"

    TEST_DIR="/tmp/python-test-project"

    if [ ! -d "$TEST_DIR" ]; then
        echo -e "${RED}Python test project not found. Run create-test-projects.sh first.${NC}"
        return 1
    fi

    # Test ruff
    echo "Testing ruff..."
    cd $TEST_DIR && python3 -m ruff check .
    cd $TEST_DIR && python3 -m ruff format --check .

    # Test pytest
    echo "Testing pytest..."
    cd $TEST_DIR && python3 -m pytest tests/ -v

    # Test mypy
    echo "Testing mypy..."
    cd $TEST_DIR && python3 -m mypy .

    echo -e "${GREEN}✅ Python validation tests passed${NC}"
}

validate_system_tools() {
    echo -e "${GREEN}Running system tools validation...${NC}"

    # Test compilers
    echo "Testing compilers..."
    gcc --version
    g++ --version
    clang --version
    clang++ --version

    # Test build tools
    echo "Testing build tools..."
    cmake --version
    ninja --version

    # Test sccache
    echo "Testing sccache..."
    if command -v sccache &> /dev/null; then
        sccache --version
    else
        echo -e "${YELLOW}⚠️ sccache not found${NC}"
    fi

    # Test Python tools
    echo "Testing Python tools..."
    python3 --version
    if python3 -m ruff --version &> /dev/null; then
        python3 -m ruff --version
    else
        echo -e "${YELLOW}⚠️ ruff not found${NC}"
    fi

    if python3 -m pytest --version &> /dev/null; then
        python3 -m pytest --version
    else
        echo -e "${YELLOW}⚠️ pytest not found${NC}"
    fi

    echo -e "${GREEN}✅ System tools validation passed${NC}"
}

cleanup_test_projects() {
    echo -e "${GREEN}Cleaning up test projects...${NC}"

    if [ -d "/tmp/cpp-test-project" ]; then
        rm -rf "/tmp/cpp-test-project"
    fi

    if [ -d "/tmp/python-test-project" ]; then
        rm -rf "/tmp/python-test-project"
    fi

    echo -e "${GREEN}✅ Test projects cleaned up${NC}"
}

print_summary() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✅ Validation complete!${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo "All tools have been validated successfully."
    echo "The runner is ready for C++ and Python development."
}

main() {
    case "${1:-}" in
        --cpp-only)
            validate_cpp_tools
            ;;
        --python-only)
            validate_python_tools
            ;;
        --system-only)
            validate_system_tools
            ;;
        --cleanup)
            cleanup_test_projects
            ;;
        *)
            validate_system_tools
            validate_cpp_tools
            validate_python_tools
            print_summary
            ;;
    esac
}

main "$@"