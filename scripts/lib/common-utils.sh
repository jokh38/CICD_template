#!/bin/bash
# Common utility functions for CICD template scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions - standardized across all scripts
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Success/error indicators
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Common validation functions
check_command_exists() {
    local cmd="$1"
    local desc="${2:-$cmd}"

    if command -v "$cmd" &> /dev/null; then
        print_success "$desc is available"
        return 0
    else
        print_error "$desc not found"
        return 1
    fi
}

check_file_exists() {
    local file="$1"
    local desc="${2:-$file}"

    if [ -f "$file" ]; then
        print_success "$desc exists"
        return 0
    else
        print_error "$desc missing: $file"
        return 1
    fi
}

check_dir_exists() {
    local dir="$1"
    local desc="${2:-$dir}"

    if [ -d "$dir" ]; then
        print_success "$desc exists"
        return 0
    else
        print_error "$desc missing: $dir"
        return 1
    fi
}

# Common script directory detection
get_script_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

get_root_dir() {
    local script_dir="$(get_script_dir)"
    echo "$(dirname "$script_dir")"
}

# Version comparison
version_compare() {
    local version1="$1"
    local version2="$2"

    if [[ $version1 == $version2 ]]; then
        return 0  # Equal versions
    fi

    local IFS=.
    local i ver1=($version1) ver2=($version2)

    # Fill empty fields with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=${#ver2[@]}; i<${#ver1[@]}; i++)); do
        ver2[i]=0
    done

    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            return 1  # version1 > version2
        elif ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1  # version1 > version2
        elif ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2  # version1 < version2
        fi
    done

    return 0  # versions are equal
}

# Common error handling
handle_error() {
    local exit_code=$?
    local line_number=$1
    local command="$2"

    if [ $exit_code -ne 0 ]; then
        log_error "Command failed with exit code $exit_code at line $line_number: $command"
        exit $exit_code
    fi
}

# Set up error trapping
setup_error_handling() {
    set -eE
    trap 'handle_error $LINENO "$BASH_COMMAND"' ERR
}

# Cleanup function that can be overridden
cleanup_on_exit() {
    # Default cleanup - can be overridden by scripts
    log_info "Performing cleanup..."
}

# Set up cleanup trap
setup_cleanup_trap() {
    trap cleanup_on_exit EXIT
}

# Common usage function template
show_usage_template() {
    local script_name="$1"
    local description="$2"
    shift 2

    cat << EOF
Usage: $script_name [OPTIONS]

$description

OPTIONS:
EOF

    # Print provided options
    for option in "$@"; do
        echo "    $option"
    done

    echo ""
    echo "Common options:"
    echo "    --help, -h          Show this help message"
    echo "    --verbose           Enable verbose output"
    echo "    --quiet             Suppress non-error output"
    echo ""
}

# Export functions if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export log log_error log_warning log_info
    export print_success print_error print_warning print_status
    export check_command_exists check_file_exists check_dir_exists
    export get_script_dir get_root_dir version_compare
    export setup_error_handling setup_cleanup_trap show_usage_template
fi