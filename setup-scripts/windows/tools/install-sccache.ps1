#!/usr/bin/env pwsh
# sccache Installation and Configuration for Windows

param(
    [switch]$Force,
    [string]$RunnerUser = "github-runner",
    [string]$SccacheVersion = "0.11.0"
)

$ErrorActionPreference = "Stop"

# Get script directory
$ScriptDir = $PSScriptRoot
$UtilsDir = Join-Path (Split-Path (Split-Path $ScriptDir -Parent) -Parent) "utils"

# Import utility module
$UtilsModule = Join-Path $UtilsDir "Check-Dependencies.psm1"
if (Test-Path $UtilsModule) {
    Import-Module $UtilsModule -Force
} else {
    Write-Host "ERROR: Utility module not found: $UtilsModule" -ForegroundColor Red
    exit 1
}

function Get-Architecture {
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($arch -eq "AMD64") {
        return "x86_64-pc-windows-msvc"
    } else {
        Write-ColorOutput "Unsupported architecture: $arch" "Red"
        exit 1
    }
}

function Install-Sccache {
    Write-ColorOutput "Installing sccache for compilation caching..." "Green"

    if (Get-Command sccache -ErrorAction SilentlyContinue -and -not $Force) {
        Write-ColorOutput "✅ sccache already installed" "Green"
        return
    }

    $arch = Get-Architecture
    $downloadUrl = "https://github.com/mozilla/sccache/releases/download/v$SccacheVersion/sccache-v$SccacheVersion-$arch.tar.gz"
    $tempPath = "$env:TEMP\sccache"
    $zipPath = "$tempPath\sccache.tar.gz"

    # Create temp directory
    New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

    try {
        # Download sccache
        Write-ColorOutput "Downloading sccache from $downloadUrl..." "Yellow"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

        # Extract
        Write-ColorOutput "Extracting sccache..." "Yellow"
        Expand-Archive -Path $zipPath -DestinationPath $tempPath -Force

        # Find the sccache executable
        $sccacheExe = Get-ChildItem -Path $tempPath -Recurse -Name "sccache.exe" | Select-Object -First 1
        $sourcePath = Join-Path $tempPath $sccacheExe
        $destPath = "${env:ProgramFiles}\sccache\sccache.exe"

        # Create destination directory
        New-Item -ItemType Directory -Path "${env:ProgramFiles}\sccache" -Force | Out-Null

        # Copy executable
        Copy-Item -Path $sourcePath -Destination $destPath -Force

        # Add to PATH
        $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*sccache*") {
            [System.Environment]::SetEnvironmentVariable("PATH", $currentPath + ";${env:ProgramFiles}\sccache", "Machine")
        }

        Write-ColorOutput "✅ sccache installed to $destPath" "Green"

    } catch {
        Write-ColorOutput "Error installing sccache: $($_.Exception.Message)" "Red"
        throw
    } finally {
        # Cleanup
        Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Configure-Sccache {
    Write-ColorOutput "Configuring sccache for user $RunnerUser..." "Green"

    try {
        # Get user profile
        $userProfile = [System.Environment]::GetEnvironmentVariable("USERPROFILE", "User")
        $configDir = Join-Path $userProfile ".config\sccache"
        $cacheDir = Join-Path $userProfile ".cache\sccache"

        # Create directories
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null

        # Create sccache config
        $configContent = @"
[cache]
dir = "$cacheDir"
size = "10G"

[server]
start_server = true
idle_timeout = 7200
max_frame_files = 10000
"@

        $configPath = Join-Path $configDir "config"
        Set-Content -Path $configPath -Value $configContent -Encoding UTF8
        Write-ColorOutput "✅ sccache configuration created at $configPath" "Green"

        # Set environment variables
        [System.Environment]::SetEnvironmentVariable("SCCACHE_DIR", $cacheDir, "User")
        [System.Environment]::SetEnvironmentVariable("SCCACHE_CACHE_SIZE", "10G", "User")
        [System.Environment]::SetEnvironmentVariable("SCCACHE_MAX_FRAME_FILES", "10000", "User")
        [System.Environment]::SetEnvironmentVariable("SCCACHE_IDLE_TIMEOUT", "7200", "User")
        [System.Environment]::SetEnvironmentVariable("SCCACHE_START_SERVER", "1", "User")
        [System.Environment]::SetEnvironmentVariable("SCCACHE_NO_DAEMON", "0", "User")

        # CMake integration
        [System.Environment]::SetEnvironmentVariable("CMAKE_C_COMPILER_LAUNCHER", "sccache", "User")
        [System.Environment]::SetEnvironmentVariable("CMAKE_CXX_COMPILER_LAUNCHER", "sccache", "User")

        Write-ColorOutput "✅ sccache environment variables configured" "Green"

    } catch {
        Write-ColorOutput "Error configuring sccache: $($_.Exception.Message)" "Red"
        throw
    }
}

function Test-Sccache {
    Write-ColorOutput "Testing sccache installation..." "Green"

    try {
        # Update PATH for current session
        $env:PATH += ";${env:ProgramFiles}\sccache"

        $version = & sccache --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ sccache is working: $version" "Green"
        } else {
            Write-ColorOutput "⚠️ sccache not working properly" "Yellow"
        }
    } catch {
        Write-ColorOutput "⚠️ sccache test failed: $($_.Exception.Message)" "Yellow"
    }
}

function Main {
    Write-Success "Starting Windows sccache installation..."

    try {
        # Check if running as Administrator
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Error-Output "Please run this script as Administrator"
            exit 1
        }

        # Check if sccache is already installed
        if ((Test-Sccache) -and (-not $Force)) {
            Write-Success "sccache is already installed - skipping installation"
            # Still configure if not configured
            $userProfile = [System.Environment]::GetEnvironmentVariable("USERPROFILE", "User")
            $configPath = Join-Path $userProfile ".config\sccache\config"
            if (-not (Test-Path $configPath)) {
                Configure-Sccache
                Test-Sccache
            } else {
                Write-Success "sccache is already configured"
            }
            exit 0
        }

        Install-Sccache
        Configure-Sccache
        Test-Sccache

        Write-Success "================================"
        Write-Success "✅ sccache installation complete!"
        Write-Success "================================"
        Write-Warning "Note: Log out and back in to apply PATH changes"

    } catch {
        Write-Error-Output "Error: $($_.Exception.Message)"
        exit 1
    }
}

Main