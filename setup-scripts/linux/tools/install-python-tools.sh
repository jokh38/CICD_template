#!/bin/bash
# Python Development Tools Installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$SCRIPT_DIR/../utils"
RUNNER_USER="github-runner"

# Source utility functions
if [ -f "$UTILS_DIR/check-deps.sh" ]; then
    source "$UTILS_DIR/check-deps.sh"
else
    echo -e "\033[0;31m[ERROR]\033[0m Utility functions not found: $UTILS_DIR/check-deps.sh"
    exit 1
fi

install_python_tools() {
    echo -e "${GREEN}Installing Python development tools for $RUNNER_USER...${NC}"

    # Install tools for the runner user
    sudo -u "$RUNNER_USER" bash <<'EOF'
    # Upgrade pip
    python3 -m pip install --upgrade pip setuptools wheel

    # Install core Python development tools
    python3 -m pip install --user \
        ruff \
        pytest pytest-cov pytest-mock \
        mypy \
        pre-commit \
        black \
        isort \
        flake8 \
        bandit \
        pipx

    # Create pipx directory for standalone tools
    mkdir -p ~/.local/pipx/bin
    echo 'export PATH="$HOME/.local/pipx/bin:$PATH"' >> ~/.bashrc
EOF

    echo -e "${GREEN}✅ Python tools installed${NC}"
}

main() {
    # Check if Python tools are already installed for the runner user
    if check_python_tools; then
        print_success "Python tools are already installed - skipping"
        exit 0
    fi

    install_python_tools
}

main "$@"