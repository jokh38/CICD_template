#!/bin/bash
# Project creation wrapper for Cookiecutter

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../cookiecutters"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 <language> [project-name]

Languages:
  python    - Python project template
  cpp       - C++ project template

Examples:
  $0 python my-awesome-project
  $0 cpp my-fast-library

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
}

create_project() {
    local language=$1
    local project_name=$2

    local template_dir="$TEMPLATES_DIR/${language}-project"

    if [ ! -d "$template_dir" ]; then
        echo -e "${RED}Error: Template not found for $language${NC}"
        exit 1
    fi

    echo -e "${GREEN}Creating $language project...${NC}"

    if [ -n "$project_name" ]; then
        cookiecutter "$template_dir" --no-input project_name="$project_name"
    else
        cookiecutter "$template_dir"
    fi

    echo -e "${GREEN}✅ Project created successfully!${NC}"
}

main() {
    if [ $# -lt 1 ]; then
        usage
    fi

    check_dependencies

    create_project "$@"
}

main "$@"
