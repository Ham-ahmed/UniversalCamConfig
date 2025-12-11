#!/bin/sh

# ------------------------------
#   Universal Cam Config Plugin Installer (Updated)
# ------------------------------

PLUGIN_NAME="UniversalCamConfig"
PLUGIN_VERSION="2.1"

clear
echo ""
echo "┌────────────────────────────────────────────────────┐"
echo "│       Universal Cam Config Plugin Installer        │"
echo "├────────────────────────────────────────────────────┤"
echo "│ This script will install the                       │"
        Universal Cam Config plugin                        │"
echo "│ on your Enigma2-based receiver.                    │"
echo "│                                                    │"
echo "│ Version   : 2.1                                    │"
echo "│ Developer : H-Ahmed                                │"
echo "└────────────────────────────────────────────────────┘"
echo ""

# === Configuration ===
ZIP_PATH="/tmp/Universal Cam Config.tar.gz"
EXTRACT_DIR="/tmp/Universal Cam Config"
INSTALL_DIR="/usr/lib/enigma2/python/Plugins/Extensions"

PLUGIN_URL="https://raw.githubusercontent.com/Ham-ahmed/UniversalCamConfig/refs/heads/main/UniversalCamConfig.tar.gz"

# === Step 1: Download ===
echo "[1/4]  Downloading plugin package from:"
echo "    https://raw.githubusercontent.com/Ham-ahmed/UniversalCamConfig/refs/heads/main/UniversalCamConfig.tar.gz"
cd /tmp || { echo "❌ Cannot change directory to /tmp. Aborting."; exit 1; }
wget "$PLUGIN_URL" -O "$ZIP_PATH"
if [ $? -ne 0 ]; then
    echo "❌ Failed to download the plugin. Please check your connection or URL."
    exit 1
fi

# === Step 2: Extract & Install ===
echo "[2/4] 📦 Extracting files and installing..."
unzip -o "$ZIP_PATH" -d "$EXTRACT_DIR" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Extraction failed. The ZIP file may be corrupted."
    exit 1
fi

rm -rf "$INSTALL_DIR/Universal Cam Config"
cp -r "$EXTRACT_DIR/Universal Cam Config" "$INSTALL_DIR"
if [ [ $? -ne 0 ]; then
    echo "❌ Failed to copy plugin to Enigma2 plugins directory."
    exit 1
fi

# === Step 3: Cleanup ===
echo "[3/4] 🧹 Cleaning up..."
rm -rf "$EXTRACT_DIR"
rm -f "$ZIP_PATH"

# === Step 4: Final Message ===
echo "[4/4] ✅ Installation complete!"
echo ""
echo " The plugin \"Universal Cam Config\" (v2.1) has been installed successfully."

# === Subscription info ===
echo ""
echo "#########################################################"
echo "#           your Device will RESTART Now                #"
echo "#########################################################"
sleep 3
killall enigma2

exit 0
