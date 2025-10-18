#!/bin/bash
# CLAUDE.md Integration Validation Script
# Validates that CLAUDE.md template integration is working correctly

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

# Function to check if file exists and validate content
validate_claude_md() {
    local file_path=$1
    local project_type=$2

    print_status "🔍 Validating $file_path..."

    if [[ ! -f "$file_path" ]]; then
        print_error "❌ CLAUDE.md not found at $file_path"
        return 1
    fi

    print_success "✅ CLAUDE.md found at $file_path"

    # Check for cookiecutter template variables (should be replaced)
    if grep -q "{{cookiecutter" "$file_path"; then
        print_error "❌ Cookiecutter template variables not replaced"
        grep "{{cookiecutter" "$file_path" | head -3
        return 1
    else
        print_success "✅ Cookiecutter template variables properly replaced"
    fi

    # Validate project-specific content
    case $project_type in
        "python")
            if grep -q "Python 3." "$file_path"; then
                print_success "✅ Python version information present"
            else
                print_warning "⚠️  Python version information not found"
            fi
            ;;
        "cpp")
            if grep -q "C++" "$file_path"; then
                print_success "✅ C++ standard information present"
            else
                print_warning "⚠️  C++ standard information not found"
            fi
            ;;
    esac

    # Check for AI workflow content
    if grep -q "AI AUTOMATED PR CREATION WORKFLOW" "$file_path"; then
        print_success "✅ AI workflow guidelines present"
    else
        print_warning "⚠️  AI workflow guidelines not found"
    fi

    # Check for command protocol
    if grep -q "/claude" "$file_path"; then
        print_success "✅ AI command protocol present"
    else
        print_warning "⚠️  AI command protocol not found"
    fi

    return 0
}

# Function to validate GitHub Actions workflow
validate_workflow() {
    local workflow_path=$1

    print_status "🔍 Validating workflow $workflow_path..."

    if [[ ! -f "$workflow_path" ]]; then
        print_warning "⚠️  Workflow not found: $workflow_path"
        return 0
    fi

    # Check if workflow references CLAUDE.md
    if grep -q "CLAUDE.md" "$workflow_path"; then
        print_success "✅ Workflow references CLAUDE.md"
    else
        print_warning "⚠️  Workflow does not reference CLAUDE.md"
    fi

    # Check for Haiku model usage
    if grep -q "haiku" "$workflow_path"; then
        print_success "✅ Uses Haiku model for efficiency"
    else
        print_warning "⚠️  Does not specify Haiku model"
    fi

    return 0
}

# Function to validate directory structure
validate_directory_structure() {
    local project_root=$1

    print_status "🔍 Validating directory structure..."

    local required_dirs=(".github" ".github/claude" ".github/workflows")

    for dir in "${required_dirs[@]}"; do
        if [[ -d "$project_root/$dir" ]]; then
            print_success "✅ Directory exists: $dir"
        else
            print_error "❌ Directory missing: $dir"
            return 1
        fi
    done

    return 0
}

# Function to simulate AI command extraction
validate_command_extraction() {
    local test_string="/claude add-feature Add user authentication system"

    print_status "🔍 Testing AI command extraction logic..."

    # Simulate the regex pattern from the workflow
    if [[ $test_string =~ \/claude\ (add-feature|fix-issue|refactor-code)(.*) ]]; then
        local command="${BASH_REMATCH[1]}"
        local description="${BASH_REMATCH[2]}"

        print_success "✅ Command extraction working"
        print_status "   Extracted command: $command"
        print_status "   Extracted description: $description"

        if [[ "$command" == "add-feature" ]]; then
            print_success "✅ Correct command type identified"
        else
            print_error "❌ Incorrect command type: $command"
            return 1
        fi
    else
        print_error "❌ Command extraction failed"
        return 1
    fi

    return 0
}

# Main validation function
main() {
    local project_root="${1:-.}"
    local project_type="${2:-auto}"

    print_status "🚀 CLAUDE.md Integration Validation"
    print_status "====================================="

    cd "$project_root"

    # Auto-detect project type if not specified
    if [[ "$project_type" == "auto" ]]; then
        if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
            project_type="python"
        elif [[ -f "CMakeLists.txt" ]] || [[ -f "meson.build" ]]; then
            project_type="cpp"
        else
            print_warning "⚠️  Could not auto-detect project type, defaulting to python"
            project_type="python"
        fi
    fi

    print_status "📁 Project root: $(pwd)"
    print_status "🔧 Project type: $project_type"
    echo

    # Run validations
    local exit_code=0

    # Validate directory structure
    if ! validate_directory_structure "."; then
        exit_code=1
    fi
    echo

    # Validate CLAUDE.md file
    if ! validate_claude_md ".github/claude/CLAUDE.md" "$project_type"; then
        exit_code=1
    fi
    echo

    # Validate GitHub Actions workflow
    validate_workflow ".github/workflows/ai-workflow.yaml"
    echo

    # Test command extraction
    if ! validate_command_extraction; then
        exit_code=1
    fi
    echo

    # Summary
    if [[ $exit_code -eq 0 ]]; then
        print_success "🎉 All validations passed!"
        print_success "✅ CLAUDE.md integration is working correctly"
        echo
        print_status "📋 Next steps:"
        print_status "1. Test AI commands: echo '/claude add-feature Test feature'"
        print_status "2. Check Claude Code CLI: claude --model haiku --help"
        print_status "3. Review .github/claude/CLAUDE.md for project context"
    else
        print_error "❌ Some validations failed"
        print_error "Please check the errors above and fix them"
    fi

    return $exit_code
}

# Help function
show_help() {
    echo "CLAUDE.md Integration Validation Script"
    echo
    echo "Usage: $0 [project_root] [project_type]"
    echo
    echo "Arguments:"
    echo "  project_root    Path to project directory (default: current directory)"
    echo "  project_type    Project type: python, cpp, or auto (default: auto)"
    echo
    echo "Examples:"
    echo "  $0"
    echo "  $0 /path/to/project python"
    echo "  $0 . cpp"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac