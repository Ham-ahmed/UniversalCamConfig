#!/bin/bash
##setup command=wget -q "--no-check-certificate" "https://raw.githubusercontent.com/Ham-ahmed/UniversalCamConfig/refs/heads/main/UniversalCam.sh" -O - | /bin/sh

######### Only This line to edit with new version ######
version='2.1'
##############################################################

TMPPATH=/tmp/UniversalCamConfig
GITHUB_BASE="https://raw.githubusercontent.com/Ham-ahmed/UniversalCamConfig/main"
GITHUB_API="https://api.github.com/repos/Ham-ahmed/UniversalCamConfig/releases/latest"

# Check architecture and set plugin path
if [ -d /usr/lib64 ]; then
    PLUGINPATH="/usr/lib64/enigma2/python/Plugins/Extensions/UniversalCamConfig"
else
    PLUGINPATH="/usr/lib/enigma2/python/Plugins/Extensions/UniversalCamConfig"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check internet connectivity
check_internet() {
    print_message $BLUE "> Checking internet connection..."
    
    # Try multiple methods to check internet
    if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
        print_message $GREEN "> Internet connection: OK"
        return 0
    elif ping -c 1 -W 3 google.com >/dev/null 2>&1; then
        print_message $GREEN "> Internet connection: OK"
        return 0
    elif wget -q --spider --timeout=10 https://github.com >/dev/null 2>&1; then
        print_message $GREEN "> Internet connection: OK"
        return 0
    else
        print_message $RED "> No internet connection detected!"
        return 1
    fi
}

# Function to check for updates
check_for_updates() {
    print_message $BLUE "> Checking for updates..."
    
    # Try multiple methods to get latest version
    local latest_version=""
    
    # Method 1: Try wget for version.txt
    if command_exists wget; then
        latest_version=$(wget -q --timeout=20 --tries=2 --no-check-certificate -O - "${GITHUB_BASE}/version.txt" 2>/dev/null | head -n 1 | tr -d '\r\n' | xargs)
    fi
    
    # Method 2: Try curl if wget failed
    if [ -z "$latest_version" ] && command_exists curl; then
        latest_version=$(curl -s --connect-timeout 10 --max-time 20 --insecure "${GITHUB_BASE}/version.txt" 2>/dev/null | head -n 1 | tr -d '\r\n' | xargs)
    fi
    
    # Method 3: Try GitHub API
    if [ -z "$latest_version" ] && command_exists curl; then
        latest_version=$(curl -s --connect-timeout 10 --max-time 20 "${GITHUB_API}" 2>/dev/null | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4 | tr -d 'v')
    fi
    
    if [ -z "$latest_version" ]; then
        print_message $YELLOW "> Could not check for updates. Continuing installation..."
        return 1
    fi
    
    # Clean version string
    latest_version=$(echo "$latest_version" | grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    
    if [ -z "$latest_version" ]; then
        print_message $YELLOW "> Could not parse version info. Continuing..."
        return 1
    fi
    
    if [ "$version" != "$latest_version" ]; then
        echo ""
        print_message $YELLOW "#########################################################"
        print_message $YELLOW "#                  NEW VERSION AVAILABLE                #"
        printf "${YELLOW}#               Current version: %-23s#${NC}\n" "$version"
        printf "${YELLOW}#               Latest version: %-24s#${NC}\n" "$latest_version"
        print_message $YELLOW "#        Please download the latest version from:       #"
        print_message $YELLOW "#     https://github.com/Ham-ahmed/UniversalCamConfig   #"
        print_message $YELLOW "#########################################################"
        echo ""
        print_message $YELLOW "> Continuing with current version in 3 seconds..."
        sleep 3
    else
        print_message $GREEN "> You have the latest version ($version)"
    fi
    
    return 0
}

# Function to install package with error handling
install_package() {
    local package=$1
    local package_name=$2
    
    print_message $BLUE "> Installing $package_name..."
    
    if [ -f /var/lib/dpkg/status ] || command_exists apt-get; then
        if command_exists apt-get; then
            apt-get update >/dev/null 2>&1 
            apt-get install -y "$package" --allow-unauthenticated >/dev/null 2>&1
        else
            print_message $RED "> apt-get not found!"
            return 1
        fi
    else
        if command_exists opkg; then
            opkg update >/dev/null 2>&1 
            opkg install "$package" --force-overwrite >/dev/null 2>&1
        else
            print_message $RED "> opkg not found!"
            return 1
        fi
    fi
    
    return $?
}

# Function to check package status
check_package() {
    local package=$1
    if [ -f /var/lib/dpkg/status ]; then
        grep -q "Package: $package" /var/lib/dpkg/status 2>/dev/null && return 0
    fi
    if [ -f /var/lib/opkg/status ]; then
        grep -q "Package: $package" /var/lib/opkg/status 2>/dev/null && return 0
    fi
    return 1
}

# Function to download file with multiple fallbacks
download_file() {
    local url=$1
    local output=$2
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        print_message $YELLOW "> Attempt $((retry_count + 1)) of $max_retries: Downloading from $url"
        
        # Try wget first
        if command_exists wget; then
            if wget --no-check-certificate --timeout=30 --tries=2 -O "$output" "$url" 2>/dev/null; then
                print_message $GREEN "> Download successful using wget!"
                return 0
            fi
        fi
        
        # Try curl if wget failed or not available
        if command_exists curl; then
            if curl -s -L --insecure --connect-timeout 30 --max-time 60 -o "$output" "$url" 2>/dev/null; then
                print_message $GREEN "> Download successful using curl!"
                return 0
            fi
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            print_message $YELLOW "> Download failed, retrying in 2 seconds..."
            sleep 2
        fi
    done
    
    return 1
}

# Main installation starts here
echo ""
print_message $BLUE "================================================"
print_message $BLUE "    UniversalCamConfig v$version Installer     "
print_message $BLUE "================================================"
echo ""

# Check internet connectivity
if ! check_internet; then
    print_message $RED "> Please check your internet connection and try again."
    exit 1
fi

# Initial cleanup
print_message $BLUE "> Initial cleanup..."
[ -d "$TMPPATH" ] && rm -rf "$TMPPATH" > /dev/null 2>&1
sync

# Detect OS type and package manager status
echo ""
if [ -f /var/lib/dpkg/status ]; then
    STATUS="/var/lib/dpkg/status"
    OSTYPE="DreamOs"
    print_message $GREEN "# Detected OE2.5/2.6 (DreamOS) #"
else
    STATUS="/var/lib/opkg/status"
    OSTYPE="Dream"
    print_message $GREEN "# Detected OE2.0 #"
fi

# Detect Python version
echo ""
if command_exists python3; then
    print_message $GREEN "> You have Python3 image"
    PYTHON="PY3"
    Packagesix="python3-six"
    Packagerequests="python3-requests"
elif command_exists python2; then
    print_message $GREEN "> You have Python2 image"
    PYTHON="PY2"
    Packagerequests="python-requests"
else
    print_message $YELLOW "> Python not found! Trying to continue anyway..."
    PYTHON="UNKNOWN"
fi

# Install required packages
echo ""
if [ "$PYTHON" = "PY3" ] && [ -n "$Packagesix" ]; then
    if ! check_package "$Packagesix"; then
        print_message $YELLOW "> Required package $Packagesix not found, installing..."
        if ! install_package "$Packagesix" "python3-six"; then
            print_message $YELLOW "> Warning: Failed to install $Packagesix, continuing anyway..."
        fi
    fi
fi

echo ""
if [ -n "$Packagerequests" ] && ! check_package "$Packagerequests"; then
    print_message $YELLOW "> Need to install $Packagerequests"
    if ! install_package "$Packagerequests" "python-requests"; then
        print_message $YELLOW "> Warning: Failed to install $Packagerequests, continuing anyway..."
    fi
fi

echo ""

# Check for updates before proceeding
check_for_updates

# Cleanup previous installations
print_message $BLUE "> Cleaning up previous installations..."
[ -d "$PLUGINPATH" ] && rm -rf "$PLUGINPATH" > /dev/null 2>&1
sync

# Download and install plugin
print_message $BLUE "> Downloading UniversalCamConfig v$version..."
mkdir -p "$TMPPATH"
cd "$TMPPATH" || { print_message $RED "> Cannot cd to $TMPPATH"; exit 1; }

# Define multiple download URLs
DOWNLOAD_FILENAME="UniversalCamConfig_v${version}.tar.gz"
DOWNLOAD_URLS=(
    "${GITHUB_BASE}/releases/download/v${version}/UniversalCamConfig_v${version}.tar.gz"
    "${GITHUB_BASE}/releases/latest/download/UniversalCamConfig_v${version}.tar.gz"
    "${GITHUB_BASE}/raw/main/releases/UniversalCamConfig_v${version}.tar.gz"
    "https://github.com/Ham-ahmed/UniversalCamConfig/releases/download/v${version}/UniversalCamConfig_v${version}.tar.gz"
    "https://github.com/Ham-ahmed/UniversalCamConfig/releases/latest/download/UniversalCamConfig_v${version}.tar.gz"
)

DOWNLOAD_SUCCESS=0
for url in "${DOWNLOAD_URLS[@]}"; do
    if download_file "$url" "$DOWNLOAD_FILENAME"; then
        DOWNLOAD_SUCCESS=1
        break
    fi
done

# If all URLs fail, try the main script as last resort
if [ $DOWNLOAD_SUCCESS -eq 0 ]; then
    print_message $YELLOW "> Trying alternative download method..."
    
    # Try to download from main branch directly
    ALTERNATIVE_URLS=(
        "${GITHUB_BASE}/archive/refs/heads/main.tar.gz"
        "${GITHUB_BASE}/archive/main.tar.gz"
    )
    
    for url in "${ALTERNATIVE_URLS[@]}"; do
        if download_file "$url" "main.tar.gz"; then
            tar -xzf "main.tar.gz" 2>/dev/null
            if [ -d "UniversalCamConfig-main" ]; then
                # Create the expected tar.gz file
                tar -czf "$DOWNLOAD_FILENAME" "UniversalCamConfig-main/"
                DOWNLOAD_SUCCESS=1
                print_message $GREEN "> Successfully created package from source"
                break
            fi
        fi
    done
fi

if [ $DOWNLOAD_SUCCESS -eq 0 ]; then
    print_message $RED "> All download attempts failed!"
    print_message $YELLOW "> Possible reasons:"
    print_message $YELLOW "> 1. No internet connection"
    print_message $YELLOW "> 2. GitHub is blocked in your network"
    print_message $YELLOW "> 3. Version $version doesn't exist"
    print_message $YELLOW "> 4. Server is temporarily unavailable"
    echo ""
    print_message $YELLOW "> Please try:"
    print_message $YELLOW "> 1. Check your internet connection"
    print_message $YELLOW "> 2. Try again later"
    print_message $YELLOW "> 3. Visit the GitHub page manually:"
    print_message $BLUE ">    https://github.com/Ham-ahmed/UniversalCamConfig"
    exit 1
fi

# Check if file was downloaded and is valid
if [ ! -f "$DOWNLOAD_FILENAME" ]; then
    print_message $RED "> Downloaded file not found!"
    exit 1
fi

# Check file size
FILESIZE=$(stat -c%s "$DOWNLOAD_FILENAME" 2>/dev/null || wc -c < "$DOWNLOAD_FILENAME" 2>/dev/null || echo "0")
if [ "$FILESIZE" -lt 100 ]; then
    print_message $RED "> Downloaded file is too small (${FILESIZE} bytes), may be corrupted!"
    rm -f "$DOWNLOAD_FILENAME"
    exit 1
fi

print_message $GREEN "> File downloaded successfully! Size: $((FILESIZE/1024)) KB"

# Extract the plugin
print_message $BLUE "> Extracting plugin..."
if ! tar -xzf "$DOWNLOAD_FILENAME" 2>/dev/null; then
    print_message $YELLOW "> Standard extraction failed, trying alternative method..."
    
    # Try gzip then tar separately
    if gzip -d "$DOWNLOAD_FILENAME" 2>/dev/null; then
        TAR_FILE="${DOWNLOAD_FILENAME%.gz}"
        if [ -f "$TAR_FILE" ]; then
            if ! tar -xf "$TAR_FILE" 2>/dev/null; then
                print_message $RED "> Extraction failed! File may be corrupted."
                exit 1
            fi
        else
            print_message $RED "> Failed to decompress file!"
            exit 1
        fi
    else
        print_message $RED "> Extraction failed! File may be corrupted or wrong format."
        exit 1
    fi
fi

# Install the plugin
print_message $BLUE "> Installing plugin..."

# Find the extracted directory
EXTRACTED_DIR=""
for dir in "UniversalCamConfig" "UniversalCamConfig-${version}" "UniversalCamConfig-main" "UniversalCamConfig-master"; do
    if [ -d "$dir" ]; then
        EXTRACTED_DIR="$dir"
        break
    fi
done

# If no specific directory found, look for any directory
if [ -z "$EXTRACTED_DIR" ]; then
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "*UniversalCamConfig*" | head -1)
fi

if [ -n "$EXTRACTED_DIR" ] && [ -d "$EXTRACTED_DIR" ]; then
    print_message $GREEN "> Found extracted directory: $EXTRACTED_DIR"
    
    # Copy files to system
    if [ -d "$EXTRACTED_DIR/usr" ]; then
        cp -r "$EXTRACTED_DIR/usr"/* /usr/ 2>/dev/null
    else
        # Look for plugin files
        PLUGIN_SRC=$(find "$EXTRACTED_DIR" -type d -name "*UniversalCamConfig*" -path "*/Plugins/Extensions/*" | head -1)
        if [ -n "$PLUGIN_SRC" ]; then
            mkdir -p "$PLUGINPATH"
            cp -r "$PLUGIN_SRC"/* "$PLUGINPATH/" 2>/dev/null
        else
            # Copy everything to plugin path
            mkdir -p "$PLUGINPATH"
            cp -r "$EXTRACTED_DIR"/* "$PLUGINPATH/" 2>/dev/null
        fi
    fi
else
    print_message $RED "> No extracted directory found!"
    exit 1
fi

# Verify installation
print_message $BLUE "> Verifying installation..."
if [ -d "$PLUGINPATH" ] && [ -f "$PLUGINPATH/__init__.py" ]; then
    print_message $GREEN "> Plugin successfully installed to: $PLUGINPATH"
else
    # Try to find where it was installed
    FOUNDPATH=$(find /usr -name "*UniversalCamConfig*" -type d 2>/dev/null | head -1)
    if [ -n "$FOUNDPATH" ] && [ -f "$FOUNDPATH/__init__.py" ]; then
        print_message $GREEN "> Plugin found at: $FOUNDPATH"
        PLUGINPATH="$FOUNDPATH"
    else
        print_message $RED "> Installation verification failed!"
        print_message $YELLOW "> Trying manual installation..."
        
        # Manual installation from tar
        tar -xzf "$DOWNLOAD_FILENAME" -C / 2>/dev/null
        if [ -d "$PLUGINPATH" ] && [ -f "$PLUGINPATH/__init__.py" ]; then
            print_message $GREEN "> Manual installation successful!"
        else
            print_message $RED "> Installation completely failed!"
            print_message $YELLOW "> Please check disk space and permissions."
            exit 1
        fi
    fi
fi

# Set correct permissions
print_message $BLUE "> Setting permissions..."
chmod -R 755 "$PLUGINPATH" >/dev/null 2>&1
find "$PLUGINPATH" -name "*.py" -exec chmod 644 {} \; >/dev/null 2>&1
find "$PLUGINPATH" -name "*.pyo" -exec chmod 644 {} \; >/dev/null 2>&1
find "$PLUGINPATH" -name "*.pyc" -exec chmod 644 {} \; >/dev/null 2>&1

# Cleanup
print_message $BLUE "> Cleaning up temporary files..."
rm -rf "$TMPPATH" > /dev/null 2>&1
sync

# Success message
echo ""
print_message $GREEN "==================================================================="
print_message $GREEN "===                    INSTALLED SUCCESSFULLY                   ==="
printf "${GREEN}===                  UniversalCamConfig v%-24s===${NC}\n" "$version"
print_message $GREEN "===                 Enigma2 restart is required                  ==="
print_message $GREEN "===              UPLOADED BY  >>>>   HAMDY_AHMED                ==="
print_message $GREEN "==================================================================="

sleep 2
print_message $YELLOW "==================================================================="
print_message $YELLOW "===                        Restarting                           ==="
print_message $YELLOW "==================================================================="

sleep 2

# Ask user if they want to restart
print_message $BLUE "> Do you want to restart Enigma2 now? (y/n): "
read -r -t 10 -n 1 response
echo ""
if [[ "$response" =~ ^[Yy]$ ]] || [ -z "$response" ]; then
    print_message $BLUE "> Restarting Enigma2..."
    
    # Restart enigma2 with multiple methods
    RESTART_SUCCESS=0
    
    # Method 1: systemctl
    if command_exists systemctl && systemctl restart enigma2 >/dev/null 2>&1; then
        RESTART_SUCCESS=1
        print_message $GREEN "> Restart command sent via systemctl"
    
    # Method 2: init.d script
    elif [ -f /etc/init.d/enigma2 ] && /etc/init.d/enigma2 restart >/dev/null 2>&1; then
        RESTART_SUCCESS=1
        print_message $GREEN "> Restart command sent via init.d"
    
    # Method 3: kill and restart
    else
        killall -9 enigma2 >/dev/null 2>&1
        sleep 3
        if [ -f /usr/bin/enigma2.sh ]; then
            /usr/bin/enigma2.sh >/dev/null 2>&1 &
            RESTART_SUCCESS=1
            print_message $GREEN "> Enigma2 killed and restarted"
        elif [ -f /etc/enigma2.sh ]; then
            /etc/enigma2.sh >/dev/null 2>&1 &
            RESTART_SUCCESS=1
            print_message $GREEN "> Enigma2 killed and restarted"
        fi
    fi
    
    if [ $RESTART_SUCCESS -eq 1 ]; then
        print_message $GREEN "> Restart initiated successfully!"
    else
        print_message $YELLOW "> Could not restart Enigma2 automatically."
        print_message $YELLOW "> Please restart your receiver manually."
    fi
else
    print_message $YELLOW "> Skipping restart. Please restart Enigma2 manually later."
fi

echo ""
print_message $GREEN "> Installation complete!"
print_message $YELLOW "> Plugin location: $PLUGINPATH"
sleep 2
exit 0