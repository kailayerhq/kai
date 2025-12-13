#!/bin/bash
set -e

# Kai CLI installer
# Usage: curl -fsSL https://kailayer.com/install.sh | bash

GITHUB_REPO="kailayerhq/kai"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="kai"

echo "Installing kai CLI..."

# Detect OS and architecture
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$OS" in
    linux)
        OS="linux"
        ;;
    darwin)
        OS="darwin"
        ;;
    *)
        echo "Error: Unsupported OS: $OS"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64)
        ARCH="amd64"
        ;;
    arm64|aarch64)
        ARCH="arm64"
        ;;
    *)
        echo "Error: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

BINARY="kai-${OS}-${ARCH}"
echo "Detected: $OS/$ARCH"

# Get latest release tag from GitHub
echo "Fetching latest release..."
LATEST_RELEASE=$(curl -fsSL "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_RELEASE" ]; then
    echo "Error: Could not determine latest release"
    exit 1
fi

echo "Latest release: $LATEST_RELEASE"

# Download URL
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${LATEST_RELEASE}/${BINARY}.gz"

# Create temp directory
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# Download binary
echo "Downloading $BINARY..."
if ! curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/${BINARY}.gz"; then
    echo "Error: Failed to download from $DOWNLOAD_URL"
    echo ""
    echo "Pre-built binary may not be available for your platform ($OS/$ARCH)."
    echo "Please build from source instead:"
    echo "  git clone https://github.com/${GITHUB_REPO}.git"
    echo "  cd kai/kai-cli"
    echo "  ./build.sh"
    exit 1
fi

# Extract
echo "Extracting..."
gunzip "$TMP_DIR/${BINARY}.gz"
chmod +x "$TMP_DIR/${BINARY}"

# Install
echo "Installing to $INSTALL_DIR..."
if [ -w "$INSTALL_DIR" ]; then
    mv "$TMP_DIR/${BINARY}" "$INSTALL_DIR/$BINARY_NAME"
else
    sudo mv "$TMP_DIR/${BINARY}" "$INSTALL_DIR/$BINARY_NAME"
fi

echo ""
echo "Successfully installed kai to $INSTALL_DIR/$BINARY_NAME"
echo "Run 'kai --help' to get started."
