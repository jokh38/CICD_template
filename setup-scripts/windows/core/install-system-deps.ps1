#!/usr/bin/env pwsh
# System Dependencies Installation for Windows

param(
    [switch]$Force,
    [string]$RunnerUser = "github-runner"
)

$ErrorActionPreference = "Stop"

# Get script directory
$ScriptDir = $PSScriptRoot
$UtilsDir = Join-Path (Split-Path $ScriptDir -Parent) "utils"

# Import utility module
$UtilsModule = Join-Path $UtilsDir "Check-Dependencies.psm1"
if (Test-Path $UtilsModule) {
    Import-Module $UtilsModule -Force
} else {
    Write-Host "ERROR: Utility module not found: $UtilsModule" -ForegroundColor Red
    exit 1
}

function Install-Chocolatey {
    Write-Success "Installing Chocolatey package manager..."

    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Success "✅ Chocolatey installed"
    } else {
        Write-Success "✅ Chocolatey already installed"
    }
}

function Install-VisualStudioBuildTools {
    Write-Success "Installing Visual Studio Build Tools..."

    $vsBuildTools = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VS7*" -ErrorAction SilentlyContinue
    if ($vsBuildTools) {
        Write-Success "✅ Visual Studio Build Tools already installed"
        return
    }

    choco install visualstudio2022buildtools --package-parameters "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended" -y
    Write-Success "✅ Visual Studio Build Tools installed"
}

function Install-Git {
    Write-Success "Installing Git..."

    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Success "✅ Git already installed"
    } else {
        choco install git -y
        Write-Success "✅ Git installed"
    }
}

function Install-Python {
    Write-Success "Installing Python..."

    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-Success "✅ Python already installed"
    } else {
        choco install python3 -y
        Write-Success "✅ Python installed"
    }
}

function Install-SystemDeps {
    Write-Success "Installing additional system dependencies..."

    $packages = @(
        "vcredist-all",
        "dotnetfx",
        "7zip",
        "curl"
    )

    foreach ($package in $packages) {
        Write-Warning "Installing $package..."
        choco install $package -y
    }

    Write-Success "✅ System dependencies installed"
}

function Update-Path {
    Write-Success "Updating PATH environment variable..."

    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    Write-Success "✅ PATH updated"
}

function Main {
    Write-Success "Starting Windows system dependencies installation..."

    try {
        # Check if running as Administrator
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Error-Output "Please run this script as Administrator"
            exit 1
        }

        # Check if system dependencies are already installed
        if ((Test-SystemDependencies) -and (-not $Force)) {
            Write-Success "System dependencies are already installed - skipping"
            exit 0
        }

        Install-Chocolatey
        Install-VisualStudioBuildTools
        Install-Git
        Install-Python
        Install-SystemDeps
        Update-Path

        Write-Success "================================"
        Write-Success "✅ System dependencies installation complete!"
        Write-Success "================================"

    } catch {
        Write-Error-Output "Error: $($_.Exception.Message)"
        exit 1
    }
}

Main