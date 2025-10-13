#!/bin/bash
# Sync template configurations across projects

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/../configs"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 <project-type> <target-dir>

Project Types:
  python    - Sync Python configuration files
  cpp       - Sync C++ configuration files

Examples:
  $0 python /path/to/python-project
  $0 cpp /path/to/cpp-project

EOF
    exit 1
}

sync_python() {
    local target_dir=$1

    echo -e "${GREEN}Syncing Python configurations to $target_dir${NC}"

    cp "$CONFIGS_DIR/python/.pre-commit-config.yaml" "$target_dir/"
    cp "$CONFIGS_DIR/python/ruff.toml" "$target_dir/"

    echo -e "${YELLOW}Note: Review pyproject.toml manually for Ruff configuration${NC}"
    echo -e "${GREEN}✅ Python configurations synced${NC}"
}

sync_cpp() {
    local target_dir=$1

    echo -e "${GREEN}Syncing C++ configurations to $target_dir${NC}"

    cp "$CONFIGS_DIR/cpp/.pre-commit-config.yaml" "$target_dir/"
    cp "$CONFIGS_DIR/cpp/.clang-format" "$target_dir/"
    cp "$CONFIGS_DIR/cpp/.clang-tidy" "$target_dir/"

    echo -e "${YELLOW}Note: Review CMakeLists.txt for any necessary updates${NC}"
    echo -e "${GREEN}✅ C++ configurations synced${NC}"
}

main() {
    if [ $# -lt 2 ]; then
        usage
    fi

    local project_type=$1
    local target_dir=$2

    if [ ! -d "$target_dir" ]; then
        echo "Error: Target directory does not exist: $target_dir"
        exit 1
    fi

    case "$project_type" in
        python)
            sync_python "$target_dir"
            ;;
        cpp)
            sync_cpp "$target_dir"
            ;;
        *)
            echo "Error: Unknown project type: $project_type"
            usage
            ;;
    esac
}

main "$@"
