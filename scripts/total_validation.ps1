#!/usr/bin/env pwsh
# Complete Development Environment Validation Script for Windows
# This script validates the development environment setup in the current project directory

param(
    [switch]$Help,
    [switch]$CppOnly,
    [switch]$PythonOnly,
    [switch]$SystemOnly
)

$ErrorActionPreference = "Stop"

# Script directory
$ScriptDir = $PSScriptRoot
$WindowsDir = Join-Path $ScriptDir "windows"

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

function Write-Warning {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-ColorOutput "[$timestamp] [WARNING] $Message" "Yellow"
}

function Write-ErrorOutput {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-ColorOutput "[$timestamp] [ERROR] $Message" "Red"
}

# Function to detect project type from current directory
function Get-ProjectType {
    # Check for Python project indicators
    if (Test-Path "pyproject.toml") {
        Write-Status "Detected Python project in current directory"
        return "python"
    }
    elseif (Test-Path "requirements.txt") {
        Write-Status "Detected Python project in current directory"
        return "python"
    }
    elseif (Test-Path "setup.py") {
        Write-Status "Detected Python project in current directory"
        return "python"
    }
    # Check for C++ project indicators
    elseif (Test-Path "CMakeLists.txt") {
        Write-Status "Detected C++ project in current directory"
        return "cpp"
    }
    elseif (Test-Path "Makefile") {
        Write-Status "Detected C++ project in current directory"
        return "cpp"
    }
    else {
        Write-Warning "No specific project type detected in current directory"
        return ""
    }
}

# Function to show usage
function Show-Usage {
    @"
Complete development environment validation for Windows

USAGE:
    .\total_validation.ps1 [OPTIONS]

OPTIONS:
    -Help, -h            Show this help message
    -CppOnly             Validate only C++ development tools
    -PythonOnly          Validate only Python development tools
    -SystemOnly          Validate only system tools

EXAMPLES:
    .\total_validation.ps1                # Auto-detect and validate current project
    .\total_validation.ps1 -PythonOnly    # Validate Python tools only
    .\total_validation.ps1 -CppOnly       # Validate C++ tools only

NOTE:
    This script should be run from within a project directory.
    It will validate the tools and setup for that specific project.

"@
}

# Main execution
function Main {
    if ($Help) {
        Show-Usage
        exit 0
    }

    Write-Status "Starting development environment validation..."
    Write-Status "Current directory: $(Get-Location)"
    Write-Status "Script directory: $ScriptDir"

    # Validate directory structure
    if (-not (Test-Path $WindowsDir)) {
        Write-ErrorOutput "Windows validation directory not found: $WindowsDir"
        exit 1
    }

    # Auto-detect project type if not specified
    $autoDetect = -not ($CppOnly -or $PythonOnly -or $SystemOnly)

    if ($autoDetect) {
        $projectType = Get-ProjectType
        if ($projectType -eq "python") {
            $PythonOnly = $true
        }
        elseif ($projectType -eq "cpp") {
            $CppOnly = $true
        }
        else {
            Write-Warning "Running full validation (all tools)"
        }
    }

    # Determine validation mode
    if ($CppOnly) {
        Write-Status "Validation mode: C++ only"
        $validationArgs = @("-CppOnly")
    }
    elseif ($PythonOnly) {
        Write-Status "Validation mode: Python only"
        $validationArgs = @("-PythonOnly")
    }
    elseif ($SystemOnly) {
        Write-Status "Validation mode: System tools only"
        $validationArgs = @("-SystemOnly")
    }
    else {
        Write-Status "Validation mode: Full (all tools)"
        $validationArgs = @()
    }

    # Run validation script
    $finalValidationScript = Join-Path $WindowsDir "validation\final-validation.ps1"

    if (-not (Test-Path $finalValidationScript)) {
        Write-ErrorOutput "Validation script not found: $finalValidationScript"
        exit 1
    }

    try {
        Write-Status "Running validation..."
        & powershell.exe -File $finalValidationScript @validationArgs

        if ($LASTEXITCODE -eq 0) {
            Write-Success "✅ Validation completed successfully"
            Write-Host ""
            Write-Host "Your development environment is ready!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Next Steps:"
            Write-Host "  1. Start developing in this project directory"
            Write-Host "  2. Use git hooks for automated quality checks"
            Write-Host "  3. Run tests regularly to ensure code quality"
            Write-Host ""
            exit 0
        }
        else {
            Write-ErrorOutput "❌ Validation failed"
            Write-Host ""
            Write-Host "Some validation tests failed. Please check the output above." -ForegroundColor Red
            Write-Host ""
            Write-Host "Troubleshooting:"
            Write-Host "  1. Ensure all required tools are installed"
            Write-Host "  2. Check that project files are properly set up"
            Write-Host "  3. Verify that configurations are correct"
            Write-Host "  4. Re-run the create-project script if needed"
            Write-Host ""
            exit 1
        }
    }
    catch {
        Write-ErrorOutput "❌ Validation failed: $($_.Exception.Message)"
        exit 1
    }
}

# Run main function
Main
