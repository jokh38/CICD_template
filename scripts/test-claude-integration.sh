#!/bin/bash
# CLAUDE.md Integration Test Script
# Creates test projects and validates CLAUDE.md integration

set -e

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_UTILS="$SCRIPT_DIR/lib/common-utils.sh"

if [ -f "$COMMON_UTILS" ]; then
    source "$COMMON_UTILS"
else
    echo "Error: Cannot find common-utils.sh at $COMMON_UTILS"
    exit 1
fi

# Configuration
TEMPLATE_DIR="$(pwd)"
TEST_DIR="/tmp/claude-integration-test"
PYTHON_PROJECT_NAME="test-python-project"
CPP_PROJECT_NAME="test-cpp-project"


# Function to cleanup test directory
cleanup() {
    if [[ -d "$TEST_DIR" ]]; then
        print_status "🧹 Cleaning up test directory..."
        rm -rf "$TEST_DIR"
    fi
}

# Function to setup test environment
setup_test_env() {
    print_status "🔧 Setting up test environment..."

    # Create test directory
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"

    print_success "✅ Test directory created: $TEST_DIR"
}

# Function to test Python project creation
test_python_project() {
    print_status "🐍 Testing Python project creation..."

    cd "$TEST_DIR"

    # Create Python project using cookiecutter
    print_status "   Creating Python project..."
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
        print_error "❌ Python project creation failed"
        return 1
    fi

    print_success "✅ Python project created successfully"

    # Validate the created project
    cd "$PYTHON_PROJECT_NAME"

    # Run validation script
    if [[ -f "$TEMPLATE_DIR/scripts/validate-claude-integration.sh" ]]; then
        print_status "   Running validation script..."
        "$TEMPLATE_DIR/scripts/validate-claude-integration.sh" . python
        validation_result=$?

        if [[ $validation_result -eq 0 ]]; then
            print_success "✅ Python project validation passed"
        else
            print_error "❌ Python project validation failed"
            return 1
        fi
    else
        print_warning "⚠️  Validation script not found"
    fi

    # Manual checks
    print_status "   Performing manual checks..."

    # Check CLAUDE.md content
    if [[ -f ".github/claude/CLAUDE.md" ]]; then
        print_success "✅ CLAUDE.md exists"

        # Check for actual project name (not template variable)
        if grep -q "$PYTHON_PROJECT_NAME" ".github/claude/CLAUDE.md"; then
            print_success "✅ Project name properly inserted"
        else
            print_error "❌ Project name not found in CLAUDE.md"
            return 1
        fi

        # Check for Python version
        if grep -q "Python 3.10" ".github/claude/CLAUDE.md"; then
            print_success "✅ Python version properly inserted"
        else
            print_error "❌ Python version not found in CLAUDE.md"
            return 1
        fi

        # Check that template variables are replaced
        if grep -q "{{cookiecutter" ".github/claude/CLAUDE.md"; then
            print_error "❌ Template variables not replaced"
            return 1
        else
            print_success "✅ Template variables properly replaced"
        fi
    else
        print_error "❌ CLAUDE.md not found"
        return 1
    fi

    # Check AI workflow
    if [[ -f ".github/workflows/ai-workflow.yaml" ]]; then
        print_success "✅ AI workflow exists"

        # Check for Haiku model
        if grep -q "haiku" ".github/workflows/ai-workflow.yaml"; then
            print_success "✅ Uses Haiku model"
        else
            print_warning "⚠️  Haiku model not specified"
        fi

        # Check for CLAUDE.md reference
        if grep -q "CLAUDE.md" ".github/workflows/ai-workflow.yaml"; then
            print_success "✅ References CLAUDE.md"
        else
            print_warning "⚠️  Does not reference CLAUDE.md"
        fi
    else
        print_error "❌ AI workflow not found"
        return 1
    fi

    cd "$TEST_DIR"
    return 0
}

# Function to test C++ project creation
test_cpp_project() {
    print_status "🔧 Testing C++ project creation..."

    cd "$TEST_DIR"

    # Create C++ project using cookiecutter
    print_status "   Creating C++ project..."
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
        print_error "❌ C++ project creation failed"
        return 1
    fi

    print_success "✅ C++ project created successfully"

    # Validate the created project
    cd "$CPP_PROJECT_NAME"

    # Run validation script
    if [[ -f "$TEMPLATE_DIR/scripts/validate-claude-integration.sh" ]]; then
        print_status "   Running validation script..."
        "$TEMPLATE_DIR/scripts/validate-claude-integration.sh" . cpp
        validation_result=$?

        if [[ $validation_result -eq 0 ]]; then
            print_success "✅ C++ project validation passed"
        else
            print_error "❌ C++ project validation failed"
            return 1
        fi
    else
        print_warning "⚠️  Validation script not found"
    fi

    # Manual checks
    print_status "   Performing manual checks..."

    # Check CLAUDE.md content
    if [[ -f ".github/claude/CLAUDE.md" ]]; then
        print_success "✅ CLAUDE.md exists"

        # Check for actual project name (not template variable)
        if grep -q "$CPP_PROJECT_NAME" ".github/claude/CLAUDE.md"; then
            print_success "✅ Project name properly inserted"
        else
            print_error "❌ Project name not found in CLAUDE.md"
            return 1
        fi

        # Check for C++ standard
        if grep -q "C++17" ".github/claude/CLAUDE.md"; then
            print_success "✅ C++ standard properly inserted"
        else
            print_error "❌ C++ standard not found in CLAUDE.md"
            return 1
        fi

        # Check that template variables are replaced
        if grep -q "{{cookiecutter" ".github/claude/CLAUDE.md"; then
            print_error "❌ Template variables not replaced"
            return 1
        else
            print_success "✅ Template variables properly replaced"
        fi
    else
        print_error "❌ CLAUDE.md not found"
        return 1
    fi

    # Check AI workflow
    if [[ -f ".github/workflows/ai-workflow.yaml" ]]; then
        print_success "✅ AI workflow exists"

        # Check for Haiku model
        if grep -q "haiku" ".github/workflows/ai-workflow.yaml"; then
            print_success "✅ Uses Haiku model"
        else
            print_warning "⚠️  Haiku model not specified"
        fi

        # Check for CLAUDE.md reference
        if grep -q "CLAUDE.md" ".github/workflows/ai-workflow.yaml"; then
            print_success "✅ References CLAUDE.md"
        else
            print_warning "⚠️  Does not reference CLAUDE.md"
        fi
    else
        print_error "❌ AI workflow not found"
        return 1
    fi

    cd "$TEST_DIR"
    return 0
}

# Function to test AI command parsing
test_ai_commands() {
    print_status "🤖 Testing AI command parsing..."

    # Test command extraction regex (from workflow)
    local test_commands=(
        "/claude add-feature Add user authentication"
        "/claude fix-issue Fix memory leak in module"
        "/claude refactor-code Improve performance of algorithm"
    )

    for cmd in "${test_commands[@]}"; do
        print_status "   Testing: $cmd"

        if [[ $cmd =~ \/claude\ (add-feature|fix-issue|refactor-code)(.*) ]]; then
            local command="${BASH_REMATCH[1]}"
            local description="${BASH_REMATCH[2]}"

            print_success "      ✅ Command: $command"
            print_success "      ✅ Description: $description"
        else
            print_error "      ❌ Failed to parse command"
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

    print_status "📊 Test Results Summary"
    print_status "======================="
    echo

    print_status "Python Project Test:"
    if [[ $python_result -eq 0 ]]; then
        print_success "   ✅ PASSED"
    else
        print_error "   ❌ FAILED"
    fi
    echo

    print_status "C++ Project Test:"
    if [[ $cpp_result -eq 0 ]]; then
        print_success "   ✅ PASSED"
    else
        print_error "   ❌ FAILED"
    fi
    echo

    print_status "AI Command Parsing Test:"
    if [[ $command_result -eq 0 ]]; then
        print_success "   ✅ PASSED"
    else
        print_error "   ❌ FAILED"
    fi
    echo

    # Overall result
    local overall_result=$((python_result + cpp_result + command_result))
    if [[ $overall_result -eq 0 ]]; then
        print_success "🎉 ALL TESTS PASSED!"
        print_success "✅ CLAUDE.md integration is working correctly"
        echo
        print_status "📋 Test projects created in: $TEST_DIR"
        print_status "   - $PYTHON_PROJECT_NAME (Python project)"
        print_status "   - $CPP_PROJECT_NAME (C++ project)"
        echo
        print_status "💡 You can examine these test projects to verify the integration:"
        print_status "   cd $TEST_DIR/$PYTHON_PROJECT_NAME && cat .github/claude/CLAUDE.md"
        print_status "   cd $TEST_DIR/$CPP_PROJECT_NAME && cat .github/claude/CLAUDE.md"
    else
        print_error "❌ SOME TESTS FAILED"
        print_error "Please check the errors above"
        return 1
    fi
}

# Main test function
main() {
    local keep_test_files=${1:-false}

    print_status "🧪 CLAUDE.md Integration Test Suite"
    print_status "=================================="
    print_status "Template directory: $TEMPLATE_DIR"
    print_status "Test directory: $TEST_DIR"
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
        print_status "📁 Test files kept in: $TEST_DIR"
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