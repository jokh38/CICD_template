#!/bin/bash
# Install Python Development Tools

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

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