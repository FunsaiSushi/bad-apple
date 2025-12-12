#!/bin/bash
# Original code: Nguyen Khac Trung Kien
# Fork by: Felipe Avelar
# Description: Plays ASCII animation of Bad Apple!! with optional audio
# Usage: ./run.sh [-h|--help]

# Exit on error
set -e

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Function to display usage information
usage() {
    echo
    echo "Usage: $0"
    echo "  -h, --help  Display this help message"
    echo
    exit 0
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

echo

# Ask for mpv audio playback
read -p "Do you want to use mpv to play sound? You need mpv installed to do that. (y/n): " choice

# Validate user input
if [[ ! $choice =~ ^[YyNn]$ ]]; then
    echo "Invalid input. Please enter 'y' or 'n'."
    exit 1
fi

# Handle mpv audio playback
if [[ $choice =~ ^[Yy]$ ]]; then
    # Check if mpv is installed
    if ! command -v mpv &> /dev/null; then
        echo
        echo "mpv is not installed. Please install it to use this feature."
        echo
        exit 1
    fi
    
    # Play audio in background
    mpv "${SCRIPT_DIR}/bad_apple.mp3" > /dev/null 2>&1 &
fi

echo

# Set frames directory
FRAMES_DIR="${SCRIPT_DIR}/frames-ascii"

# Validate frames directory
if [[ ! -d "$FRAMES_DIR" ]]; then
    echo "Error: Frames directory not found at $FRAMES_DIR"
    exit 1
fi

# Clear screen - try multiple methods for Windows compatibility
clear 2>/dev/null || printf "\033[2J\033[H"

# Pre-load frame filenames to avoid repeated ls calls (performance optimization)
frames=($(ls -v "$FRAMES_DIR" 2>/dev/null))

# Play animation with optimized display
for filename in "${frames[@]}"; do
    file="${FRAMES_DIR}/$filename"
    
    if [[ -f "$file" ]]; then
        # Move cursor to top-left - use ANSI escape code directly for better Windows compatibility
        printf "\033[H"
        
        # Display frame
        cat "$file"
    fi
    
    # Adjust sleep time based on OS for smoother playback
    # Windows terminals (Git Bash) tend to render slower, so use slightly faster timing
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$MSYSTEM" ]]; then
        sleep 0.020  # Slightly faster for Windows terminals
    else
        sleep 0.024  # Original timing for Unix/macOS
    fi
done

# Exit with success
exit 0
