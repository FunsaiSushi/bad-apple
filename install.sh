#!/bin/bash
# Bad Apple Terminal Animation - Curl Installer
# This script downloads and runs the Bad Apple ASCII animation
# Usage: curl -sSL https://raw.githubusercontent.com/FunsaiSushi/bad-apple/main/install.sh | sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# GitHub repository URL
REPO_URL="https://github.com/FunsaiSushi/bad-apple.git"
REPO_NAME="bad-apple"

# Create temporary directory
TMP_DIR=$(mktemp -d -t bad-apple-XXXXXX)
trap "rm -rf $TMP_DIR" EXIT

printf "${GREEN}🍎 Bad Apple Terminal Animation${NC}\n"
printf "${YELLOW}Downloading animation files...${NC}\n"

# Check if git is available
if ! command -v git &> /dev/null; then
    printf "${RED}Error: git is not installed. Please install git to run this animation.${NC}\n"
    echo "You can install git with:"
    echo "  macOS: brew install git"
    echo "  Ubuntu/Debian: sudo apt-get install git"
    echo "  Fedora: sudo dnf install git"
    exit 1
fi

# Clone the repository with error handling
if ! git clone --depth 1 "$REPO_URL" "$TMP_DIR/$REPO_NAME" 2>&1; then
    printf "${RED}Error: Failed to clone repository.${NC}\n"
    printf "${YELLOW}Please check:${NC}\n"
    echo "  1. Your internet connection"
    echo "  2. The repository URL is correct: $REPO_URL"
    echo "  3. The repository exists and is accessible"
    exit 1
fi

cd "$TMP_DIR/$REPO_NAME"

# Check if run.sh exists
if [[ ! -f "run.sh" ]]; then
    printf "${RED}Error: run.sh not found in repository.${NC}\n"
    exit 1
fi

# Make run.sh executable
chmod +x run.sh

# Check if frames directory exists
if [[ ! -d "frames-ascii" ]]; then
    printf "${RED}Error: Frames directory not found. The repository may be incomplete.${NC}\n"
    exit 1
fi

# Check if frames directory has files
if [[ -z "$(ls -A frames-ascii 2>/dev/null)" ]]; then
    printf "${RED}Error: Frames directory is empty.${NC}\n"
    exit 1
fi

printf "${GREEN}Ready! Starting animation...${NC}\n"
echo ""

# Function to detect OS and provide mpv installation command
detect_mpv_install_command() {
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo "brew install mpv"
            return 0
        else
            printf "${YELLOW}Homebrew not found. Install Homebrew first: https://brew.sh${NC}\n"
            return 1
        fi
    elif [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu
        echo "sudo apt-get update && sudo apt-get install -y mpv"
        return 0
    elif [[ -f /etc/redhat-release ]]; then
        # RedHat/Fedora/CentOS
        if command -v dnf &> /dev/null; then
            echo "sudo dnf install -y mpv"
        else
            echo "sudo yum install -y mpv"
        fi
        return 0
    elif [[ -f /etc/arch-release ]]; then
        # Arch Linux
        echo "sudo pacman -S --noconfirm mpv"
        return 0
    else
        printf "${YELLOW}Unknown OS. Please install mpv manually.${NC}\n"
        return 1
    fi
}

# Function to install mpv
install_mpv() {
    local install_cmd=$(detect_mpv_install_command)
    if [[ $? -eq 0 ]]; then
        printf "${YELLOW}Installing mpv...${NC}\n"
        eval "$install_cmd"
        if [[ $? -eq 0 ]]; then
            printf "${GREEN}mpv installed successfully!${NC}\n"
            return 0
        else
            printf "${RED}Failed to install mpv. Please install it manually.${NC}\n"
            return 1
        fi
    else
        return 1
    fi
}

# Check mpv availability and handle installation
USE_AUDIO="n"
if command -v mpv &> /dev/null; then
    printf "${YELLOW}Audio will be played (mpv detected)${NC}\n"
    USE_AUDIO="y"
else
    printf "${YELLOW}mpv is not installed. Audio playback will be disabled.${NC}\n"
    
    # Try to prompt the user (works even when piped via curl | sh)
    # Check if we can read from /dev/tty (the actual terminal)
    if [[ -c /dev/tty ]] 2>/dev/null; then
        # Interactive mode - ask the user
        # Read from /dev/tty to work even when stdin is piped
        echo ""
        read -p "Would you like to install mpv for audio playback? (y/n): " install_choice < /dev/tty
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            if install_mpv; then
                USE_AUDIO="y"
                printf "${GREEN}Audio will be played!${NC}\n"
            else
                printf "${YELLOW}Continuing without audio...${NC}\n"
            fi
        else
            printf "${YELLOW}Continuing without audio...${NC}\n"
        fi
    else
        # No terminal available (non-interactive environment)
        echo ""
        printf "${YELLOW}To enable audio, install mpv:${NC}\n"
        local install_cmd=$(detect_mpv_install_command)
        if [[ $? -eq 0 ]]; then
            echo "  $install_cmd"
        fi
        printf "${YELLOW}Running without audio...${NC}\n"
    fi
fi

# Temporarily modify run.sh to skip the interactive prompt
# Create a backup and patch the read command to use our choice
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS sed requires extension
    sed -i.bak "s/read -p \"Do you want to use mpv to play sound? You need mpv installed to do that. (y\/n): \" choice/choice=\"$USE_AUDIO\"/" run.sh
else
    # Linux sed
    sed -i "s/read -p \"Do you want to use mpv to play sound? You need mpv installed to do that. (y\/n): \" choice/choice=\"$USE_AUDIO\"/" run.sh
fi

# Run the patched script
./run.sh

# Restore the original (though cleanup will remove it anyway since we're in a temp dir)
mv run.sh.bak run.sh 2>/dev/null || true

# Cleanup is handled by trap
