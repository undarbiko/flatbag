#!/bin/bash
set -e

CREATE_SOURCE=false
CREATE_BINARY=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--source) CREATE_SOURCE=true ;;
        -b|--binary) CREATE_BINARY=true ;;
        -h|--help)
            echo "Usage: ./build.sh [OPTIONS]"
            echo "Options:"
            echo "  -s, --source    Create a source code archive (.tar.gz)"
            echo "  -b, --binary    Create a binary release archive (.tar.gz)"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

echo "==> Building FlatBag for Linux (Release)..."
flutter build linux --release

# Extract version and build numbers from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d '+' -f 1)
BUILD=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d '+' -f 2)
APP_NAME="flatbag"
PKG_NAME="${APP_NAME}-${VERSION}-${BUILD}-linux-x86_64"

if [ "$CREATE_BINARY" = true ]; then
    echo "==> Creating binary release package..."
    mkdir -p release
    cp -r build/linux/x64/release/bundle "release/${PKG_NAME}"
    tar -czvf "release/${PKG_NAME}.tar.gz" -C release "${PKG_NAME}"
    rm -rf "release/${PKG_NAME}"
    echo "==> Binary package created at release/${PKG_NAME}.tar.gz"
fi

if [ "$CREATE_SOURCE" = true ]; then
    echo "==> Creating source code package..."
    mkdir -p release
    SRC_PKG_NAME="${APP_NAME}-${VERSION}-${BUILD}-source"
    tar -czvf "release/${SRC_PKG_NAME}.tar.gz" --transform "s,^\.,${SRC_PKG_NAME}," --exclude=.git --exclude=.dart_tool --exclude=build --exclude=release --exclude=linux/flutter/ephemeral .
    echo "==> Source package created at release/${SRC_PKG_NAME}.tar.gz"
fi

echo "==> Build process completed successfully!"