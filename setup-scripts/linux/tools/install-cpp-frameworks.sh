#!/bin/bash
# C++ Testing Frameworks Installation

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

install_cpp_testing_frameworks() {
    echo -e "${GREEN}Installing C++ testing frameworks...${NC}"

    if [ "$OS" = "debian" ]; then
        # Install Google Test v1.17.0 from GitHub
        echo -e "${YELLOW}Installing GoogleTest v1.17.0...${NC}"
        cd /tmp
        wget https://github.com/google/googletest/archive/refs/tags/v1.17.0.tar.gz
        tar -xzf v1.17.0.tar.gz
        cd googletest-1.17.0
        cmake -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_TESTING=OFF -DINSTALL_GTEST=ON
        cmake --build build
        cmake --install build
        cd /tmp
        rm -rf v1.17.0.tar.gz googletest-1.17.0

        # Install Catch2 v3.11.0 from GitHub
        echo -e "${YELLOW}Installing Catch2 v3.11.0...${NC}"
        cd /tmp
        wget https://github.com/catchorg/Catch2/archive/refs/tags/v3.11.0.tar.gz
        tar -xzf v3.11.0.tar.gz
        cd Catch2-3.11.0
        cmake -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_TESTING=OFF
        cmake --build build
        cmake --install build
        cd /tmp
        rm -rf v3.11.0.tar.gz Catch2-3.11.0

        # Install Google Benchmark
        echo -e "${YELLOW}Installing Google Benchmark...${NC}"
        cd /tmp
        git clone https://github.com/google/benchmark.git
        cd benchmark
        cmake -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DBENCHMARK_ENABLE_TESTING=OFF
        cmake --build build
        cmake --install build
        cd /tmp
        rm -rf benchmark
    elif [ "$OS" = "redhat" ]; then
        # Install Google Test v1.17.0 from GitHub for RHEL/CentOS
        echo -e "${YELLOW}Installing GoogleTest v1.17.0...${NC}"
        cd /tmp
        wget https://github.com/google/googletest/archive/refs/tags/v1.17.0.tar.gz
        tar -xzf v1.17.0.tar.gz
        cd googletest-1.17.0
        cmake -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_TESTING=OFF -DINSTALL_GTEST=ON
        cmake --build build
        cmake --install build
        cd /tmp
        rm -rf v1.17.0.tar.gz googletest-1.17.0

        # Install Catch2 v3.11.0 from GitHub for RHEL/CentOS
        echo -e "${YELLOW}Installing Catch2 v3.11.0...${NC}"
        cd /tmp
        wget https://github.com/catchorg/Catch2/archive/refs/tags/v3.11.0.tar.gz
        tar -xzf v3.11.0.tar.gz
        cd Catch2-3.11.0
        cmake -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_TESTING=OFF
        cmake --build build
        cmake --install build
        cd /tmp
        rm -rf v3.11.0.tar.gz Catch2-3.11.0
    fi

    echo -e "${GREEN}✅ C++ testing frameworks installed${NC}"
}

main() {
    detect_os

    # Check if C++ frameworks are already installed
    if check_cpp_frameworks; then
        print_success "C++ frameworks are already installed - skipping"
        exit 0
    fi

    install_cpp_testing_frameworks
}

main "$@"