#!/bin/bash
# GitHub Actions Self-Hosted Runner Installation (Linux)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

RUNNER_VERSION="2.319.1"
RUNNER_USER="github-runner"
INSTALL_DIR="/opt/actions-runner"

# Logging functions (consistent with other scripts)
print_status() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root"
        exit 1
    fi
}

install_dependencies() {
    print_status "Installing dependencies..."

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
        print_error "Unsupported OS"
        exit 1
    fi
}

create_runner_user() {
    print_status "Creating runner user..."

    if ! id "$RUNNER_USER" &>/dev/null; then
        useradd -m -s /bin/bash "$RUNNER_USER"
    fi
}

download_runner() {
    print_status "Downloading runner..."

    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
        -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

    tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
    rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

    chown -R "$RUNNER_USER:$RUNNER_USER" "$INSTALL_DIR"
}

configure_runner() {
    print_warning "Runner configuration"
    echo "Please provide the following information:"
    echo ""

    read -p "GitHub URL (e.g., https://github.com/your-org): " GITHUB_URL
    read -p "Registration token: " REG_TOKEN
    read -p "Runner name (default: $(hostname)): " RUNNER_NAME
    RUNNER_NAME=${RUNNER_NAME:-$(hostname)}

    print_status "Configuring runner..."

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
    print_status "Installing systemd service..."

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
    print_status "Installing Python development tools..."

    sudo -u "$RUNNER_USER" bash <<'EOF'
pip3 install --user \
    ruff \
    pytest pytest-cov \
    mypy \
    pre-commit
EOF

    print_success "Python tools installed"
}

setup_cpp_tools() {
    print_status "Installing C++ development tools..."

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
        print_error "Unsupported architecture: $ARCH"
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

    print_success "C++ tools installed"
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