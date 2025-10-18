#!/bin/bash
# Install sccache (shared compilation cache)

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

# Install sccache
print_status "Installing sccache..."
if ! command -v sccache &> /dev/null; then
    # Get latest version
    SCCACHE_VERSION=$(curl -s https://api.github.com/repos/mozilla/sccache/releases/latest | grep tag_name | cut -d '"' -f 4)
    SCCACHE_VERSION=${SCCACHE_VERSION#v}

    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="x86_64"
            ;;
        aarch64)
            ARCH="aarch64"
            ;;
        *)
            print_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    wget "https://github.com/mozilla/sccache/releases/download/v${SCCACHE_VERSION}/sccache-v${SCCACHE_VERSION}-${ARCH}-unknown-linux-musl.tar.gz" -O /tmp/sccache.tar.gz
    cd /tmp
    tar -xzf sccache.tar.gz
    cp "sccache-v${SCCACHE_VERSION}-${ARCH}-unknown-linux-musl/sccache" /usr/local/bin/
    chmod +x /usr/local/bin/sccache
    rm -rf /tmp/sccache*
else
    print_status "sccache already installed"
fi

# Create sccache config directory
print_status "Setting up sccache configuration..."
mkdir -p ~/.config/sccache

# Create basic sccache config
cat > ~/.config/sccache/config << 'EOF'
# sccache configuration
cache_dir = "~/.cache/sccache"
max_size = "5G"
EOF

print_success "sccache installed successfully"