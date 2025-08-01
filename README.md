# Cursor AI IDE Installer for Ubuntu 24.04

A simple and user-friendly script to install, update, and manage the Cursor AI IDE on Ubuntu 24.04. The script supports automatic download of the latest AppImage and provides easy icon customization.

---

## ✨ Features

- **🚀 Automatic Installation**: Download and install the latest Cursor AppImage with a single command
- **🔄 Easy Updates**: Update Cursor to the latest version using the same script
- **🎨 Icon Customization**: Choose between light and dark theme icons during installation
- **🔄 Icon Restoration**: Change your icon selection after installation if needed
- **📦 Dependency Management**: Automatically installs required tools (`curl`, `wget`, `jq`, `figlet`)
- **🖥️ Desktop Integration**: Creates proper desktop entries for easy launching
- **🛡️ Safety Checks**: Validates Ubuntu version and provides comprehensive error handling

---

## 🎨 Available Icons

- <img src="images/cursor-icon.png" alt="Cursor Icon" width="24"/> `cursor-icon.png` – Standard Cursor logo with blue background
- <img src="images/cursor-black-icon.png" alt="Cursor Black Icon" width="24"/> `cursor-black-icon.png` – Cursor logo with dark/black background

---

## 🚀 Quick Start

### Prerequisites
- Ubuntu 24.04 (or compatible)
- Internet connection
- `sudo` privileges

### Installation

1. **Download and make executable:**
   ```bash
   chmod +x manage_cursor.sh
   ```

2. **Run the script:**
   ```bash
   ./manage_cursor.sh
   ```

3. **Choose your option:**
   - `1` - **Install Cursor** (first-time installation)
   - `2` - **Update Cursor** (update existing installation)
   - `3` - **Restore Icons** (change icon after installation)

4. **Follow the prompts:**
   - Choose auto-download (recommended) or specify local file path
   - Select your preferred icon theme
   - Wait for installation to complete

5. **Launch Cursor:**
   - Find "Cursor AI IDE" in your application menu
   - Or run: `/opt/Cursor/AppRun --no-sandbox`

---

## 🛠️ What the Script Does

The script handles the complete installation process:

1. **System Validation**: Checks Ubuntu version compatibility
2. **Dependency Installation**: Installs required tools automatically
3. **AppImage Processing**: Downloads and extracts the Cursor AppImage
4. **System Integration**: Creates desktop entries and sets proper permissions
5. **Icon Management**: Downloads and applies your chosen icon theme

---

## 🎨 Icon Management

### During Installation
You'll be prompted to choose an icon filename:
- `cursor-icon.png` for light theme
- `cursor-black-icon.png` for dark theme

### After Installation
Use option `3` (Restore Icons) to change your icon selection:
1. Run the script: `./manage_cursor.sh`
2. Choose option `3`
3. Enter the desired icon filename
4. The script will download and apply the new icon automatically

---

## ❌ Uninstallation

To completely remove Cursor:

```bash
# Remove application files
sudo rm -rf /opt/Cursor

# Remove desktop entry
sudo rm -f /usr/share/applications/cursor.desktop
```

---

## 🧩 Troubleshooting

**Common Issues:**
- **Wrong Ubuntu version**: Script is designed for Ubuntu 24.04 only
- **Permission denied**: Ensure you have `sudo` privileges
- **Download fails**: Check your internet connection
- **Icon not showing**: Try the "Restore Icons" option
- **App won't start**: Run from terminal to see error messages

**Script Permissions:**
```bash
chmod +x manage_cursor.sh
```

---

## 📝 Notes

- The script automatically handles all dependencies
- Icons are downloaded from this repository's `images` directory
- Desktop entries are created with proper permissions
- The `--no-sandbox` flag is used for compatibility
- All temporary files are cleaned up automatically

---

For questions or issues, please open an issue in this repository.
