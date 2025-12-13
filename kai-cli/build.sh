#!/bin/bash
set -e

# Kai CLI build script
# Builds from source with all required dependencies

echo "Building kai CLI from source..."

# Detect OS
OS="$(uname -s)"

# Check for Go
if ! command -v go &> /dev/null; then
    echo "Error: Go is not installed. Please install Go 1.22+ first."
    echo "  Visit: https://go.dev/dl/"
    exit 1
fi

# Check Go version (need 1.22+)
GO_VERSION=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//')
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
                sudo apt-get update && sudo apt-get install -y gcc
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y gcc
            elif command -v yum &> /dev/null; then
                sudo yum install -y gcc
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm gcc
            elif command -v apk &> /dev/null; then
                sudo apk add gcc musl-dev
            else
                echo "Error: Could not detect package manager. Please install gcc manually."
                exit 1
            fi
            ;;
        Darwin)
            if ! xcode-select -p &> /dev/null; then
                echo "Installing Xcode Command Line Tools..."
                xcode-select --install
                echo "Please run this script again after Xcode tools are installed."
                exit 0
            fi
            ;;
        *)
            echo "Error: Unsupported OS: $OS"
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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Build
echo "Building kai..."
CGO_ENABLED=1 go build -o kai ./cmd/kai

echo ""
echo "Build successful: $SCRIPT_DIR/kai"
echo ""

# Offer to install
INSTALL_DIR="/usr/local/bin"
read -p "Install to $INSTALL_DIR? [Y/n] " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    if [ -w "$INSTALL_DIR" ]; then
        cp kai "$INSTALL_DIR/kai"
    else
        sudo cp kai "$INSTALL_DIR/kai"
    fi
    echo "Installed to $INSTALL_DIR/kai"
fi

echo "Done! Run 'kai --help' to get started."
