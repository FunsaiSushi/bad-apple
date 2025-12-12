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
    
    # Clone with proper error handling
    # Suppress all output (stdout, stderr) and check exit code
    $ErrorActionPreference = "Continue"
    git clone --depth 1 $REPO_URL $REPO_PATH *>$null
    
    # Check if git clone succeeded
    if ($LASTEXITCODE -ne 0) {
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
    
    # Function to detect Windows package manager and provide mpv installation command
    function Get-MpvInstallCommand {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            return "winget install mpv"
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            return "choco install mpv -y"
        } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            return "scoop install mpv"
        } else {
            return $null
        }
    }
    
    # Function to install mpv
    function Install-Mpv {
        $installCmd = Get-MpvInstallCommand
        if ($installCmd) {
            Write-ColorOutput Yellow "Installing mpv..."
            Invoke-Expression $installCmd
            if ($LASTEXITCODE -eq 0 -or $?) {
                Write-ColorOutput Green "mpv installed successfully!"
                return $true
            } else {
                Write-ColorOutput Red "Failed to install mpv. Please install it manually."
                return $false
            }
        } else {
            Write-ColorOutput Yellow "No package manager found (winget, chocolatey, or scoop)."
            Write-Output "Please install mpv manually from: https://mpv.io/installation/"
            return $false
        }
    }
    
    # Check mpv availability and handle installation
    $USE_AUDIO = "n"
    if (Get-Command mpv -ErrorAction SilentlyContinue) {
        Write-ColorOutput Yellow "Audio will be played (mpv detected)"
        $USE_AUDIO = "y"
    } else {
        Write-ColorOutput Yellow "mpv is not installed. Audio playback will be disabled."
        
        # Try to prompt the user (Read-Host works even when piped)
        # Read-Host reads from the console directly, not from stdin
        try {
            Write-Output ""
            $installChoice = Read-Host "Would you like to install mpv for audio playback? (y/n)"
            if ($installChoice -match "^[Yy]$") {
                if (Install-Mpv) {
                    $USE_AUDIO = "y"
                    Write-ColorOutput Green "Audio will be played!"
                } else {
                    Write-ColorOutput Yellow "Continuing without audio..."
                }
            } else {
                Write-ColorOutput Yellow "Continuing without audio..."
            }
        } catch {
            # No console available (non-interactive environment)
            Write-Output ""
            Write-ColorOutput Yellow "To enable audio, install mpv:"
            $installCmd = Get-MpvInstallCommand
            if ($installCmd) {
                Write-Output "  $installCmd"
            } else {
                Write-Output "  Download from: https://mpv.io/installation/"
            }
            Write-ColorOutput Yellow "Running without audio..."
        }
    }
    
    # For Windows, we need to use bash to run run.sh
    # Check if bash is available (Git Bash or WSL)
    $bashPath = $null
    
    # First, try to find bash in PATH
    $bashCmd = Get-Command bash -ErrorAction SilentlyContinue
    if ($bashCmd) {
        $bashPath = $bashCmd.Source
    }
    
    # If not found, check common Git Bash locations
    if (-not $bashPath) {
        $commonPaths = @(
            "${env:ProgramFiles}\Git\bin\bash.exe",
            "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
            "${env:ProgramFiles}\Git\usr\bin\bash.exe"
        )
        
        foreach ($path in $commonPaths) {
            if (Test-Path $path) {
                $bashPath = $path
                break
            }
        }
    }
    
    if ($bashPath) {
        # Patch run.sh to skip the interactive prompt
        $runShContent = Get-Content "run.sh" -Raw
        $runShContent = $runShContent -replace 'read -p "Do you want to use mpv to play sound\? You need mpv installed to do that\. \(y/n\): " choice', "choice=`"$USE_AUDIO`""
        Set-Content "run.sh" -Value $runShContent -NoNewline
        
        # Run the script using bash
        & $bashPath run.sh
    } else {
        Write-ColorOutput Red "Error: bash is not available."
        Write-Output ""
        Write-Output "Since git is working, Git for Windows is likely installed, but bash is not in your PATH."
        Write-Output ""
        Write-Output "Options:"
        Write-Output "  1. Restart PowerShell after installing Git for Windows"
        Write-Output "  2. Add Git Bash to PATH manually"
        Write-Output "  3. Install WSL (Windows Subsystem for Linux)"
        Write-Output "  4. Use Git Bash directly: Open 'Git Bash' and run:"
        Write-Output "     curl -sSL https://raw.githubusercontent.com/FunsaiSushi/bad-apple/main/install.sh | sh"
        exit 1
    }
} finally {
    # Cleanup
    if (Test-Path $TMP_DIR) {
        Remove-Item -Recurse -Force $TMP_DIR -ErrorAction SilentlyContinue
    }
}

