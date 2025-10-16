#!/bin/bash
# CLAUDE.md Integration Test Script
# Creates test projects and validates CLAUDE.md integration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEMPLATE_DIR="$(pwd)"
TEST_DIR="/tmp/claude-integration-test"
PYTHON_PROJECT_NAME="test-python-project"
CPP_PROJECT_NAME="test-cpp-project"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to cleanup test directory
cleanup() {
    if [[ -d "$TEST_DIR" ]]; then
        print_status $BLUE "🧹 Cleaning up test directory..."
        rm -rf "$TEST_DIR"
    fi
}

# Function to setup test environment
setup_test_env() {
    print_status $BLUE "🔧 Setting up test environment..."

    # Create test directory
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"

    print_status $GREEN "✅ Test directory created: $TEST_DIR"
}

# Function to test Python project creation
test_python_project() {
    print_status $BLUE "🐍 Testing Python project creation..."

    cd "$TEST_DIR"

    # Create Python project using cookiecutter
    print_status $BLUE "   Creating Python project..."
    cookiecutter "$TEMPLATE_DIR/cookiecutters/python-project" \
        --no-input \
        project_name="$PYTHON_PROJECT_NAME" \
        project_description="A test Python project for CLAUDE.md integration" \
        project_slug="test-python-project" \
        python_version="3.10" \
        author_name="Test Author" \
        author_email="test@example.com" \
        license="MIT" \
        use_ai_workflow="yes" \
        runner_type="github-hosted" \
        include_docker="no"

    if [[ ! -d "$PYTHON_PROJECT_NAME" ]]; then
        print_status $RED "❌ Python project creation failed"
        return 1
    fi

    print_status $GREEN "✅ Python project created successfully"

    # Validate the created project
    cd "$PYTHON_PROJECT_NAME"

    # Run validation script
    if [[ -f "$TEMPLATE_DIR/scripts/validate-claude-integration.sh" ]]; then
        print_status $BLUE "   Running validation script..."
        "$TEMPLATE_DIR/scripts/validate-claude-integration.sh" . python
        validation_result=$?

        if [[ $validation_result -eq 0 ]]; then
            print_status $GREEN "✅ Python project validation passed"
        else
            print_status $RED "❌ Python project validation failed"
            return 1
        fi
    else
        print_status $YELLOW "⚠️  Validation script not found"
    fi

    # Manual checks
    print_status $BLUE "   Performing manual checks..."

    # Check CLAUDE.md content
    if [[ -f ".github/claude/CLAUDE.md" ]]; then
        print_status $GREEN "✅ CLAUDE.md exists"

        # Check for actual project name (not template variable)
        if grep -q "$PYTHON_PROJECT_NAME" ".github/claude/CLAUDE.md"; then
            print_status $GREEN "✅ Project name properly inserted"
        else
            print_status $RED "❌ Project name not found in CLAUDE.md"
            return 1
        fi

        # Check for Python version
        if grep -q "Python 3.10" ".github/claude/CLAUDE.md"; then
            print_status $GREEN "✅ Python version properly inserted"
        else
            print_status $RED "❌ Python version not found in CLAUDE.md"
            return 1
        fi

        # Check that template variables are replaced
        if grep -q "{{cookiecutter" ".github/claude/CLAUDE.md"; then
            print_status $RED "❌ Template variables not replaced"
            return 1
        else
            print_status $GREEN "✅ Template variables properly replaced"
        fi
    else
        print_status $RED "❌ CLAUDE.md not found"
        return 1
    fi

    # Check AI workflow
    if [[ -f ".github/workflows/ai-workflow.yaml" ]]; then
        print_status $GREEN "✅ AI workflow exists"

        # Check for Haiku model
        if grep -q "haiku" ".github/workflows/ai-workflow.yaml"; then
            print_status $GREEN "✅ Uses Haiku model"
        else
            print_status $YELLOW "⚠️  Haiku model not specified"
        fi

        # Check for CLAUDE.md reference
        if grep -q "CLAUDE.md" ".github/workflows/ai-workflow.yaml"; then
            print_status $GREEN "✅ References CLAUDE.md"
        else
            print_status $YELLOW "⚠️  Does not reference CLAUDE.md"
        fi
    else
        print_status $RED "❌ AI workflow not found"
        return 1
    fi

    cd "$TEST_DIR"
    return 0
}

# Function to test C++ project creation
test_cpp_project() {
    print_status $BLUE "🔧 Testing C++ project creation..."

    cd "$TEST_DIR"

    # Create C++ project using cookiecutter
    print_status $BLUE "   Creating C++ project..."
    cookiecutter "$TEMPLATE_DIR/cookiecutters/cpp-project" \
        --no-input \
        project_name="$CPP_PROJECT_NAME" \
        project_description="A test C++ project for CLAUDE.md integration" \
        project_slug="test-cpp-project" \
        cpp_standard="17" \
        build_system="cmake" \
        testing_framework="gtest" \
        use_ninja="yes" \
        license="MIT" \
        use_ai_workflow="yes" \
        runner_type="self-hosted" \
        enable_cache="yes"

    if [[ ! -d "$CPP_PROJECT_NAME" ]]; then
        print_status $RED "❌ C++ project creation failed"
        return 1
    fi

    print_status $GREEN "✅ C++ project created successfully"

    # Validate the created project
    cd "$CPP_PROJECT_NAME"

    # Run validation script
    if [[ -f "$TEMPLATE_DIR/scripts/validate-claude-integration.sh" ]]; then
        print_status $BLUE "   Running validation script..."
        "$TEMPLATE_DIR/scripts/validate-claude-integration.sh" . cpp
        validation_result=$?

        if [[ $validation_result -eq 0 ]]; then
            print_status $GREEN "✅ C++ project validation passed"
        else
            print_status $RED "❌ C++ project validation failed"
            return 1
        fi
    else
        print_status $YELLOW "⚠️  Validation script not found"
    fi

    # Manual checks
    print_status $BLUE "   Performing manual checks..."

    # Check CLAUDE.md content
    if [[ -f ".github/claude/CLAUDE.md" ]]; then
        print_status $GREEN "✅ CLAUDE.md exists"

        # Check for actual project name (not template variable)
        if grep -q "$CPP_PROJECT_NAME" ".github/claude/CLAUDE.md"; then
            print_status $GREEN "✅ Project name properly inserted"
        else
            print_status $RED "❌ Project name not found in CLAUDE.md"
            return 1
        fi

        # Check for C++ standard
        if grep -q "C++17" ".github/claude/CLAUDE.md"; then
            print_status $GREEN "✅ C++ standard properly inserted"
        else
            print_status $RED "❌ C++ standard not found in CLAUDE.md"
            return 1
        fi

        # Check that template variables are replaced
        if grep -q "{{cookiecutter" ".github/claude/CLAUDE.md"; then
            print_status $RED "❌ Template variables not replaced"
            return 1
        else
            print_status $GREEN "✅ Template variables properly replaced"
        fi
    else
        print_status $RED "❌ CLAUDE.md not found"
        return 1
    fi

    # Check AI workflow
    if [[ -f ".github/workflows/ai-workflow.yaml" ]]; then
        print_status $GREEN "✅ AI workflow exists"

        # Check for Haiku model
        if grep -q "haiku" ".github/workflows/ai-workflow.yaml"; then
            print_status $GREEN "✅ Uses Haiku model"
        else
            print_status $YELLOW "⚠️  Haiku model not specified"
        fi

        # Check for CLAUDE.md reference
        if grep -q "CLAUDE.md" ".github/workflows/ai-workflow.yaml"; then
            print_status $GREEN "✅ References CLAUDE.md"
        else
            print_status $YELLOW "⚠️  Does not reference CLAUDE.md"
        fi
    else
        print_status $RED "❌ AI workflow not found"
        return 1
    fi

    cd "$TEST_DIR"
    return 0
}

# Function to test AI command parsing
test_ai_commands() {
    print_status $BLUE "🤖 Testing AI command parsing..."

    # Test command extraction regex (from workflow)
    local test_commands=(
        "/claude add-feature Add user authentication"
        "/claude fix-issue Fix memory leak in module"
        "/claude refactor-code Improve performance of algorithm"
    )

    for cmd in "${test_commands[@]}"; do
        print_status $BLUE "   Testing: $cmd"

        if [[ $cmd =~ \/claude\ (add-feature|fix-issue|refactor-code)(.*) ]]; then
            local command="${BASH_REMATCH[1]}"
            local description="${BASH_REMATCH[2]}"

            print_status $GREEN "      ✅ Command: $command"
            print_status $GREEN "      ✅ Description: $description"
        else
            print_status $RED "      ❌ Failed to parse command"
            return 1
        fi
    done

    return 0
}

# Function to show test results summary
show_summary() {
    local python_result=$1
    local cpp_result=$2
    local command_result=$3

    print_status $BLUE "📊 Test Results Summary"
    print_status $BLUE "======================="
    echo

    print_status $BLUE "Python Project Test:"
    if [[ $python_result -eq 0 ]]; then
        print_status $GREEN "   ✅ PASSED"
    else
        print_status $RED "   ❌ FAILED"
    fi
    echo

    print_status $BLUE "C++ Project Test:"
    if [[ $cpp_result -eq 0 ]]; then
        print_status $GREEN "   ✅ PASSED"
    else
        print_status $RED "   ❌ FAILED"
    fi
    echo

    print_status $BLUE "AI Command Parsing Test:"
    if [[ $command_result -eq 0 ]]; then
        print_status $GREEN "   ✅ PASSED"
    else
        print_status $RED "   ❌ FAILED"
    fi
    echo

    # Overall result
    local overall_result=$((python_result + cpp_result + command_result))
    if [[ $overall_result -eq 0 ]]; then
        print_status $GREEN "🎉 ALL TESTS PASSED!"
        print_status $GREEN "✅ CLAUDE.md integration is working correctly"
        echo
        print_status $BLUE "📋 Test projects created in: $TEST_DIR"
        print_status $BLUE "   - $PYTHON_PROJECT_NAME (Python project)"
        print_status $BLUE "   - $CPP_PROJECT_NAME (C++ project)"
        echo
        print_status $BLUE "💡 You can examine these test projects to verify the integration:"
        print_status $BLUE "   cd $TEST_DIR/$PYTHON_PROJECT_NAME && cat .github/claude/CLAUDE.md"
        print_status $BLUE "   cd $TEST_DIR/$CPP_PROJECT_NAME && cat .github/claude/CLAUDE.md"
    else
        print_status $RED "❌ SOME TESTS FAILED"
        print_status $RED "Please check the errors above"
        return 1
    fi
}

# Main test function
main() {
    local keep_test_files=${1:-false}

    print_status $BLUE "🧪 CLAUDE.md Integration Test Suite"
    print_status $BLUE "=================================="
    print_status $BLUE "Template directory: $TEMPLATE_DIR"
    print_status $BLUE "Test directory: $TEST_DIR"
    echo

    # Setup test environment
    setup_test_env

    # Run tests
    local python_result=0
    local cpp_result=0
    local command_result=0

    # Test Python project
    if ! test_python_project; then
        python_result=1
    fi
    echo

    # Test C++ project
    if ! test_cpp_project; then
        cpp_result=1
    fi
    echo

    # Test AI command parsing
    if ! test_ai_commands; then
        command_result=1
    fi
    echo

    # Show summary
    show_summary $python_result $cpp_result $command_result

    local overall_result=$((python_result + cpp_result + command_result))

    # Cleanup unless user wants to keep files
    if [[ "$keep_test_files" != "true" ]]; then
        cleanup
    else
        print_status $BLUE "📁 Test files kept in: $TEST_DIR"
    fi

    return $overall_result
}

# Help function
show_help() {
    echo "CLAUDE.md Integration Test Script"
    echo
    echo "Usage: $0 [--keep-files]"
    echo
    echo "Options:"
    echo "  --keep-files    Keep test files for inspection"
    echo
    echo "This script creates test projects and validates CLAUDE.md integration."
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    --keep-files)
        main true
        ;;
    *)
        main false
        ;;
esac