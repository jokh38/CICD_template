#!/bin/bash
# Compiler Tools Installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$SCRIPT_DIR/../utils"

# Source utility functions
if [ -f "$UTILS_DIR/check-deps.sh" ]; then
    source "$UTILS_DIR/check-deps.sh"
else
    echo -e "\033[0;31m[ERROR]\033[0m Utility functions not found: $UTILS_DIR/check-deps.sh"
    exit 1
fi

install_compilers() {
    echo -e "${GREEN}Installing compiler tools...${NC}"

    if [ "$OS" = "debian" ]; then
        apt-get install -y \
            gcc g++ \
            clang clangd \
            gdb \
            llvm-dev
    elif [ "$OS" = "redhat" ]; then
        yum install -y \
            gcc gcc-c++ \
            clang clang-tools-extra \
            gdb \
            llvm-devel
    fi

    echo -e "${GREEN}✅ Compiler tools installed${NC}"
}

main() {
    detect_os

    # Check if compiler tools are already installed
    if check_compilers; then
        print_success "Compiler tools are already installed - skipping"
        exit 0
    fi

    install_compilers
}

main "$@"