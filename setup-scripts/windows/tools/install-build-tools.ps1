#!/usr/bin/env pwsh
# Build Tools Installation for Windows

param(
    [switch]$Force,
    [string]$RunnerUser = "github-runner"
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Install-CMake {
    Write-ColorOutput "Installing CMake..." "Green"

    if (Get-Command cmake -ErrorAction SilentlyContinue) {
        Write-ColorOutput "✅ CMake already installed" "Green"
    } else {
        choco install cmake --installargs 'ADD_CMAKE_TO_PATH=System' -y
        Write-ColorOutput "✅ CMake installed" "Green"
    }
}

function Install-Ninja {
    Write-ColorOutput "Installing Ninja..." "Green"

    if (Get-Command ninja -ErrorAction SilentlyContinue) {
        Write-ColorOutput "✅ Ninja already installed" "Green"
    } else {
        choco install ninja -y
        Write-ColorOutput "✅ Ninja installed" "Green"
    }
}

function Install-Meson {
    Write-ColorOutput "Installing Meson..." "Green"

    if (Get-Command meson -ErrorAction SilentlyContinue) {
        Write-ColorOutput "✅ Meson already installed" "Green"
    } else {
        pip install meson
        Write-ColorOutput "✅ Meson installed" "Green"
    }
}

function Install-Package-Config {
    Write-ColorOutput "Installing pkg-config..." "Green"

    if (Get-Command pkg-config -ErrorAction SilentlyContinue) {
        Write-ColorOutput "✅ pkg-config already installed" "Green"
    } else {
        choco install pkgconfiglite -y
        Write-ColorOutput "✅ pkg-config installed" "Green"
    }
}

function Update-BuildToolsPath {
    Write-ColorOutput "Updating build tools PATH..." "Green"

    # Refresh environment variables
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    Write-ColorOutput "✅ PATH updated for build tools" "Green"
}

function Test-BuildTools {
    Write-ColorOutput "Testing installed build tools..." "Green"

    $tools = @("cmake", "ninja", "meson")

    foreach ($tool in $tools) {
        try {
            $version = & $tool --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "✅ $tool is available" "Green"
            } else {
                Write-ColorOutput "⚠️ $tool not found or not working" "Yellow"
            }
        } catch {
            Write-ColorOutput "⚠️ $tool not found" "Yellow"
        }
    }
}

function Main {
    Write-ColorOutput "Starting Windows build tools installation..." "Green"

    try {
        # Check if running as Administrator
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-ColorOutput "Please run this script as Administrator" "Red"
            exit 1
        }

        Install-CMake
        Install-Ninja
        Install-Meson
        Install-Package-Config
        Update-BuildToolsPath
        Test-BuildTools

        Write-ColorOutput "================================" "Green"
        Write-ColorOutput "✅ Build tools installation complete!" "Green"
        Write-ColorOutput "================================" "Green"

    } catch {
        Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
        exit 1
    }
}

Main