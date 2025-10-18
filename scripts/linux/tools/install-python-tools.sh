#!/bin/bash
# Install Python Development Tools

set -e

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_UTILS="$SCRIPT_DIR/../../lib/common-utils.sh"

if [ -f "$COMMON_UTILS" ]; then
    source "$COMMON_UTILS"
else
    echo "Error: Cannot find common-utils.sh at $COMMON_UTILS"
    exit 1
fi

# Install Python development tools
print_status "Installing Python development tools..."
pip3 install --upgrade pip

# Install essential Python development tools
print_status "Installing essential Python packages..."
pip3 install \
    ruff \
    black \
    isort \
    pytest \
    pytest-cov \
    pytest-mock \
    mypy \
    flake8 \
    bandit \
    pre-commit \
    virtualenv \
    pipenv \
    poetry \
    tox \
    sphinx \
    sphinx-rtd-theme

# Install additional development tools
print_status "Installing additional Python development packages..."
pip3 install \
    ipython \
    jupyter \
    jupyterlab \
    python-lsp-server \
    debugpy

print_success "Python development tools installed successfully"