#!/bin/bash
# Build Tools Installation

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

install_build_tools() {
    echo -e "${GREEN}Installing build tools...${NC}"

    if [ "$OS" = "debian" ]; then
        apt-get install -y \
            cmake ninja-build \
            meson \
            pkg-config \
            autoconf automake
    elif [ "$OS" = "redhat" ]; then
        yum install -y \
            cmake ninja-build \
            meson \
            pkgconfig autoconf automake
    fi

    echo -e "${GREEN}✅ Build tools installed${NC}"
}

main() {
    detect_os

    # Check if build tools are already installed
    if check_build_tools; then
        print_success "Build tools are already installed - skipping"
        exit 0
    fi

    install_build_tools
}

main "$@"