#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: ./uninstall.sh [OPTION]"
    echo "Options:"
    echo "  --binary-only  Remove the system-wide application files (requires sudo)"
    echo "  --data-only    Remove the user's FlatBag config and cache files"
    echo "  --all          Remove both system-wide application files and user data (requires sudo)"
    echo "  -h, --help     Show this help message"
}

if [ "$#" -eq 0 ]; then
    usage
    exit 0
fi

MODE=""

set_mode() {
    if [ -n "$MODE" ]; then
        echo "Error: Multiple mode options specified ('--$MODE' and '--$1'). Specify only one." >&2
        echo "Run './uninstall.sh --help' for usage." >&2
        exit 1
    fi
    MODE="$1"
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --binary-only) set_mode "binary-only" ;;
        --data-only)   set_mode "data-only" ;;
        --all)         set_mode "all" ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown parameter passed: $1" >&2
            echo "Run './uninstall.sh --help' for usage." >&2
            exit 1
            ;;
    esac
    shift
done

INSTALL_DIR="/opt/flatbag"
BIN_PATH="/usr/local/bin/flatbag"
APP_ID="io.github.undarbiko.flatbag"
DESKTOP_FILE="/usr/share/applications/${APP_ID}.desktop"
ICON_THEME_DIR="/usr/share/icons/hicolor"

remove_binary() {
    echo "==> Removing system-wide FlatBag files..."

    if [ -d "$INSTALL_DIR" ]; then
        echo "==> Removing $INSTALL_DIR..."
        rm -rf "$INSTALL_DIR"
    else
        echo "==> $INSTALL_DIR not found, skipping."
    fi

    if [ -L "$BIN_PATH" ]; then
        local link_target
        link_target="$(readlink "$BIN_PATH" || true)"
        if [ "$link_target" = "$INSTALL_DIR/flatbag" ]; then
            echo "==> Removing symlink $BIN_PATH..."
            rm -f "$BIN_PATH"
        else
            echo "Warning: $BIN_PATH points to '$link_target' (expected '$INSTALL_DIR/flatbag'), skipping." >&2
        fi
    elif [ -e "$BIN_PATH" ]; then
        echo "Warning: $BIN_PATH is not a symlink, skipping." >&2
    else
        echo "==> Symlink $BIN_PATH not found, skipping."
    fi

    if [ -f "$DESKTOP_FILE" ]; then
        echo "==> Removing desktop entry $DESKTOP_FILE..."
        rm -f "$DESKTOP_FILE"
    else
        echo "==> Desktop entry $DESKTOP_FILE not found, skipping."
    fi

    if [ -d "$ICON_THEME_DIR" ]; then
        echo "==> Removing application icons from $ICON_THEME_DIR..."
        find "$ICON_THEME_DIR" -type f -name "${APP_ID}.*" -delete
    fi

    if command -v gtk-update-icon-cache >/dev/null 2>&1 && [ -d "$ICON_THEME_DIR" ]; then
        echo "==> Updating icon cache..."
        gtk-update-icon-cache -f -t "$ICON_THEME_DIR" || true
    fi

    if command -v update-desktop-database >/dev/null 2>&1 && [ -d "/usr/share/applications" ]; then
        echo "==> Updating desktop database..."
        update-desktop-database /usr/share/applications || true
    fi
}

remove_user_data() {
    local target_user target_home user_config_dir user_cache_dir

    echo "==> Removing FlatBag user config and cache..."

    if [ "$EUID" -eq 0 ]; then
        target_user="${SUDO_USER:-root}"
        if command -v getent >/dev/null 2>&1; then
            target_home="$(getent passwd "$target_user" | cut -d: -f6 || true)"
        else
            target_home="$(awk -F: -v u="$target_user" '$1 == u {print $6}' /etc/passwd)"
        fi
    else
        target_user="${USER:-$(id -un)}"
        target_home="${HOME:-}"
    fi

    if [ -z "$target_home" ] || [ ! -d "$target_home" ]; then
        echo "Warning: Could not resolve home directory for user '$target_user'; skipping user data removal." >&2
        return 0
    fi

    # Use XDG_* paths when running directly as the user, or when preserved under sudo for the target user
    if [ -n "${XDG_CONFIG_HOME:-}" ] && { [ "$EUID" -ne 0 ] || [ -z "${SUDO_USER:-}" ] || [[ "$XDG_CONFIG_HOME" == "$target_home"/* ]]; }; then
        user_config_dir="${XDG_CONFIG_HOME}/flatbag"
    else
        user_config_dir="${target_home}/.config/flatbag"
    fi

    if [ -n "${XDG_CACHE_HOME:-}" ] && { [ "$EUID" -ne 0 ] || [ -z "${SUDO_USER:-}" ] || [[ "$XDG_CACHE_HOME" == "$target_home"/* ]]; }; then
        user_cache_dir="${XDG_CACHE_HOME}/flatbag"
    else
        user_cache_dir="${target_home}/.cache/flatbag"
    fi

    for dir in "$user_config_dir" "$user_cache_dir"; do
        if [ -d "$dir" ]; then
            echo "==> Removing $dir..."
            rm -rf "$dir"
        else
            echo "==> $dir not found, skipping."
        fi
    done
}

case "$MODE" in
    binary-only)
        if [ "$EUID" -ne 0 ]; then
            echo "Please run this script as root for --binary-only (e.g., sudo ./uninstall.sh --binary-only)" >&2
            exit 1
        fi
        remove_binary
        echo "Note: User configuration and cache were preserved."
        echo "      Run './uninstall.sh --data-only' to remove them."
        ;;
    data-only)
        remove_user_data
        ;;
    all)
        if [ "$EUID" -ne 0 ]; then
            echo "Please run this script as root for --all (e.g., sudo ./uninstall.sh --all)" >&2
            exit 1
        fi
        remove_binary
        remove_user_data
        ;;
esac

echo "==> FlatBag uninstall (${MODE}) completed successfully!"
