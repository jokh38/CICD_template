#!/bin/bash
# Project creation wrapper for Cookiecutter

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../cookiecutters"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 <language> [project-name] [--github]

Languages:
  python    - Python project template
  cpp       - C++ project template

Arguments:
  language       Language template to use (python/cpp)
  project-name   Optional project name or absolute path (e.g., /home/user/my-project)
  --github       Optional flag to create GitHub repository automatically

Examples:
  $0 python my-awesome-project
  $0 python /home/user/my-awesome-project --github
  $0 cpp my-fast-library --github

Note: If --github flag is used, you must have gh CLI installed and authenticated.
Install gh CLI: https://cli.github.com/

EOF
    exit 1
}

check_dependencies() {
    local deps=("cookiecutter" "git")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${RED}Error: $dep not found${NC}"
            echo "Install with: pip install cookiecutter"
            exit 1
        fi
    done

    # Check for gh CLI (optional)
    if ! command -v "gh" &> /dev/null; then
        echo -e "${YELLOW}Warning: gh CLI not found. Install it to auto-create GitHub repositories: https://cli.github.com/${NC}"
        GH_AVAILABLE=false
    else
        GH_AVAILABLE=true
    fi
}

create_project() {
    local language=$1
    local project_name=$2
    local create_repo=${3:-false}

    local template_dir="$TEMPLATES_DIR/${language}-project"

    if [ ! -d "$template_dir" ]; then
        echo -e "${RED}Error: Template not found for $language${NC}"
        exit 1
    fi

    echo -e "${GREEN}Creating $language project...${NC}"

    if [ -n "$project_name" ]; then
        # Extract just the directory name from full path for project_name
        local basename_project=$(basename "$project_name")
        cookiecutter "$template_dir" --no-input project_name="$basename_project" output_dir="$(dirname "$project_name")"
        local project_dir="$project_name"
    else
        cookiecutter "$template_dir"
        # Get the created project directory from cookiecutter output
        echo -e "${YELLOW}Enter the project directory that was created:${NC}"
        read -p "Project path: " project_dir
    fi

    # Change to the project directory for GitHub operations
    cd "$project_dir"

    echo -e "${GREEN}✅ Project created!${NC}"
    echo ""
    echo -e "${YELLOW}• AI-Enabled Project Features:${NC}"
    echo "  - AI workflow templates pre-configured"
    echo "  - GitHub Actions with AI automation ready"
    echo "  - Comprehensive documentation for AI development"
    echo "  - GitHub labels automatically configured for AI workflows"
    echo ""

    # GitHub repository creation
    if [ "$create_repo" = true ] && [ "$GH_AVAILABLE" = true ]; then
        create_github_repo "$(basename "$project_dir")"
    elif [ "$create_repo" = true ]; then
        echo -e "${YELLOW}GitHub repository creation skipped (gh CLI not available)${NC}"
        echo "Install gh CLI: https://cli.github.com/"
    fi

    echo ""
    echo -e "${YELLOW}• Next Steps:${NC}"
    echo "  1. Navigate to your project directory and start development"
    echo "  2. Install requirements by using setup-scripts/total_run.sh (requires sudo)"
    echo "     Run: sudo bash setup-scripts/total_run.sh"
    echo "  3. Check .github/claude/CLAUDE.md for AI assistant integration details"
    echo "  4. GitHub labels are ready for AI automation (use 'claude', 'ai-assist', etc.)"
}

create_github_repo() {
    local repo_name=$1
    echo -e "${BLUE}Creating GitHub repository '$repo_name'...${NC}"

    if gh repo create "$repo_name" --public --source=. --remote=origin --push; then
        echo -e "${GREEN}✅ GitHub repository created and pushed successfully!${NC}"
        echo -e "${YELLOW}Repository URL: https://github.com/$(gh api user --jq '.login')/$repo_name${NC}"
    else
        echo -e "${RED}❌ Failed to create GitHub repository${NC}"
        echo -e "${YELLOW}You can create it manually:${NC}"
        echo "  1. Go to https://github.com/new"
        echo "  2. Create repository named '$repo_name'"
        echo "  3. Add remote and push:"
        echo "     git remote add origin https://github.com/YOUR-USERNAME/$repo_name.git"
        echo "     git push -u origin main"
    fi
}

main() {
    if [ $# -lt 1 ]; then
        usage
    fi

    # Handle help flags
    case $1 in
        -h|--help)
            usage
            ;;
    esac

    check_dependencies

    local language="$1"
    local project_name=""
    local create_repo=false

    # Parse arguments
    shift
    while [ $# -gt 0 ]; do
        case $1 in
            --github)
                create_repo=true
                shift
                ;;
            *)
                if [ -z "$project_name" ]; then
                    project_name="$1"
                else
                    echo -e "${RED}Error: Unexpected argument '$1'${NC}"
                    usage
                fi
                shift
                ;;
        esac
    done

    create_project "$language" "$project_name" "$create_repo"
}

main "$@"
