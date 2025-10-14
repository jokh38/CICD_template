#!/bin/bash
# GitHub Actions Self-Hosted Runner Installation (Linux)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

RUNNER_VERSION="2.319.1"
RUNNER_USER="github-runner"
INSTALL_DIR="/opt/actions-runner"

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root${NC}"
        exit 1
    fi
}

install_dependencies() {
    echo -e "${GREEN}Installing dependencies...${NC}"

    if [ -f /etc/debian_version ]; then
        apt-get update
        apt-get install -y \
            curl jq git build-essential \
            libssl-dev libffi-dev python3 python3-pip
    elif [ -f /etc/redhat-release ]; then
        yum install -y \
            curl jq git gcc gcc-c++ make \
            openssl-devel libffi-devel python3 python3-pip
    else
        echo -e "${RED}Unsupported OS${NC}"
        exit 1
    fi
}

create_runner_user() {
    echo -e "${GREEN}Creating runner user...${NC}"

    if ! id "$RUNNER_USER" &>/dev/null; then
        useradd -m -s /bin/bash "$RUNNER_USER"
    fi
}

download_runner() {
    echo -e "${GREEN}Downloading runner...${NC}"

    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
        -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

    tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
    rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

    chown -R "$RUNNER_USER:$RUNNER_USER" "$INSTALL_DIR"
}

configure_runner() {
    echo -e "${YELLOW}Runner configuration${NC}"
    echo "Please provide the following information:"
    echo ""

    read -p "GitHub URL (e.g., https://github.com/your-org): " GITHUB_URL
    read -p "Registration token: " REG_TOKEN
    read -p "Runner name (default: $(hostname)): " RUNNER_NAME
    RUNNER_NAME=${RUNNER_NAME:-$(hostname)}

    echo -e "${GREEN}Configuring runner...${NC}"

    cd "$INSTALL_DIR"
    sudo -u "$RUNNER_USER" ./config.sh \
        --url "$GITHUB_URL" \
        --token "$REG_TOKEN" \
        --name "$RUNNER_NAME" \
        --labels self-hosted,Linux,X64 \
        --work _work \
        --unattended
}

install_service() {
    echo -e "${GREEN}Installing systemd service...${NC}"

    cd "$INSTALL_DIR"
    ./svc.sh install "$RUNNER_USER"
    ./svc.sh start

    systemctl enable actions.runner.*.service
}

print_success() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✅ Runner installed successfully!${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo "Service status:"
    systemctl status actions.runner.*.service --no-pager
    echo ""
    echo "Next steps:"
    echo "1. Verify runner appears in GitHub settings"
    echo "2. Run: sudo $0 --setup-python"
    echo "   or: sudo $0 --setup-cpp"
}

setup_python_tools() {
    echo -e "${GREEN}Installing Python development tools...${NC}"

    sudo -u "$RUNNER_USER" bash <<'EOF'
pip3 install --user \
    ruff \
    pytest pytest-cov \
    mypy \
    pre-commit
EOF

    echo -e "${GREEN}✅ Python tools installed${NC}"
}

setup_cpp_tools() {
    echo -e "${GREEN}Installing C++ development tools...${NC}"

    if [ -f /etc/debian_version ]; then
        apt-get install -y \
            clang clang-format clang-tidy \
            cmake ninja-build \
            build-essential
    fi

    # Install sccache v0.11.0
    SCCACHE_VERSION="0.11.0"
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
    rm -rf "sccache-v${SCCACHE_VERSION}-${SCCACHE_ARCH}"

    # Configure sccache
    sudo -u "$RUNNER_USER" bash <<'EOF'
mkdir -p ~/.cache/sccache
echo 'export SCCACHE_DIR=~/.cache/sccache' >> ~/.bashrc
echo 'export SCCACHE_CACHE_SIZE="10G"' >> ~/.bashrc
echo 'export CMAKE_C_COMPILER_LAUNCHER="sccache"' >> ~/.bashrc
echo 'export CMAKE_CXX_COMPILER_LAUNCHER="sccache"' >> ~/.bashrc
EOF

    echo -e "${GREEN}✅ C++ tools installed${NC}"
}

main() {
    case "${1:-}" in
        --setup-python)
            setup_python_tools
            ;;
        --setup-cpp)
            setup_cpp_tools
            ;;
        *)
            check_root
            install_dependencies
            create_runner_user
            download_runner
            configure_runner
            install_service
            print_success
            ;;
    esac
}

main "$@"