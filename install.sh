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

# Patch run.sh to skip the interactive prompt
# Determine if we should use audio based on mpv availability
USE_AUDIO="n"
if command -v mpv &> /dev/null; then
    printf "${YELLOW}Audio will be played (mpv detected)${NC}\n"
    USE_AUDIO="y"
else
    printf "${YELLOW}Running without audio (mpv not installed)${NC}\n"
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
