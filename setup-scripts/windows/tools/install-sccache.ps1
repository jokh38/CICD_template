#!/usr/bin/env pwsh
# Install sccache for Windows

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

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

# Function to check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to download file with progress
function Download-FileWithProgress {
    param(
        [string]$Url,
        [string]$OutputPath
    )

    try {
        $webClient = New-Object System.Net.WebClient
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
            $percent = $Event.SourceEventArgs.ProgressPercentage
            Write-Progress -Activity "Downloading" -Status "$percent% Complete:" -PercentComplete $percent
        } | Out-Null

        $webClient.DownloadFile($Url, $OutputPath)
        $webClient.Dispose()
        Write-Progress -Activity "Downloading" -Completed
    } catch {
        Write-Error-Output "Failed to download file: $($_.Exception.Message)"
        throw
    }
}

# Function to install sccache
function Install-SCCache {
    Write-Status "Installing sccache..."

    try {
        # Check if sccache is already installed
        try {
            $sccacheVersion = sccache --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Status "sccache already installed: $sccacheVersion"
                return
            }
        } catch {
            # sccache not found, proceed with installation
        }

        # Get latest release information from GitHub API
        Write-Status "Getting latest sccache release information..."
        $apiUrl = "https://api.github.com/repos/mozilla/sccache/releases/latest"
        $releaseInfo = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        $tagName = $releaseInfo.tag_name
        $version = $tagName.TrimStart('v')

        Write-Status "Latest sccache version: $version"

        # Determine architecture and download URL
        $architecture = if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "i686" }

        # Find the appropriate Windows asset
        $asset = $releaseInfo.assets | Where-Object { $_.name -like "*windows*$architecture*" -and $_.name -like "*.zip*" } | Select-Object -First 1

        if (-not $asset) {
            # Fallback to a generic pattern
            $asset = $releaseInfo.assets | Where-Object { $_.name -like "*windows*" -and $_.name -like "*.zip*" } | Select-Object -First 1
        }

        if (-not $asset) {
            throw "Could not find appropriate sccache Windows binary for architecture: $architecture"
        }

        $downloadUrl = $asset.browser_download_url
        $fileName = $asset.name
        $downloadPath = Join-Path $env:TEMP $fileName
        $extractPath = Join-Path $env:TEMP "sccache-extract"

        Write-Status "Downloading sccache from: $downloadUrl"
        Download-FileWithProgress -Url $downloadUrl -OutputPath $downloadPath

        # Extract the archive
        Write-Status "Extracting sccache..."
        if (Test-Path $extractPath) {
            Remove-Item -Path $extractPath -Recurse -Force
        }
        Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force

        # Find the sccache executable
        $sccacheExe = Get-ChildItem -Path $extractPath -Recurse -Filter "sccache.exe" | Select-Object -First 1

        if (-not $sccacheExe) {
            throw "sccache.exe not found in extracted archive"
        }

        # Install to Program Files
        $installDir = "${env:ProgramFiles}\sccache"
        if (-not (Test-Path $installDir)) {
            New-Item -Path $installDir -ItemType Directory -Force | Out-Null
        }

        $sccacheDest = Join-Path $installDir "sccache.exe"
        Copy-Item -Path $sccacheExe.FullName -Destination $sccacheDest -Force

        # Add to PATH
        $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*$installDir*") {
            [System.Environment]::SetEnvironmentVariable("PATH", $currentPath + ";$installDir", "Machine")
            Write-Status "Added sccache to system PATH"
        }

        # Cleanup
        Remove-Item -Path $downloadPath -ErrorAction SilentlyContinue
        Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue

        Write-Success "sccache installed successfully to: $installDir"

    } catch {
        Write-Error-Output "Failed to install sccache: $($_.Exception.Message)"
        throw
    }
}

# Function to create sccache configuration
function Set-SCCacheConfiguration {
    Write-Status "Setting up sccache configuration..."

    try {
        # Create config directory
        $configDir = Join-Path $env:USERPROFILE ".config\sccache"
        if (-not (Test-Path $configDir)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        }

        # Create configuration file
        $configFile = Join-Path $configDir "config"
        $configContent = @"
# sccache configuration
cache_dir = "~\\cache\\sccache"
max_size = "5G"

# Windows-specific settings
# You can customize these based on your needs
"@

        $configContent | Out-File -FilePath $configFile -Encoding UTF8 -Force

        # Create cache directory
        $cacheDir = Join-Path $env:USERPROFILE "cache\sccache"
        if (-not (Test-Path $cacheDir)) {
            New-Item -Path $cacheDir -ItemType Directory -Force | Out-Null
        }

        Write-Success "sccache configuration created"

    } catch {
        Write-Error-Output "Failed to create sccache configuration: $($_.Exception.Message)"
        throw
    }
}

# Function to setup sccache as compiler wrapper
function Set-SCCacheCompilerWrapper {
    Write-Status "Setting up sccache as compiler wrapper..."

    try {
        # Set environment variables for sccache
        $envVariables = @(
            "SCCACHE_CACHE_SIZE=5G",
            "SCCACHE_DIR=$env:USERPROFILE\cache\sccache",
            "SCCACHE_IDLE_TIMEOUT=7200",
            "SCCACHE_LOG=info"
        )

        foreach ($var in $envVariables) {
            $name, $value = $var -split '=', 2
            [System.Environment]::SetEnvironmentVariable($name, $value, "User")
            Write-Status "Set environment variable: $name"
        }

        # Note: To use sccache as compiler wrapper, users need to:
        # 1. Set CC=clang-cl (or cl.exe for MSVC) to use sccache
        # 2. Set CXX=clang++ (or cl.exe for MSVC) to use sccache
        # This will be documented in the summary

        Write-Success "sccache compiler wrapper environment configured"

    } catch {
        Write-Error-Output "Failed to setup sccache compiler wrapper: $($_.Exception.Message)"
        throw
    }
}

# Function to verify sccache installation
function Test-SCCacheInstallation {
    Write-Status "Verifying sccache installation..."

    try {
        # Refresh environment variables
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

        # Test sccache command
        $sccacheVersion = sccache --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "sccache is working: $sccacheVersion"
        } else {
            Write-Warning "sccache not working properly"
        }

        # Test sccache stats
        $stats = sccache --show-stats 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "sccache statistics are accessible"
        } else {
            Write-Warning "sccache statistics not accessible"
        }

    } catch {
        Write-Warning "Could not verify sccache installation: $($_.Exception.Message)"
    }
}

# Main installation
try {
    Write-Status "Starting Windows sccache installation..."

    # Check administrator privileges for system-wide installation
    $isAdmin = Test-Administrator
    if (-not $isAdmin) {
        Write-Warning "Not running as Administrator. Some features may not work properly."
    }

    # Install sccache
    Install-SCCache

    # Create configuration
    Set-SCCacheConfiguration

    # Setup compiler wrapper environment
    Set-SCCacheCompilerWrapper

    # Verify installation
    Test-SCCacheInstallation

    Write-Success "sccache installation completed successfully"
    Write-Status "Note: To use sccache as compiler wrapper, set these environment variables:"
    Write-Status "  For MSVC: CC=sccache cl.exe, CXX=sccache cl.exe"
    Write-Status "  For Clang: CC=sccache clang, CXX=sccache clang++"

} catch {
    Write-Error-Output "sccache installation failed: $($_.Exception.Message)"
    exit 1
}