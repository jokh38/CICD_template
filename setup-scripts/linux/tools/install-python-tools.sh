#!/bin/bash
# Python Development Tools Installation

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

RUNNER_USER="github-runner"

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
    install_python_tools
}

main "$@"