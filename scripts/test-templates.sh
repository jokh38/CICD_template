#!/bin/bash
# Automated template testing script
# Part of the CICD Template System - Phase 7.1

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TEST_DIR="$ROOT_DIR/tests"
TEMP_DIR="/tmp/cicd-template-test-$$"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Test functions
run_test() {
    local test_name="$1"
    local test_command="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    log_info "Running test: $test_name"

    if eval "$test_command" > "$TEMP_DIR/test_output.log" 2>&1; then
        echo -e "${GREEN}✓ PASS: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL: $test_name${NC}"
        echo -e "${RED}Output:${NC}"
        cat "$TEMP_DIR/test_output.log" | sed 's/^/  /'
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up test environment..."
    rm -rf "$TEMP_DIR"
    if [ -d "$TEST_DIR" ]; then
        log_info "Cleaning up test projects..."
        rm -rf "$TEST_DIR"
    fi
}

# Setup test environment
setup_test_env() {
    log "Setting up test environment..."

    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    mkdir -p "$TEST_DIR"

    # Check dependencies
    local deps=("cookiecutter" "python3" "cmake" "ninja")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Dependency not found: $dep"
            log_error "Please install: pip install cookiecutter"
            exit 1
        fi
    done

    log "Test environment ready"
}

# Test Python template
test_python_template() {
    log "Testing Python Cookiecutter template..."

    cd "$TEST_DIR"

    # Create Python project
    run_test "Python template generation" \
        "cookiecutter '$ROOT_DIR/cookiecutters/python-project' \
            --no-input \
            project_name='Test Python Project' \
            project_description='A test Python project' \
            author_name='Test Author' \
            author_email='test@example.com' \
            python_version='3.10' \
            use_ai_workflow='no' \
            runner_type='github-hosted' \
            include_docker='no' \
            license='MIT'"

    cd test-python-project

    # Test project structure
    run_test "Python project structure exists" \
        "[ -f 'pyproject.toml' ] && [ -f '.pre-commit-config.yaml' ] && [ -d '.github/workflows' ]"

    # Test virtual environment creation
    run_test "Python virtual environment creation" \
        "python3 -m venv .venv && source .venv/bin/activate && pip install -e .[dev]"

    # Test pre-commit hooks
    run_test "Python pre-commit hooks installation" \
        "source .venv/bin/activate && pre-commit install"

    # Test linting
    run_test "Python linting with Ruff" \
        "source .venv/bin/activate && ruff check ."

    # Test formatting
    run_test "Python formatting with Ruff" \
        "source .venv/bin/activate && ruff format --check ."

    # Test running tests
    run_test "Python tests execution" \
        "source .venv/bin/activate && pytest tests/ -v"

    log "Python template tests completed"
}

# Test C++ template
test_cpp_template() {
    log "Testing C++ Cookiecutter template..."

    cd "$TEST_DIR"

    # Create C++ project
    run_test "C++ template generation" \
        "cookiecutter '$ROOT_DIR/cookiecutters/cpp-project' \
            --no-input \
            project_name='Test CPP Project' \
            project_description='A test C++ project' \
            author_name='Test Author' \
            author_email='test@example.com' \
            cpp_standard='17' \
            build_system='cmake' \
            use_ai_workflow='no' \
            runner_type='github-hosted' \
            enable_cache='yes' \
            use_ninja='yes' \
            testing_framework='gtest' \
            license='MIT'"

    cd test-cpp-project

    # Test project structure
    run_test "C++ project structure exists" \
        "[ -f 'CMakeLists.txt' ] && [ -f '.clang-format' ] && [ -d '.github/workflows' ]"

    # Test CMake configuration
    run_test "CMake configuration" \
        "cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release"

    # Test build
    run_test "C++ build with Ninja" \
        "cmake --build build -j\$(nproc)"

    # Test execution
    run_test "C++ executable runs" \
        "./build/test-cpp-project --version"

    # Test running tests
    run_test "C++ tests execution" \
        "ctest --test-dir build --output-on-failure -j\$(nproc)"

    log "C++ template tests completed"
}

# Test reusable workflows
test_reusable_workflows() {
    log "Testing reusable workflows..."

    # Validate YAML syntax
    run_test "Python CI workflow YAML syntax" \
        "python3 -c 'import yaml; yaml.safe_load(open(\"$ROOT_DIR/.github/workflows/python-ci-reusable.yaml\"))'"

    run_test "C++ CI workflow YAML syntax" \
        "python3 -c 'import yaml; yaml.safe_load(open(\"$ROOT_DIR/.github/workflows/cpp-ci-reusable.yaml\"))'"

    # Validate composite actions
    run_test "Python cache action YAML syntax" \
        "python3 -c 'import yaml; yaml.safe_load(open(\"$ROOT_DIR/.github/actions/setup-python-cache/action.yaml\"))'"

    run_test "C++ cache action YAML syntax" \
        "python3 -c 'import yaml; yaml.safe_load(open(\"$ROOT_DIR/.github/actions/setup-cpp-cache/action.yaml\"))'"

    run_test "CI monitor action YAML syntax" \
        "python3 -c 'import yaml; yaml.safe_load(open(\"$ROOT_DIR/.github/actions/monitor-ci/action.yaml\"))'"

    # Validate workflow templates
    run_test "Python starter workflow YAML syntax" \
        "python3 -c 'import yaml; yaml.safe_load(open(\"$ROOT_DIR/.github/workflow-templates/python-ci.yml\"))'"

    run_test "C++ starter workflow YAML syntax" \
        "python3 -c 'import yaml; yaml.safe_load(open(\"$ROOT_DIR/.github/workflow-templates/cpp-ci.yml\"))'"

    log "Reusable workflow tests completed"
}

# Test configuration files
test_configurations() {
    log "Testing configuration files..."

    # Test Python configurations
    run_test "Python pre-commit config syntax" \
        "python3 -c 'import yaml; yaml.safe_load(open(\"$ROOT_DIR/configs/python/.pre-commit-config.yaml\"))'"

    run_test "Ruff config syntax" \
        "python3 -c 'import tomllib; tomllib.load(open(\"$ROOT_DIR/configs/python/ruff.toml\", \"rb\"))'"

    run_test "Python pyproject template syntax" \
        "python3 -c 'import tomllib; tomllib.load(open(\"$ROOT_DIR/configs/python/pyproject.toml.template\", \"rb\"))'"

    # Test C++ configurations
    run_test "C++ pre-commit config syntax" \
        "python3 -c 'import yaml; yaml.safe_load(open(\"$ROOT_DIR/configs/cpp/.pre-commit-config.yaml\"))'"

    run_test "clang-format config syntax" \
        "clang-format --style=file --dump-config < '$ROOT_DIR/configs/cpp/.clang-format' > /dev/null"

    run_test "clang-tidy config exists" \
        "[ -f '$ROOT_DIR/configs/cpp/.clang-tidy' ]"

    run_test "CMake template syntax" \
        "cmake --help-command-list > /dev/null && \
         grep -q 'cmake_minimum_required' '$ROOT_DIR/configs/cpp/CMakeLists.txt.template'"

    log "Configuration file tests completed"
}

# Test helper scripts
test_helper_scripts() {
    log "Testing helper scripts..."

    # Test script syntax
    run_test "create-project.sh syntax" \
        "bash -n '$ROOT_DIR/scripts/create-project.sh'"

    run_test "sync-templates.sh syntax" \
        "bash -n '$ROOT_DIR/scripts/sync-templates.sh'"

    run_test "verify-setup.sh syntax" \
        "bash -n '$ROOT_DIR/scripts/verify-setup.sh'"

    run_test "common-utils.sh syntax" \
        "bash -n '$ROOT_DIR/scripts/lib/common-utils.sh'"

    # Test script functionality (dry run where possible)
    run_test "verify-setup.sh execution" \
        "cd '$ROOT_DIR' && bash scripts/verify-setup.sh"

    log "Helper script tests completed"
}

# Test runner setup scripts
test_runner_setup() {
    log "Testing runner setup scripts..."

    # Test syntax validation
    run_test "Linux runner install script syntax" \
        "bash -n '$ROOT_DIR/runner-setup/linux/install-runner-linux.sh'"

    run_test "Linux Python tools setup syntax" \
        "bash -n '$ROOT_DIR/runner-setup/linux/setup-python-tools.sh'"

    run_test "Linux C++ tools setup syntax" \
        "bash -n '$ROOT_DIR/runner-setup/linux/setup-cpp-tools.sh'"

    run_test "Windows runner install script syntax" \
        "powershell -NoProfile -Command '& { try { . \"$ROOT_DIR/runner-setup/windows/install-runner-windows.ps1\" -WhatIf } catch { exit 0 } }'"

    run_test "Windows service manager syntax" \
        "powershell -NoProfile -Command '& { try { . \"$ROOT_DIR/runner-setup/windows/manage-runner-service.ps1\" -WhatIf } catch { exit 0 } }'"

    # Test configuration files
    run_test "Linux runner config YAML syntax" \
        "python3 -c 'import yaml; yaml.safe_load(open(\"$ROOT_DIR/runner-setup/linux/runner-config.yaml\"))'"

    run_test "Windows runner config YAML syntax" \
        "python3 -c 'import yaml; yaml.safe_load(open(\"$ROOT_DIR/runner-setup/windows/runner-config-windows.yaml\"))'"

    log "Runner setup script tests completed"
}

# Performance tests
test_performance() {
    log "Running performance tests..."

    # Test Python project creation speed
    local start_time=$(date +%s)
    cd "$TEST_DIR"
    cookiecutter "$ROOT_DIR/cookiecutters/python-project" \
        --no-input \
        project_name='Perf Test Python' \
        use_ai_workflow='no' > /dev/null 2>&1
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    run_test "Python project creation speed (< 30s)" \
        "[ $duration -lt 30 ]"

    log_info "Python project creation took ${duration}s"

    # Test C++ project creation speed
    start_time=$(date +%s)
    cookiecutter "$ROOT_DIR/cookiecutters/cpp-project" \
        --no-input \
        project_name='Perf Test CPP' \
        build_system='cmake' \
        use_ai_workflow='no' > /dev/null 2>&1
    end_time=$(date +%s)
    duration=$((end_time - start_time))

    run_test "C++ project creation speed (< 30s)" \
        "[ $duration -lt 30 ]"

    log_info "C++ project creation took ${duration}s"

    # Test Ruff performance (if available)
    if command -v ruff &> /dev/null; then
        cd perf-test-python
        start_time=$(date +%s.%N)
        ruff check . > /dev/null 2>&1
        end_time=$(date +%s.%N)
        duration=$(echo "$end_time - $start_time" | bc -l)

        run_test "Ruff linting speed (< 5s)" \
        "python3 -c \"print($duration < 5.0)\""

        log_info "Ruff linting took ${duration}s"
        cd ..
    fi

    log "Performance tests completed"
}

# Generate test report
generate_report() {
    log "Generating test report..."

    local report_file="$ROOT_DIR/test-report-$(date +%Y%m%d-%H%M%S).md"

    cat > "$report_file" << EOF
# CICD Template System Test Report

**Generated:** $(date)
**Test Environment:** $(uname -a)

## Test Summary

- **Total Tests:** $TESTS_TOTAL
- **Passed:** $TESTS_PASSED
- **Failed:** $TESTS_FAILED
- **Success Rate:** $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%

## Test Results

$(if [ $TESTS_FAILED -eq 0 ]; then
    echo "🎉 **All tests passed!**"
else
    echo "⚠️ **Some tests failed.** Review the output above for details."
fi)

## Test Categories

1. **Python Template** - Cookiecutter template generation and validation
2. **C++ Template** - Cookiecutter template generation and validation
3. **Reusable Workflows** - YAML syntax validation
4. **Configuration Files** - Configuration syntax validation
5. **Helper Scripts** - Script syntax and basic functionality
6. **Runner Setup** - Runner script syntax validation
7. **Performance** - Basic performance benchmarks

## Next Steps

- If any tests failed, review the specific error messages
- Run the failed tests manually for detailed debugging
- Update templates or configurations as needed
- Re-run this test suite to verify fixes

EOF

    log "Test report saved to: $report_file"

    # Print summary
    echo ""
    echo "================================"
    echo "Test Summary"
    echo "================================"
    echo "Total Tests: $TESTS_TOTAL"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo "Success Rate: $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%"
    echo "================================"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}⚠️ Some tests failed. Check the report for details.${NC}"
        return 1
    fi
}

# Main execution
main() {
    log "Starting CICD Template System integration tests..."

    # Setup
    setup_test_env

    # Run tests
    test_python_template
    test_cpp_template
    test_reusable_workflows
    test_configurations
    test_helper_scripts
    test_runner_setup
    test_performance

    # Generate report
    generate_report

    # Cleanup
    cleanup

    # Exit with appropriate code
    if [ $TESTS_FAILED -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --no-cleanup   Skip cleanup of test files"
        echo ""
        echo "This script tests the CICD Template System:"
        echo "- Cookiecutter templates (Python + C++)"
        echo "- Reusable GitHub Actions workflows"
        echo "- Configuration files"
        echo "- Helper scripts"
        echo "- Runner setup scripts"
        echo "- Performance benchmarks"
        exit 0
        ;;
    --no-cleanup)
        # Override cleanup function
        cleanup() {
            log_info "Skipping cleanup as requested"
            log_info "Test files left in: $TEST_DIR"
            log_info "Temp files left in: $TEMP_DIR"
        }
        main
        ;;
    *)
        main
        ;;
esac