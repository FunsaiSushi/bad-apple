# Bad Apple Terminal Animation - PowerShell Installer
# This script downloads and runs the Bad Apple ASCII animation on Windows
# Usage: irm https://raw.githubusercontent.com/FunsaiSushi/bad-apple/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# GitHub repository URL
$REPO_URL = "https://github.com/FunsaiSushi/bad-apple.git"
$REPO_NAME = "bad-apple"

Write-ColorOutput Green "🍎 Bad Apple Terminal Animation"
Write-ColorOutput Yellow "Downloading animation files..."

# Check if git is available
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-ColorOutput Red "Error: git is not installed. Please install git to run this animation."
    Write-Output "You can install git from: https://git-scm.com/download/win"
    exit 1
}

# Create temporary directory
$TMP_DIR = Join-Path $env:TEMP "bad-apple-$(New-Guid)"
New-Item -ItemType Directory -Path $TMP_DIR -Force | Out-Null

try {
    # Clone the repository
    Write-Output "Cloning repository..."
    $REPO_PATH = Join-Path $TMP_DIR $REPO_NAME
    git clone --depth 1 $REPO_URL $REPO_PATH 2>&1 | Out-Null
    
    if (-not $?) {
        Write-ColorOutput Red "Error: Failed to clone repository."
        Write-ColorOutput Yellow "Please check:"
        Write-Output "  1. Your internet connection"
        Write-Output "  2. The repository URL is correct: $REPO_URL"
        Write-Output "  3. The repository exists and is accessible"
        exit 1
    }
    
    Set-Location $REPO_PATH
    
    # Check if run.sh exists
    if (-not (Test-Path "run.sh")) {
        Write-ColorOutput Red "Error: run.sh not found in repository."
        exit 1
    }
    
    # Check if frames directory exists
    if (-not (Test-Path "frames-ascii")) {
        Write-ColorOutput Red "Error: Frames directory not found. The repository may be incomplete."
        exit 1
    }
    
    # Check if frames directory has files
    if ((Get-ChildItem "frames-ascii" -ErrorAction SilentlyContinue).Count -eq 0) {
        Write-ColorOutput Red "Error: Frames directory is empty."
        exit 1
    }
    
    Write-ColorOutput Green "Ready! Starting animation..."
    Write-Output ""
    
    # Determine if we should use audio based on mpv availability
    $USE_AUDIO = "n"
    if (Get-Command mpv -ErrorAction SilentlyContinue) {
        Write-ColorOutput Yellow "Audio will be played (mpv detected)"
        $USE_AUDIO = "y"
    } else {
        Write-ColorOutput Yellow "Running without audio (mpv not installed)"
    }
    
    # For Windows, we need to use bash to run run.sh
    # Check if bash is available (Git Bash or WSL)
    if (Get-Command bash -ErrorAction SilentlyContinue) {
        # Patch run.sh to skip the interactive prompt
        $runShContent = Get-Content "run.sh" -Raw
        $runShContent = $runShContent -replace 'read -p "Do you want to use mpv to play sound\? You need mpv installed to do that\. \(y/n\): " choice', "choice=`"$USE_AUDIO`""
        Set-Content "run.sh" -Value $runShContent -NoNewline
        
        # Run the script using bash
        bash run.sh
    } else {
        Write-ColorOutput Red "Error: bash is not available."
        Write-Output "Please install Git for Windows (includes Git Bash) from: https://git-scm.com/download/win"
        Write-Output "Or use WSL (Windows Subsystem for Linux)"
        exit 1
    }
} finally {
    # Cleanup
    if (Test-Path $TMP_DIR) {
        Remove-Item -Recurse -Force $TMP_DIR -ErrorAction SilentlyContinue
    }
}

