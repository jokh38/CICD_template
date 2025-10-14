#!/usr/bin/env pwsh
# Python Development Tools Installation for Windows

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
    Write-ColorOutput "Starting Windows Python development tools installation..." "Green"

    try {
        # Check if running as Administrator
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-ColorOutput "Please run this script as Administrator" "Red"
            exit 1
        }

        Update-Pip
        Install-PythonLintingTools
        Install-PythonTestingTools
        Install-PythonSecurityTools
        Install-PythonPackageTools
        Update-PythonPath
        Test-PythonTools

        Write-ColorOutput "================================" "Green"
        Write-ColorOutput "✅ Python tools installation complete!" "Green"
        Write-ColorOutput "================================" "Green"
        Write-ColorOutput "Note: Log out and back in to apply PATH changes" "Yellow"

    } catch {
        Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
        exit 1
    }
}

Main