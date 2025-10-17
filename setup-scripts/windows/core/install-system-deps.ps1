#!/usr/bin/env pwsh
# Install System Dependencies for Windows

param(
    [string]$RunnerUser = "github-runner"
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
    Write-ColorOutput "[INFO] $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[SUCCESS] $Message" "Green"
}

function Write-Error-Output {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

# Function to check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to install Chocolatey if not present
function Install-ChocolateyIfMissing {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Status "Installing Chocolatey package manager..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Refresh environment variables
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

        Write-Success "Chocolatey installed successfully"
    } else {
        Write-Status "Chocolatey already installed"
    }
}

# Function to install package via Chocolatey
function Install-ChocoPackage {
    param(
        [string]$PackageName,
        [string]$DisplayName = $PackageName
    )

    Write-Status "Installing $DisplayName..."
    try {
        choco install $PackageName -y --no-progress
        Write-Success "$DisplayName installed successfully"
    } catch {
        Write-Error-Output "Failed to install $DisplayName`: $($_.Exception.Message)"
        throw
    }
}

# Main installation
try {
    Write-Status "Starting Windows system dependencies installation..."

    # Check administrator privileges
    if (-not (Test-Administrator)) {
        Write-Error-Output "This script requires Administrator privileges"
        exit 1
    }

    # Install Chocolatey
    Install-ChocolateyIfMissing

    # Install essential system tools
    Write-Status "Installing essential system tools..."

    $packages = @(
        @{ Name = "git"; Display = "Git" },
        @{ Name = "curl"; Display = "cURL" },
        @{ Name = "wget"; Display = "Wget" },
        @{ Name = "7zip"; Display = "7-Zip" },
        @{ Name = "vswhere"; Display = "Visual Studio Locator" },
        @{ Name = "vcredist-all"; Display = "Visual C++ Redistributables" }
    )

    foreach ($package in $packages) {
        Install-ChocoPackage -PackageName $package.Name -DisplayName $package.Display
    }

    # Install Windows SDK
    Write-Status "Installing Windows SDK..."
    try {
        choco install windows-sdk-10.0 -y --no-progress
        Write-Success "Windows SDK installed successfully"
    } catch {
        Write-Warning "Failed to install Windows SDK (may already be installed): $($_.Exception.Message)"
    }

    # Enable Windows Subsystem for Linux (optional)
    Write-Status "Checking WSL availability..."
    try {
        $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
        if ($wslFeature.State -eq "Disabled") {
            Write-Status "WSL is available but not enabled. You can enable it later if needed."
        } elseif ($wslFeature.State -eq "Enabled") {
            Write-Status "WSL is already enabled"
        }
    } catch {
        Write-Warning "Could not check WSL status: $($_.Exception.Message)"
    }

    # Refresh environment variables
    Write-Status "Refreshing environment variables..."
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

    Write-Success "System dependencies installation completed successfully"

} catch {
    Write-Error-Output "System dependencies installation failed: $($_.Exception.Message)"
    exit 1
}