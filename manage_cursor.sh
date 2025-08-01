#!/bin/bash

# Check Ubuntu version and exit if not 24.04
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null)
if [ "$UBUNTU_VERSION" != "24.04" ]; then
    echo "-------------------------------------"
    echo "==============================="
    echo "❌ This script is for Ubuntu 24.04 only."
    echo "==============================="
    echo "You are running Ubuntu $UBUNTU_VERSION."
    echo "This script is for Ubuntu 24.04 only."
    echo "Please use the installer for Ubuntu 22.04:"
    echo "https://github.com/hieutt192/Cursor-ubuntu/tree/main"
    echo "-------------------------------------"
    exit 1
fi

# --- Global Variables ---
CURSOR_EXTRACT_DIR="/opt/Cursor"                   # Where the AppImage is extracted
ICON_FILENAME_ON_DISK="cursor-icon.png"            # Main icon name
ALT_ICON_FILENAME_ON_DISK="cursor-black-icon.png"  # Secondary icon (dark variant)
ICON_PATH="${CURSOR_EXTRACT_DIR}/${ICON_FILENAME_ON_DISK}"
EXECUTABLE_PATH="${CURSOR_EXTRACT_DIR}/AppRun"     # Main executable after extract
DESKTOP_ENTRY_PATH="/usr/share/applications/cursor.desktop"

# --- Utility Functions ---
print_error() {
    echo "==============================="
    echo "❌ $1"
    echo "==============================="
}

print_success() {
    echo "==============================="
    echo "✅ $1"
    echo "==============================="
}

print_info() {
    echo "==============================="
    echo "ℹ️ $1"
    echo "==============================="
}

# --- Dependency Management ---
install_dependencies() {
    local deps=("curl" "jq" "wget" "figlet")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "📦 $dep is not installed. Installing..."
            sudo apt-get update
            sudo apt-get install -y "$dep"
        fi
    done
}

# --- Download Latest Cursor AppImage Function ---
download_latest_cursor_appimage() {
    API_URL="https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable"
    USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    DOWNLOAD_PATH="/tmp/latest-cursor.AppImage"

    FINAL_URL=$(curl -sL -A "$USER_AGENT" "$API_URL" | jq -r '.url // .downloadUrl')
    if [ -z "$FINAL_URL" ] || [ "$FINAL_URL" = "null" ]; then
        print_error "Could not retrieve the final AppImage URL from the Cursor API."
        return 1
    fi

    echo "⬇️ Downloading latest Cursor AppImage from: $FINAL_URL"
    wget -q -O "$DOWNLOAD_PATH" "$FINAL_URL"
    if [ $? -eq 0 ] && [ -s "$DOWNLOAD_PATH" ]; then
        echo "✅ Successfully downloaded the Cursor AppImage!"
        echo "$DOWNLOAD_PATH"
        return 0
    else
        print_error "Failed to download the AppImage."
        return 1
    fi
}

# --- Download Functions ---
get_appimage_path() {
    local operation="$1"  # "install" or "update"
    local action_text=""

    if [ "$operation" = "update" ]; then
        action_text="new Cursor AppImage"
    else
        action_text="Cursor AppImage"
    fi

    echo "How do you want to provide the $action_text?" >&2
    echo "📥 1. Automatically download the latest version (recommended)" >&2
    echo "📁 2. Specify local file path manually" >&2
    echo "------------------------" >&2
    read -rp "Choose 1 or 2: " appimage_option >&2

    local cursor_download_path=""

    if [ "$appimage_option" = "1" ]; then
        echo "⏳ Downloading the latest Cursor AppImage, please wait..." >&2
        cursor_download_path=$(download_latest_cursor_appimage 2>/dev/null | tail -n 1)
        if [ $? -ne 0 ] || [ ! -f "$cursor_download_path" ]; then
            print_error "Auto-download failed!" >&2
            echo "🤔 Would you like to specify the local file path manually instead? (y/n)" >&2
            read -r retry_option >&2
            if [[ "$retry_option" =~ ^[Yy]$ ]]; then
                if [ "$operation" = "update" ]; then
                    read -rp "📂 Enter new Cursor AppImage file path: " cursor_download_path >&2
                else
                    read -rp "📂 Enter Cursor AppImage file path: " cursor_download_path >&2
                fi
            else
                echo "❌ Exiting." >&2
                exit 1
            fi
        fi
    else
        if [ "$operation" = "update" ]; then
            read -rp "📂 Enter new Cursor AppImage file path: " cursor_download_path >&2
        else
            read -rp "📂 Enter Cursor AppImage file path: " cursor_download_path >&2
        fi
    fi

    # Return only the path
    echo "$cursor_download_path"
}

# --- AppImage Processing ---
process_appimage() {
    local source_path="$1"
    local operation="$2"  # "install" or "update"

    if [ ! -f "$source_path" ]; then
        print_error "File does not exist at: $source_path"
        exit 1
    fi

    chmod +x "$source_path"
    echo "📦 Extracting AppImage..."
    (cd /tmp && "$source_path" --appimage-extract > /dev/null)
    if [ ! -d "/tmp/squashfs-root" ]; then
        print_error "Failed to extract the AppImage."
        sudo rm -f "$source_path"
        exit 1
    fi
    echo "✅ Extraction successful!"

    if [ "$operation" = "update" ]; then
        # ── Preserve icon(s) ────────────────────────────────
        local icon_backup_dir="/tmp/cursor_icon_backup.$$"
        mkdir -p "$icon_backup_dir"
        for icon_file in "$ICON_FILENAME_ON_DISK" "$ALT_ICON_FILENAME_ON_DISK"; do
            if [ -f "${CURSOR_EXTRACT_DIR}/${icon_file}" ]; then
                cp "${CURSOR_EXTRACT_DIR}/${icon_file}" "${icon_backup_dir}/"
            fi
        done

        echo "🗑️ Removing old version at ${CURSOR_EXTRACT_DIR}..."
        sudo rm -rf "${CURSOR_EXTRACT_DIR:?}"/*
    else
        echo "📁 Creating installation directory at ${CURSOR_EXTRACT_DIR}..."
        sudo mkdir -p "$CURSOR_EXTRACT_DIR"
    fi

    echo "📦 Deploying new version..."
    sudo rsync -a --remove-source-files /tmp/squashfs-root/ "$CURSOR_EXTRACT_DIR/"

    if [ "$operation" = "update" ]; then
        # ── Restore icon(s) ────────────────────────────────
        for icon_file in "$ICON_FILENAME_ON_DISK" "$ALT_ICON_FILENAME_ON_DISK"; do
            if [ -f "${icon_backup_dir}/${icon_file}" ]; then
                sudo mv "${icon_backup_dir}/${icon_file}" "${CURSOR_EXTRACT_DIR}/${icon_file}"
            fi
        done
        rm -rf "$icon_backup_dir"
    fi

    echo "🔧 Setting proper permissions..."
    # Set directory permissions (755 = rwxr-xr-x)
    sudo chmod -R 755 "$CURSOR_EXTRACT_DIR"
    # Ensure executable is properly set
    sudo chmod +x "$EXECUTABLE_PATH"
    if [ $? -ne 0 ]; then
        print_error "Failed to set permissions. Please check system configuration."
        exit 1
    fi
    echo "✅ Permissions set successfully."

    sudo rm -f "$source_path"
    sudo rm -rf /tmp/squashfs-root
}
# --- Installation Function ---
installCursor() {
    if [ -d "$CURSOR_EXTRACT_DIR" ]; then
        print_info "Cursor is already installed at $CURSOR_EXTRACT_DIR. Choose the Update option instead."
        exec "$0"
    fi

    figlet -f slant "Install Cursor"
    echo "💿 Installing Cursor AI IDE on Ubuntu..."

    install_dependencies

    local cursor_download_path=$(get_appimage_path "install")

    process_appimage "$cursor_download_path" "install"

    # ── Icon & desktop entry ───────────────────────────────────────────────
    read -rp "🎨 Enter icon filename from GitHub (e.g., cursor-icon.png): " icon_name_from_github
    local icon_download_url="https://raw.githubusercontent.com/hieutt192/Cursor-ubuntu/main/images/$icon_name_from_github"
    echo "🎨 Downloading icon to $ICON_PATH..."
    sudo curl -L "$icon_download_url" -o "$ICON_PATH"

    echo "🖥️ Creating .desktop entry for Cursor..."
    sudo tee "$DESKTOP_ENTRY_PATH" >/dev/null <<EOL
[Desktop Entry]
Name=Cursor AI IDE
Exec=${EXECUTABLE_PATH} --no-sandbox
Icon=${ICON_PATH}
Type=Application
Categories=Development;
EOL

    # Set standard permissions for .desktop file (644 = rw-r--r--)
    echo "🔧 Setting desktop entry permissions..."
    sudo chmod 644 "$DESKTOP_ENTRY_PATH"
    if [ $? -ne 0 ]; then
        print_error "Failed to set desktop entry permissions."
        exit 1
    fi
    echo "✅ Desktop entry created with proper permissions."

    print_success "Cursor AI IDE installation complete!"
}

# --- Update Function ---
updateCursor() {
    if [ ! -d "$CURSOR_EXTRACT_DIR" ]; then
        print_error "Cursor is not installed. Please run the installer first."
        exec "$0"
    fi

    figlet -f slant "Update Cursor"
    echo "🆙 Updating Cursor AI IDE..."

    install_dependencies

    local cursor_download_path=$(get_appimage_path "update")

    process_appimage "$cursor_download_path" "update"

    print_success "Cursor AI IDE update complete!"
}

# --- Restore Icons Function ---
restoreIcons() {
    if [ ! -d "$CURSOR_EXTRACT_DIR" ]; then
        print_error "Cursor is not installed. Please run the installer first."
        exec "$0"
    fi

    figlet -f slant "Restore Icons"
    echo "🎨 Restoring Cursor AI IDE icons..."

    echo "Available icons:"
    echo "1. cursor-icon.png - Standard Cursor logo with blue background"
    echo "2. cursor-black-icon.png - Cursor logo with dark/black background"
    echo "------------------------"
    read -rp "Enter icon filename (e.g., cursor-icon.png): " icon_name_from_github

    if [ -z "$icon_name_from_github" ]; then
        print_error "No icon filename provided. Exiting."
        exit 1
    fi

    local icon_download_url="https://raw.githubusercontent.com/hieutt192/Cursor-ubuntu/main/images/$icon_name_from_github"
    echo "🎨 Downloading icon to $ICON_PATH..."

    # Download the new icon
    if sudo curl -L "$icon_download_url" -o "$ICON_PATH"; then
        echo "✅ Icon downloaded successfully!"

        # Update the desktop entry with the new icon
        echo "🖥️ Updating desktop entry with new icon..."
        sudo tee "$DESKTOP_ENTRY_PATH" >/dev/null <<EOL
[Desktop Entry]
Name=Cursor AI IDE
Exec=${EXECUTABLE_PATH} --no-sandbox
Icon=${ICON_PATH}
Type=Application
Categories=Development;
EOL

        # Set proper permissions for .desktop file
        sudo chmod 644 "$DESKTOP_ENTRY_PATH"
        if [ $? -eq 0 ]; then
            echo "✅ Desktop entry updated with proper permissions."
            print_success "Icon restoration complete!"
        else
            print_error "Failed to set desktop entry permissions."
            exit 1
        fi
    else
        print_error "Failed to download the icon. Please check the filename and try again."
        exit 1
    fi
}

# --- Main Menu ---
install_dependencies

figlet -f slant "Cursor AI IDE"
echo "For Ubuntu 24.04"
echo "-------------------------------------------------"
echo "  /\\_/\\"
echo " ( o.o )"
echo "  > ^ <"
echo "------------------------"
echo "💿 1. Install Cursor"
echo "🆙 2. Update Cursor"
echo "🎨 3. Restore Icons"
echo "Note: If the menu reappears after choosing 1, 2, or 3, check any error message above."
echo "------------------------"

read -rp "Please choose an option (1, 2, or 3): " choice

case $choice in
    1)
        installCursor
        ;;
    2)
        updateCursor
        ;;
    3)
        restoreIcons
        ;;
    *)
        print_error "Invalid option. Exiting."
        exit 1
        ;;
esac

exit 0
