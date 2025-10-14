#!/bin/bash
# sccache Installation and Configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$SCRIPT_DIR/../utils"
RUNNER_USER="github-runner"
SCCACHE_VERSION="0.11.0"

# Source utility functions
if [ -f "$UTILS_DIR/check-deps.sh" ]; then
    source "$UTILS_DIR/check-deps.sh"
else
    echo -e "\033[0;31m[ERROR]\033[0m Utility functions not found: $UTILS_DIR/check-deps.sh"
    exit 1
fi

install_sccache() {
    echo -e "${GREEN}Installing sccache for compilation caching...${NC}"

    # Download and install sccache
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        SCCACHE_ARCH="x86_64-unknown-linux-musl"
    else
        echo -e "${RED}Unsupported architecture: $ARCH${NC}"
        exit 1
    fi

    curl -L "https://github.com/mozilla/sccache/releases/download/v${SCCACHE_VERSION}/sccache-v${SCCACHE_VERSION}-${SCCACHE_ARCH}.tar.gz" | tar xz

    mv "sccache-v${SCCACHE_VERSION}-${SCCACHE_ARCH}/sccache" /usr/local/bin/
    chmod +x /usr/local/bin/sccache

    # Cleanup
    rm -rf "sccache-v${SCCACHE_VERSION}-${SCCACHE_ARCH}"

    echo -e "${GREEN}✅ sccache installed${NC}"
}

configure_sccache() {
    echo -e "${GREEN}Configuring sccache for $RUNNER_USER...${NC}"

    sudo -u "$RUNNER_USER" bash <<EOF
    # Create sccache directory
    mkdir -p ~/.cache/sccache

    # Configure sccache environment variables
    cat >> ~/.bashrc << 'BASHRC_EOF'

# sccache configuration
export SCCACHE_DIR="\$HOME/.cache/sccache"
export SCCACHE_CACHE_SIZE="10G"
export SCCACHE_MAX_FRAME_FILES="10000"
export SCCACHE_IDLE_TIMEOUT="7200"
export SCCACHE_START_SERVER="1"
export SCCACHE_NO_DAEMON="0"

# CMake integration
export CMAKE_C_COMPILER_LAUNCHER="sccache"
export CMAKE_CXX_COMPILER_LAUNCHER="sccache"
BASHRC_EOF

    # Create sccache config
    mkdir -p ~/.config/sccache
    cat > ~/.config/sccache/config << 'SCCACHE_CONFIG'
[disk]
dir = "${HOME}/.cache/sccache"
size = "10G"

[server]
start_server = true
idle_timeout = 7200
max_frame_files = 10000
SCCACHE_CONFIG

    echo "sccache configured for $RUNNER_USER"
EOF

    echo -e "${GREEN}✅ sccache configuration created${NC}"
}

main() {
    # Check if sccache is already installed
    if check_sccache; then
        print_success "sccache is already installed - skipping installation"
        # Still configure if not configured
        if [ ! -f "/home/$RUNNER_USER/.config/sccache/config" ]; then
            configure_sccache
        else
            print_success "sccache is already configured"
        fi
        exit 0
    fi

    install_sccache
    configure_sccache
}

main "$@"