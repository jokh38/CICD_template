#!/usr/bin/env pwsh
# Python Development Tools Installation for Windows

param(
    [switch]$Force,
    [string]$RunnerUser = "github-runner"
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

function Update-Pip {
    Write-ColorOutput "Updating pip..." "Green"

    try {
        python -m pip install --upgrade pip setuptools wheel
        Write-ColorOutput "✅ pip updated" "Green"
    } catch {
        Write-ColorOutput "Error updating pip: $($_.Exception.Message)" "Red"
        throw
    }
}

function Install-PythonLintingTools {
    Write-ColorOutput "Installing Python linting and formatting tools..." "Green"

    $tools = @(
        "ruff",
        "black",
        "isort",
        "flake8",
        "mypy"
    )

    foreach ($tool in $tools) {
        try {
            Write-ColorOutput "Installing $tool..." "Yellow"
            python -m pip install --user $tool
            Write-ColorOutput "✅ $tool installed" "Green"
        } catch {
            Write-ColorOutput "⚠️ Failed to install $tool: $($_.Exception.Message)" "Yellow"
        }
    }
}

function Install-PythonTestingTools {
    Write-ColorOutput "Installing Python testing tools..." "Green"

    $tools = @(
        "pytest",
        "pytest-cov",
        "pytest-mock",
        "coverage"
    )

    foreach ($tool in $tools) {
        try {
            Write-ColorOutput "Installing $tool..." "Yellow"
            python -m pip install --user $tool
            Write-ColorOutput "✅ $tool installed" "Green"
        } catch {
            Write-ColorOutput "⚠️ Failed to install $tool: $($_.Exception.Message)" "Yellow"
        }
    }
}

function Install-PythonSecurityTools {
    Write-ColorOutput "Installing Python security tools..." "Green"

    $tools = @(
        "bandit",
        "safety"
    )

    foreach ($tool in $tools) {
        try {
            Write-ColorOutput "Installing $tool..." "Yellow"
            python -m pip install --user $tool
            Write-ColorOutput "✅ $tool installed" "Green"
        } catch {
            Write-ColorOutput "⚠️ Failed to install $tool: $($_.Exception.Message)" "Yellow"
        }
    }
}

function Install-PythonPackageTools {
    Write-ColorOutput "Installing Python package management tools..." "Green"

    $tools = @(
        "pipx",
        "pre-commit",
        "build",
        "twine",
        "wheel"
    )

    foreach ($tool in $tools) {
        try {
            Write-ColorOutput "Installing $tool..." "Yellow"
            python -m pip install --user $tool
            Write-ColorOutput "✅ $tool installed" "Green"
        } catch {
            Write-ColorOutput "⚠️ Failed to install $tool: $($_.Exception.Message)" "Yellow"
        }
    }
}

function Update-PythonPath {
    Write-ColorOutput "Updating Python user script PATH..." "Green"

    try {
        $pythonUserBase = python -m site --user-base
        $userScriptsPath = Join-Path $pythonUserBase "Scripts"

        $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        if ($currentPath -notlike "*$userScriptsPath*") {
            [System.Environment]::SetEnvironmentVariable("PATH", $currentPath + ";$userScriptsPath", "User")
            Write-ColorOutput "✅ Added $userScriptsPath to user PATH" "Green"
        } else {
            Write-ColorOutput "✅ Python user scripts already in PATH" "Green"
        }

        # Update current session
        $env:PATH += ";$userScriptsPath"

    } catch {
        Write-ColorOutput "Error updating Python PATH: $($_.Exception.Message)" "Red"
    }
}

function Test-PythonTools {
    Write-ColorOutput "Testing Python tools installation..." "Green"

    $tools = @(
        @{Name="ruff"; Command="ruff"},
        @{Name="pytest"; Command="pytest"},
        @{Name="mypy"; Command="mypy"},
        @{Name="black"; Command="black"},
        @{Name="pre-commit"; Command="pre-commit"}
    )

    foreach ($tool in $tools) {
        try {
            $result = & $tool.Command --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "✅ $($tool.Name) is working" "Green"
            } else {
                Write-ColorOutput "⚠️ $($tool.Name) not working properly" "Yellow"
            }
        } catch {
            Write-ColorOutput "⚠️ $($tool.Name) not found" "Yellow"
        }
    }
}

function Main {
    Write-Success "Starting Windows Python development tools installation..."

    try {
        # Check if running as Administrator
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Error-Output "Please run this script as Administrator"
            exit 1
        }

        # Check if Python tools are already installed
        if ((Test-PythonTools) -and (-not $Force)) {
            Write-Success "Python tools are already installed - skipping"
            exit 0
        }

        Update-Pip
        Install-PythonLintingTools
        Install-PythonTestingTools
        Install-PythonSecurityTools
        Install-PythonPackageTools
        Update-PythonPath
        Test-PythonTools

        Write-Success "================================"
        Write-Success "✅ Python tools installation complete!"
        Write-Success "================================"
        Write-Warning "Note: Log out and back in to apply PATH changes"

    } catch {
        Write-Error-Output "Error: $($_.Exception.Message)"
        exit 1
    }
}

Main