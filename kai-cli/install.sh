#!/bin/bash
set -e

echo "Installing kai CLI..."

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

# Check for Go
if ! command -v go &> /dev/null; then
    echo "Error: Go is not installed. Please install Go 1.22+ first."
    echo "  Visit: https://go.dev/dl/"
    exit 1
fi

# Check Go version (need 1.22+)
GO_VERSION=$(go version | grep -oP 'go\K[0-9]+\.[0-9]+' | head -1)
GO_MAJOR=$(echo "$GO_VERSION" | cut -d. -f1)
GO_MINOR=$(echo "$GO_VERSION" | cut -d. -f2)

if [ "$GO_MAJOR" -lt 1 ] || ([ "$GO_MAJOR" -eq 1 ] && [ "$GO_MINOR" -lt 22 ]); then
    echo "Error: Go 1.22+ is required. Found: go$GO_VERSION"
    exit 1
fi

echo "Found Go $GO_VERSION"

# Install C compiler if needed (required for CGO)
install_gcc() {
    echo "Installing C compiler (required for CGO dependencies)..."

    case "$OS" in
        Linux)
            if command -v apt-get &> /dev/null; then
                # Debian/Ubuntu
                sudo apt-get update && sudo apt-get install -y gcc
            elif command -v dnf &> /dev/null; then
                # Fedora/RHEL
                sudo dnf install -y gcc
            elif command -v yum &> /dev/null; then
                # Older RHEL/CentOS
                sudo yum install -y gcc
            elif command -v pacman &> /dev/null; then
                # Arch Linux
                sudo pacman -S --noconfirm gcc
            elif command -v apk &> /dev/null; then
                # Alpine
                sudo apk add gcc musl-dev
            else
                echo "Error: Could not detect package manager. Please install gcc manually."
                exit 1
            fi
            ;;
        Darwin)
            # macOS - check for Xcode CLI tools
            if ! xcode-select -p &> /dev/null; then
                echo "Installing Xcode Command Line Tools..."
                xcode-select --install
                echo "Please run this script again after Xcode tools are installed."
                exit 0
            fi
            ;;
        *)
            echo "Error: Unsupported OS: $OS"
            echo "Please install a C compiler (gcc/clang) manually."
            exit 1
            ;;
    esac
}

# Check for C compiler
if ! command -v gcc &> /dev/null && ! command -v clang &> /dev/null; then
    install_gcc
else
    echo "Found C compiler"
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Build kai
echo "Building kai..."
CGO_ENABLED=1 go build -o kai ./cmd/kai

echo ""
echo "Build successful!"
echo ""

# Offer to install to PATH
INSTALL_DIR="/usr/local/bin"

if [ -w "$INSTALL_DIR" ] || [ "$EUID" -eq 0 ]; then
    read -p "Install kai to $INSTALL_DIR? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cp kai "$INSTALL_DIR/kai"
        echo "Installed kai to $INSTALL_DIR/kai"
    fi
else
    read -p "Install kai to $INSTALL_DIR? (requires sudo) [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        sudo cp kai "$INSTALL_DIR/kai"
        echo "Installed kai to $INSTALL_DIR/kai"
    fi
fi

echo ""
echo "Done! Run 'kai --help' to get started."
