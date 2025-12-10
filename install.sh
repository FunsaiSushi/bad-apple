#!/bin/bash
# Bad Apple Terminal Animation - Curl Installer
# This script downloads and runs the Bad Apple ASCII animation
# Usage: curl -sSL https://raw.githubusercontent.com/FunsaiSushi/BadAppleBash/main/install.sh | sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# GitHub repository URL
REPO_URL="https://github.com/FunsaiSushi/BadAppleBash.git"
REPO_NAME="BadAppleBash"

# Create temporary directory
TMP_DIR=$(mktemp -d -t bad-apple-XXXXXX)
trap "rm -rf $TMP_DIR" EXIT

echo -e "${GREEN}🍎 Bad Apple Terminal Animation${NC}"
echo -e "${YELLOW}Downloading animation files...${NC}"

# Check if git is available
if command -v git &> /dev/null; then
    # Clone the repository
    git clone --depth 1 "$REPO_URL" "$TMP_DIR/$REPO_NAME" > /dev/null 2>&1
    cd "$TMP_DIR/$REPO_NAME"
else
    echo -e "${RED}Error: git is not installed. Please install git to run this animation.${NC}"
    echo "You can install git with:"
    echo "  macOS: brew install git"
    echo "  Ubuntu/Debian: sudo apt-get install git"
    echo "  Fedora: sudo dnf install git"
    exit 1
fi

# Make run.sh executable
chmod +x run.sh

# Check if frames directory exists
if [[ ! -d "frames-ascii" ]]; then
    echo -e "${RED}Error: Frames directory not found. The repository may be incomplete.${NC}"
    exit 1
fi

echo -e "${GREEN}Ready! Starting animation...${NC}"
echo ""

# Run the animation
./run.sh

# Cleanup is handled by trap
