#!/bin/bash
# Setup GitHub Labels for CICD Template Projects
# This script creates the required labels for AI automation workflows

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common utilities
COMMON_UTILS="$SCRIPT_DIR/lib/common-utils.sh"

if [ -f "$COMMON_UTILS" ]; then
    source "$COMMON_UTILS"
else
    echo "Error: Cannot find common-utils.sh at $COMMON_UTILS"
    exit 1
fi

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "This script must be run in a git repository"
        exit 1
    fi
}

# Function to check if gh CLI is installed and authenticated
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed. Please install it first."
        echo "Install instructions: https://cli.github.com/manual/installation"
        exit 1
    fi

    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI is not authenticated. Please run 'gh auth login' first."
        exit 1
    fi
}

# Function to create a label
create_label() {
    local name="$1"
    local description="$2"
    local color="$3"

    # Check if label already exists
    if gh label list --search "$name" --limit 1 | grep -q "$name"; then
        print_status "Label '$name' already exists, skipping..."
        return 0
    fi

    # Create the label
    if gh label create "$name" --color "$color" --description "$description"; then
        print_success "Created label: $name"
    else
        print_warning "Failed to create label: $name (may already exist)"
    fi
}

# Function to create all AI automation labels
create_ai_labels() {
    print_status "Creating AI automation labels..."

    # AI & Automation Labels
    create_label "claude" "Issues and PRs related to Claude AI automation" "f1e05a"
    create_label "ai-assist" "Issues requiring AI assistance or automation" "ff9800"
    create_label "ai-automation" "Automated tasks performed by AI assistants" "9c27b0"
    create_label "claude-code-review" "Code reviews performed by Claude AI" "e91e63"
    create_label "automated-pr" "Pull requests created automatically by AI" "673ab7"

    print_success "AI automation labels created/verified"
}

# Function to create enhanced default labels
create_enhanced_defaults() {
    print_status "Creating enhanced default labels..."

    # Enhanced GitHub Default Labels
    create_label "bug" "Something isn't working" "d73a4a"
    create_label "documentation" "Improvements or additions to documentation" "0075ca"
    create_label "duplicate" "This issue or pull request already exists" "cfd3d7"
    create_label "enhancement" "New feature or request" "a2eeef"
    create_label "good first issue" "Good for newcomers" "7057ff"
    create_label "help wanted" "Extra attention is needed" "008672"
    create_label "invalid" "This doesn't seem right" "e4e669"
    create_label "question" "Further information is requested" "d876e3"
    create_label "wontfix" "This will not be worked on" "ffffff"

    print_success "Enhanced default labels created/verified"
}

# Function to create workflow labels
create_workflow_labels() {
    print_status "Creating workflow labels..."

    # Development Workflow Labels
    create_label "dependencies" "Pull requests that update a dependency file" "0366d6"
    create_label "security" "Pull requests that address a security vulnerability" "ee0701"
    create_label "performance" "Performance related issues and improvements" "088259"
    create_label "refactor" "Code refactoring and cleanup" "fbca04"
    create_label "tests" "Test coverage and test-related improvements" "5319e7"
    create_label "build/ci" "Issues and PRs related to build and CI/CD" "0075ca"

    print_success "Workflow labels created/verified"
}

# Function to create priority labels
create_priority_labels() {
    print_status "Creating priority labels..."

    # Priority Labels
    create_label "priority/low" "Low priority items that can be addressed later" "bfdadc"
    create_label "priority/medium" "Medium priority items for regular consideration" "ffd93d"
    create_label "priority/high" "High priority items requiring prompt attention" "ff7043"
    create_label "priority/critical" "Critical issues requiring immediate attention" "b60205"

    print_success "Priority labels created/verified"
}

# Function to create size labels
create_size_labels() {
    print_status "Creating size labels..."

    # Size Labels
    create_label "size/xs" "Tiny changes (1-10 lines)" "c7e8c3"
    create_label "size/s" "Small changes (10-50 lines)" "b4e8d6"
    create_label "size/m" "Medium changes (50-200 lines)" "a5d5a8"
    create_label "size/l" "Large changes (200-500 lines)" "96c293"
    create_label "size/xl" "Very large changes (500+ lines)" "7bc96b"

    print_success "Size labels created/verified"
}

# Function to create project-specific labels based on project type
create_project_labels() {
    print_status "Creating project-specific labels..."

    # Detect project type
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
        create_label "python" "Python-specific issues and changes" "3572A5"
    fi

    if [ -f "CMakeLists.txt" ] || [ -f "meson.build" ] || find . -name "*.cpp" -o -name "*.hpp" | grep -q .; then
        create_label "cpp" "C++ specific issues and changes" "f34b7d"

        if [ -f "CMakeLists.txt" ]; then
            create_label "cmake" "CMake build system related" "0646c8"
        fi

        if [ -f "meson.build" ]; then
            create_label "meson" "Meson build system related" "00780c"
        fi
    fi

    # Check for GitHub Actions
    if [ -d ".github/workflows" ]; then
        create_label "github-actions" "GitHub Actions workflows and automation" "000000"
    fi

    print_success "Project-specific labels created/verified"
}

# Function to display usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "This script sets up GitHub labels for CICD template projects."
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Enable verbose output"
    echo "  --ai-only      Only create AI automation labels"
    echo "  --defaults     Only create enhanced default labels"
    echo ""
    echo "Examples:"
    echo "  $0                    # Create all labels"
    echo "  $0 --ai-only          # Only create AI labels"
    echo "  $0 --defaults         # Only create default labels"
}

# Main function
main() {
    local ai_only=false
    local defaults_only=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                set -x
                shift
                ;;
            --ai-only)
                ai_only=true
                shift
                ;;
            --defaults)
                defaults_only=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    print_status "Setting up GitHub labels for CICD template project..."

    # Check prerequisites
    check_git_repo
    check_gh_cli

    # Create labels based on options
    if [ "$defaults_only" = true ]; then
        create_enhanced_defaults
    elif [ "$ai_only" = true ]; then
        create_ai_labels
    else
        create_ai_labels
        create_enhanced_defaults
        create_workflow_labels
        create_priority_labels
        create_size_labels
        create_project_labels
    fi

    print_success "GitHub labels setup complete!"

    # Show summary
    echo ""
    print_status "Label Summary:"
    gh label list --limit 100 | wc -l | xargs echo "Total labels:"
    echo ""
    print_status "AI Labels:"
    gh label list --search "claude\|ai-\|automated" --limit 10 || echo "No AI labels found"
    echo ""
    print_status "Usage Examples:"
    echo "  gh issue create --title 'Bug: Fix compilation error' --label 'bug,claude'"
    echo "  gh issue create --title 'Add new feature' --label 'enhancement,ai-assist'"
    echo "  gh pr create --label 'enhancement,python,size/m' --draft"
}

# Run main function
main "$@"