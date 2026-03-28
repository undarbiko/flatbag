#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., sudo ./install.sh)"
  exit 1
fi

BUNDLE_DIR="build/linux/x64/release/bundle"
INSTALL_DIR="/opt/flatbag"
BIN_DIR="/usr/local/bin"

if [ ! -d "$BUNDLE_DIR" ]; then
    echo "Error: Build bundle not found at $BUNDLE_DIR."
    echo "Please run './build.sh' first to compile the application."
    exit 1
fi

echo "==> Installing FlatBag to $INSTALL_DIR..."

# Remove previous installation to avoid stale files
rm -rf "$INSTALL_DIR"

# Create installation directory and copy core app files
mkdir -p "$INSTALL_DIR"
cp -r "$BUNDLE_DIR/flatbag" "$INSTALL_DIR/"
cp -r "$BUNDLE_DIR/data" "$INSTALL_DIR/"
cp -r "$BUNDLE_DIR/lib" "$INSTALL_DIR/"

# Symlink executable so it's globally available in the system PATH
echo "==> Creating symlink in $BIN_DIR..."
ln -sf "$INSTALL_DIR/flatbag" "$BIN_DIR/flatbag"

# Install desktop entries and icons to the system share directory
if [ -d "$BUNDLE_DIR/share" ]; then
    echo "==> Installing desktop file and icons..."
    cp -r "$BUNDLE_DIR/share/"* /usr/share/
fi

echo "==> Updating icon cache..."
gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true

echo "==> FlatBag installed successfully!"