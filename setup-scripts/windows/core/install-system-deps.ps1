#!/usr/bin/env pwsh
# System Dependencies Installation for Windows

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

function Install-Chocolatey {
    Write-ColorOutput "Installing Chocolatey package manager..." "Green"

    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-ColorOutput "✅ Chocolatey installed" "Green"
    } else {
        Write-ColorOutput "✅ Chocolatey already installed" "Green"
    }
}

function Install-VisualStudioBuildTools {
    Write-ColorOutput "Installing Visual Studio Build Tools..." "Green"

    $vsBuildTools = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VS7*" -ErrorAction SilentlyContinue
    if ($vsBuildTools) {
        Write-ColorOutput "✅ Visual Studio Build Tools already installed" "Green"
        return
    }

    choco install visualstudio2022buildtools --package-parameters "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended" -y
    Write-ColorOutput "✅ Visual Studio Build Tools installed" "Green"
}

function Install-Git {
    Write-ColorOutput "Installing Git..." "Green"

    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-ColorOutput "✅ Git already installed" "Green"
    } else {
        choco install git -y
        Write-ColorOutput "✅ Git installed" "Green"
    }
}

function Install-Python {
    Write-ColorOutput "Installing Python..." "Green"

    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-ColorOutput "✅ Python already installed" "Green"
    } else {
        choco install python3 -y
        Write-ColorOutput "✅ Python installed" "Green"
    }
}

function Install-SystemDeps {
    Write-ColorOutput "Installing additional system dependencies..." "Green"

    $packages = @(
        "vcredist-all",
        "dotnetfx",
        "7zip",
        "curl"
    )

    foreach ($package in $packages) {
        Write-ColorOutput "Installing $package..." "Yellow"
        choco install $package -y
    }

    Write-ColorOutput "✅ System dependencies installed" "Green"
}

function Update-Path {
    Write-ColorOutput "Updating PATH environment variable..." "Green"

    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    Write-ColorOutput "✅ PATH updated" "Green"
}

function Main {
    Write-ColorOutput "Starting Windows system dependencies installation..." "Green"

    try {
        # Check if running as Administrator
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-ColorOutput "Please run this script as Administrator" "Red"
            exit 1
        }

        Install-Chocolatey
        Install-VisualStudioBuildTools
        Install-Git
        Install-Python
        Install-SystemDeps
        Update-Path

        Write-ColorOutput "================================" "Green"
        Write-ColorOutput "✅ System dependencies installation complete!" "Green"
        Write-ColorOutput "================================" "Green"

    } catch {
        Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
        exit 1
    }
}

Main