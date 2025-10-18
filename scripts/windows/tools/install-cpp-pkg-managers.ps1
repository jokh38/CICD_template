#!/usr/bin/env pwsh
# Install C++ Package Managers (Conan, vcpkg) for Windows
#
# This script handles user-level C++ package manager installations on Windows.
# Installs:
# - vcpkg: Microsoft's C++ package manager
# - Conan: Cross-platform C/C++ package manager

param(
    [string]$DeveloperUser = "developer",
    [string]$VcpkgInstallPath = "$env:ProgramFiles\vcpkg"
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Status {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-ColorOutput "[$timestamp] [INFO] $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-ColorOutput "[$timestamp] [SUCCESS] $Message" "Green"
}

function Write-ErrorOutput {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-ColorOutput "[$timestamp] [ERROR] $Message" "Red"
}

function Write-Warning {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-ColorOutput "[$timestamp] [WARNING] $Message" "Yellow"
}

# Function to check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check for Administrator privileges
if (-not (Test-Administrator)) {
    Write-ErrorOutput "This script requires Administrator privileges for vcpkg installation"
    Write-ErrorOutput "Please run PowerShell as Administrator and try again"
    exit 1
}

# Function to test network connectivity
function Test-NetworkConnectivity {
    param([string]$HostName = "github.com")

    try {
        $result = Test-Connection -ComputerName $HostName -Count 1 -Quiet
        return $result
    } catch {
        return $false
    }
}

# Install vcpkg
Write-Status "Installing vcpkg..."

if (Test-Path $VcpkgInstallPath) {
    Write-Status "vcpkg already installed at $VcpkgInstallPath. Skipping installation."
} else {
    # Check network connectivity
    if (-not (Test-NetworkConnectivity -HostName "github.com")) {
        Write-ErrorOutput "Network connectivity required for vcpkg installation"
        Write-ErrorOutput "Cannot reach github.com"
        exit 1
    }

    # Check if git is available
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-ErrorOutput "Git is not installed or not in PATH"
        Write-ErrorOutput "Please install Git first: winget install Git.Git"
        exit 1
    }

    Write-Status "Cloning vcpkg repository to $VcpkgInstallPath..."
    try {
        # Clone vcpkg repository
        git clone https://github.com/microsoft/vcpkg.git $VcpkgInstallPath

        Write-Status "Bootstrapping vcpkg..."

        # Run bootstrap script
        $bootstrapScript = Join-Path $VcpkgInstallPath "bootstrap-vcpkg.bat"
        if (Test-Path $bootstrapScript) {
            & $bootstrapScript

            if ($LASTEXITCODE -eq 0) {
                # Add vcpkg to PATH permanently (system-wide)
                $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
                if ($currentPath -notlike "*$VcpkgInstallPath*") {
                    Write-Status "Adding vcpkg to system PATH..."
                    [Environment]::SetEnvironmentVariable(
                        "Path",
                        "$currentPath;$VcpkgInstallPath",
                        "Machine"
                    )

                    # Also add to current session
                    $env:Path += ";$VcpkgInstallPath"
                }

                # Set VCPKG_ROOT environment variable
                Write-Status "Setting VCPKG_ROOT environment variable..."
                [Environment]::SetEnvironmentVariable("VCPKG_ROOT", $VcpkgInstallPath, "Machine")
                $env:VCPKG_ROOT = $VcpkgInstallPath

                Write-Success "vcpkg installed successfully at $VcpkgInstallPath"
            } else {
                Write-ErrorOutput "Failed to bootstrap vcpkg"
                exit 1
            }
        } else {
            Write-ErrorOutput "Bootstrap script not found: $bootstrapScript"
            exit 1
        }
    } catch {
        Write-ErrorOutput "Failed to install vcpkg: $($_.Exception.Message)"
        exit 1
    }
}

# Install Conan
Write-Status "Installing Conan..."

# Check if Python is available
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-ErrorOutput "Python is not installed or not in PATH"
    Write-ErrorOutput "Please install Python first: winget install Python.Python.3.11"
    exit 1
}

# Check if pip is available
if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
    Write-ErrorOutput "pip is not installed or not in PATH"
    Write-ErrorOutput "Please ensure Python installation includes pip"
    exit 1
}

try {
    # Check if Conan is already installed
    $conanInstalled = $false
    try {
        $conanVersion = conan --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Conan already installed: $conanVersion"
            $conanInstalled = $true
        }
    } catch {
        # Conan not installed, continue with installation
    }

    if (-not $conanInstalled) {
        # Upgrade pip first
        Write-Status "Upgrading pip..."
        python -m pip install --upgrade pip

        # Install Conan
        Write-Status "Installing Conan package manager..."
        python -m pip install conan

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Conan installed successfully"

            # Verify installation
            $conanVersion = conan --version 2>&1
            Write-Status "Installed Conan version: $conanVersion"
        } else {
            Write-ErrorOutput "Failed to install Conan"
            exit 1
        }
    }
} catch {
    Write-ErrorOutput "Failed to install Conan: $($_.Exception.Message)"
    exit 1
}

# Create Conan default profile if it doesn't exist
Write-Status "Configuring Conan default profile..."
try {
    $profileCheck = conan profile detect --force 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Conan default profile created"
    } else {
        Write-Warning "Could not create Conan default profile automatically"
        Write-Warning "You may need to run 'conan profile detect' manually"
    }
} catch {
    Write-Warning "Could not configure Conan profile: $($_.Exception.Message)"
}

# Summary
Write-Host ""
Write-Success "C++ Package Managers Installation Complete"
Write-Host ""
Write-Host "Installed Components:" -ForegroundColor Cyan
Write-Host "  ✓ vcpkg - $VcpkgInstallPath" -ForegroundColor Green
Write-Host "  ✓ Conan - $(conan --version 2>&1)" -ForegroundColor Green
Write-Host ""
Write-Host "Environment Variables Set:" -ForegroundColor Cyan
Write-Host "  - VCPKG_ROOT = $VcpkgInstallPath" -ForegroundColor Yellow
Write-Host "  - PATH updated to include vcpkg" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Restart your terminal or IDE to load new PATH variables"
Write-Host "  2. Verify installation:"
Write-Host "     - vcpkg version"
Write-Host "     - conan --version"
Write-Host "  3. Use vcpkg: vcpkg install <package>"
Write-Host "  4. Use Conan: conan install <package>"
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "  - vcpkg: https://vcpkg.io/"
Write-Host "  - Conan: https://docs.conan.io/"
Write-Host ""

exit 0
