#!/bin/bash
# Common utility functions for dependency checking

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to check if package is installed (Debian/Ubuntu)
is_deb_package_installed() {
    dpkg -l | grep -q "^ii  $1 " 2>/dev/null
}

# Function to check if package is installed (RHEL/CentOS)
is_rpm_package_installed() {
    rpm -q "$1" &> /dev/null
}

# Function to detect OS
detect_os() {
    if [ -f /etc/debian_version ]; then
        OS="debian"
    elif [ -f /etc/redhat-release ]; then
        OS="redhat"
    else
        echo -e "${RED}Unsupported OS${NC}"
        exit 1
    fi
}

# Function to check system dependencies
check_system_deps() {
    print_status "Checking system dependencies..."
    local missing_deps=()
    local all_installed=true

    if [ "$OS" = "debian" ]; then
        local deps=(
            "build-essential" "cmake" "ninja-build"
            "clang" "clang-format" "clang-tidy"
            "gcc" "g++" "gdb"
            "libssl-dev" "libffi-dev"
            "curl" "wget" "git" "jq"
            "pkg-config" "autoconf" "automake"
            "libgtest-dev" "libbenchmark-dev"
            "python3" "python3-pip" "python3-venv" "python3-dev"
        )

        for dep in "${deps[@]}"; do
            if ! is_deb_package_installed "$dep"; then
                missing_deps+=("$dep")
                all_installed=false
            fi
        done

    elif [ "$OS" = "redhat" ]; then
        local deps=(
            "cmake" "ninja-build"
            "clang" "clang-tools-extra"
            "gcc" "gcc-c++" "gdb"
            "openssl-devel" "libffi-devel"
            "curl" "wget" "git" "jq"
            "pkgconfig" "autoconf" "automake"
            "python3" "python3-pip" "python3-devel"
        )

        for dep in "${deps[@]}"; do
            if ! is_rpm_package_installed "$dep"; then
                missing_deps+=("$dep")
                all_installed=false
            fi
        done
    fi

    if [ "$all_installed" = true ]; then
        print_success "All system dependencies are already installed"
        return 0
    else
        print_warning "Missing system dependencies:"
        printf '  %s\n' "${missing_deps[@]}"
        return 1
    fi
}

# Function to check compiler tools
check_compilers() {
    print_status "Checking compiler tools..."
    local missing_tools=()
    local all_installed=true

    local tools=("gcc" "g++" "clang" "clangd" "gdb")

    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
            all_installed=false
        fi
    done

    if [ "$all_installed" = true ]; then
        print_success "All compiler tools are already installed"
        return 0
    else
        print_warning "Missing compiler tools:"
        printf '  %s\n' "${missing_tools[@]}"
        return 1
    fi
}

# Function to check build tools
check_build_tools() {
    print_status "Checking build tools..."
    local missing_tools=()
    local all_installed=true

    local tools=("cmake" "ninja" "make")

    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
            all_installed=false
        fi
    done

    if [ "$all_installed" = true ]; then
        print_success "All build tools are already installed"
        return 0
    else
        print_warning "Missing build tools:"
        printf '  %s\n' "${missing_tools[@]}"
        return 1
    fi
}

# Function to check Python tools
check_python_tools() {
    print_status "Checking Python tools..."
    local missing_tools=()
    local all_installed=true

    local tools=("python3" "pip3")

    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
            all_installed=false
        fi
    done

    # Check for Python packages
    if command_exists pip3; then
        local python_packages=("ruff" "pytest" "mypy" "black" "isort")
        for package in "${python_packages[@]}"; do
            if ! pip3 show "$package" &> /dev/null; then
                missing_tools+=("python3-$package")
                all_installed=false
            fi
        done
    else
        all_installed=false
    fi

    if [ "$all_installed" = true ]; then
        print_success "All Python tools are already installed"
        return 0
    else
        print_warning "Missing Python tools:"
        printf '  %s\n' "${missing_tools[@]}"
        return 1
    fi
}

# Function to check C++ frameworks
check_cpp_frameworks() {
    print_status "Checking C++ frameworks..."
    local missing_tools=()
    local all_installed=true

    # Check for Google Test headers
    if [ ! -f "/usr/local/include/gtest/gtest.h" ] && [ ! -f "/usr/include/gtest/gtest.h" ]; then
        missing_tools+=("Google Test")
        all_installed=false
    fi

    # Check for Catch2 headers
    if [ ! -f "/usr/local/include/catch2/catch_test_macros.hpp" ] && [ ! -f "/usr/include/catch2/catch_test_macros.hpp" ]; then
        missing_tools+=("Catch2")
        all_installed=false
    fi

    # Check for Google Benchmark headers
    if [ ! -f "/usr/local/include/benchmark/benchmark.h" ] && [ ! -f "/usr/include/benchmark/benchmark.h" ]; then
        missing_tools+=("Google Benchmark")
        all_installed=false
    fi

    if [ "$all_installed" = true ]; then
        print_success "All C++ frameworks are already installed"
        return 0
    else
        print_warning "Missing C++ frameworks:"
        printf '  %s\n' "${missing_tools[@]}"
        return 1
    fi
}

# Function to check sccache
check_sccache() {
    print_status "Checking sccache..."

    if command_exists sccache; then
        print_success "sccache is already installed"
        return 0
    else
        print_warning "sccache is not installed"
        return 1
    fi
}

# Function to check if Git is configured
check_git_config() {
    print_status "Checking Git configuration..."

    if [ -f "$HOME/.gitconfig" ]; then
        if git config --global user.name &> /dev/null && git config --global user.email &> /dev/null; then
            print_success "Git is already configured"
            return 0
        fi
    fi

    print_warning "Git is not configured"
    return 1
}

# Function to check code formatting configurations
check_code_formatting() {
    print_status "Checking code formatting configurations..."
    local missing_configs=()
    local all_configured=true

    local configs=(
        "$HOME/.clang-format"
        "$HOME/.clang-tidy"
        "$HOME/.config/ruff/ruff.toml"
    )

    for config in "${configs[@]}"; do
        if [ ! -f "$config" ]; then
            missing_configs+=("$config")
            all_configured=false
        fi
    done

    if [ "$all_configured" = true ]; then
        print_success "All code formatting configurations are already set up"
        return 0
    else
        print_warning "Missing formatting configurations:"
        printf '  %s\n' "${missing_configs[@]}"
        return 1
    fi
}