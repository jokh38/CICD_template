#!/bin/bash
# Sync template configurations across projects

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

CONFIGS_DIR="$SCRIPT_DIR/../configs"

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

    print_success "Syncing Python configurations to $target_dir"

    cp "$CONFIGS_DIR/python/.pre-commit-config.yaml" "$target_dir/"
    cp "$CONFIGS_DIR/python/ruff.toml" "$target_dir/"

    print_warning "Note: Review pyproject.toml manually for Ruff configuration"
    print_success "Python configurations synced"
}

sync_cpp() {
    local target_dir=$1

    print_success "Syncing C++ configurations to $target_dir"

    cp "$CONFIGS_DIR/cpp/.pre-commit-config.yaml" "$target_dir/"
    cp "$CONFIGS_DIR/cpp/.clang-format" "$target_dir/"
    cp "$CONFIGS_DIR/cpp/.clang-tidy" "$target_dir/"

    print_warning "Note: Review CMakeLists.txt for any necessary updates"
    print_success "C++ configurations synced"
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
