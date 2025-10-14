#!/usr/bin/env pwsh
# Complete Development Environment Setup Orchestration Script for Windows

param(
    [switch]$Help,
    [switch]$Basic,
    [switch]$CppOnly,
    [switch]$PythonOnly,
    [switch]$NoValidation,
    [switch]$ValidateOnly,
    [switch]$Cleanup,
    [switch]$DryRun,
    [string]$RunnerUser = "github-runner"
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
    Write-ColorOutput "[INFO] $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[SUCCESS] $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

function Write-Error-Output {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

# Function to show usage
function Show-Usage {
    @"
Complete development environment setup for GitHub Actions runners (Windows)

USAGE:
    .\total_run.ps1 [OPTIONS]

OPTIONS:
    -Help, -h                Show this help message
    -Basic                   Install only basic tools (system deps, compilers, build tools)
    -CppOnly                 Install only C++ development tools
    -PythonOnly              Install only Python development tools
    -NoValidation            Skip validation tests
    -ValidateOnly            Run validation tests only
    -Cleanup                 Clean up test projects
    -DryRun                  Show what would be executed without running
    -RunnerUser <user>       Specify runner user (default: github-runner)

EXAMPLES:
    .\total_run.ps1                      # Full installation with validation
    .\total_run.ps1 -Basic               # Basic tools only
    .\total_run.ps1 -CppOnly             # C++ tools only
    .\total_run.ps1 -PythonOnly          # Python tools only
    .\total_run.ps1 -ValidateOnly        # Run validation tests
    .\total_run.ps1 -Cleanup             # Clean up test projects
    .\total_run.ps1 -DryRun              # Show what would be executed

"@
}

# Function to check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to run a script with error handling
function Invoke-SetupScript {
    param(
        [string]$ScriptPath,
        [string]$Description,
        [string[]]$Arguments = @()
    )

    if (-not (Test-Path $ScriptPath)) {
        Write-Error-Output "Script not found: $ScriptPath"
        return $false
    }

    Write-Status "Running: $Description"
    Write-Status "Executing: $ScriptPath"

    if ($DryRun) {
        Write-Status "[DRY RUN] Would execute: $ScriptPath $($Arguments -join ' ')"
        return $true
    }

    try {
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-File", $ScriptPath, "-RunnerUser", $RunnerUser, $Arguments -Wait -PassThru -WindowStyle Hidden
        if ($process.ExitCode -eq 0) {
            Write-Success "Completed: $Description"
            return $true
        } else {
            Write-Error-Output "Failed: $Description (Exit code: $($process.ExitCode))"
            return $false
        }
    } catch {
        Write-Error-Output "Failed to execute script: $($_.Exception.Message)"
        return $false
    }
}

# Function to install basic tools
function Install-BasicTools {
    Write-Status "Installing basic development tools..."

    $scripts = @(
        @{ Path = "$WindowsDir\core\install-system-deps.ps1"; Desc = "System Dependencies" },
        @{ Path = "$WindowsDir\tools\install-compilers.ps1"; Desc = "Compiler Tools" },
        @{ Path = "$WindowsDir\tools\install-build-tools.ps1"; Desc = "Build Tools" }
    )

    foreach ($script in $scripts) {
        if (-not (Invoke-SetupScript -ScriptPath $script.Path -Description $script.Desc)) {
            return $false
        }
    }
    return $true
}

# Function to install C++ tools
function Install-CppTools {
    Write-Status "Installing C++ development tools..."

    $scripts = @(
        @{ Path = "$WindowsDir\tools\install-sccache.ps1"; Desc = "sccache" },
        @{ Path = "$WindowsDir\tools\install-cpp-frameworks.ps1"; Desc = "C++ Testing Frameworks" },
        @{ Path = "$WindowsDir\config\setup-code-formatting.ps1"; Desc = "C++ Code Formatting" }
    )

    foreach ($script in $scripts) {
        if (-not (Invoke-SetupScript -ScriptPath $script.Path -Description $script.Desc)) {
            return $false
        }
    }
    return $true
}

# Function to install Python tools
function Install-PythonTools {
    Write-Status "Installing Python development tools..."

    $scriptPath = "$WindowsDir\tools\install-python-tools.ps1"
    return (Invoke-SetupScript -ScriptPath $scriptPath -Description "Python Development Tools")
}

# Function to setup configurations
function Set-Configurations {
    Write-Status "Setting up configurations..."

    $scripts = @(
        @{ Path = "$WindowsDir\config\setup-git-config.ps1"; Desc = "Git Configuration" },
        @{ Path = "$WindowsDir\config\setup-code-formatting.ps1"; Desc = "Code Formatting Configurations" }
    )

    foreach ($script in $scripts) {
        if (-not (Invoke-SetupScript -ScriptPath $script.Path -Description $script.Desc)) {
            return $false
        }
    }

    Write-Success "Configurations completed"
    return $true
}

# Function to create test projects
function New-TestProjects {
    if ($Validate) {
        Write-Status "Creating test projects..."

        # Test project creation for Windows would be implemented here
        # For now, we'll skip this as it's a complex process on Windows
        Write-Warning "Test project creation not implemented for Windows yet"
    }
    return $true
}

# Function to run validation
function Invoke-Validation {
    if ($Validate) {
        Write-Status "Running validation tests..."

        # Validation for Windows would be implemented here
        # For now, we'll do basic checks
        $tools = @("cmake", "ninja", "gcc", "clang", "python", "ruff")

        foreach ($tool in $tools) {
            try {
                $result = & $tool --version 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "$tool is available"
                } else {
                    Write-Warning "$tool not found or not working"
                }
            } catch {
                Write-Warning "$tool not found"
            }
        }
    }
    return $true
}

# Function to cleanup
function Invoke-Cleanup {
    Write-Status "Cleaning up..."

    $tempPaths = @(
        "$env:TEMP\cpp-test-project",
        "$env:TEMP\python-test-project"
    )

    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Recurse -Force
                Write-Success "Cleaned up: $path"
            } catch {
                Write-Warning "Failed to clean up $path`: $($_.Exception.Message)"
            }
        }
    }
}

# Function to print summary
function Show-Summary {
    Write-Host ""
    Write-ColorOutput "================================" "Green"
    Write-ColorOutput "✅ Setup Complete!" "Green"
    Write-ColorOutput "================================" "Green"
    Write-Host ""

    Write-Host "Installation Summary:"
    if ($InstallBasic -or $InstallAll) {
        Write-Host "  ✓ System dependencies"
        Write-Host "  ✓ Compiler tools (MSVC, Clang, MinGW)"
        Write-Host "  ✓ Build tools (CMake, Ninja)"
    }

    if ($InstallCpp -or $InstallAll) {
        Write-Host "  ✓ C++ tools (sccache, testing frameworks)"
        Write-Host "  ✓ C++ formatting configurations"
    }

    if ($InstallPython -or $InstallAll) {
        Write-Host "  ✓ Python tools (ruff, pytest, mypy)"
        Write-Host "  ✓ Python formatting configurations"
    }

    Write-Host ""
    Write-Host "Next Steps:"
    Write-Host "  1. Restart PowerShell to apply environment changes"
    Write-Host "  2. Test the installation with your projects"
    Write-Host "  3. Use the provided aliases for common tasks"
    Write-Host "  4. Git is configured and ready for use"
    Write-Host ""
    Write-Host "Configuration files created in:"
    Write-Host "  - ~/.gitconfig (Git configuration)"
    Write-Host "  - ~/.gitignore_global (Global gitignore)"
    Write-Host "  - ~/.config/git/commit.template (Commit template)"
    Write-Host "  - ~\.clang-format, ~\.clang-tidy (C++)"
    Write-Host "  - ~\.config\ruff\ruff.toml (Python)"
    Write-Host "  - ~\.config\cmake\CMakePresets.json"
    Write-Host "  - ~\.config\sccache\config"
    Write-Host ""
    Write-Host "Git user configured: Kwanghyun Jo <jokh38@gmail.com>"
    Write-Host ""
}

# Main execution function
function Main {
    # Parse installation options
    $Script:InstallAll = $true
    $Script:InstallBasic = $false
    $Script:InstallCpp = $false
    $Script:InstallPython = $false
    $Script:Validate = $true

    if ($Basic) {
        $Script:InstallAll = $false
        $Script:InstallBasic = $true
        $Script:InstallCpp = $false
        $Script:InstallPython = $false
    }

    if ($CppOnly) {
        $Script:InstallAll = $false
        $Script:InstallBasic = $false
        $Script:InstallCpp = $true
        $Script:InstallPython = $false
    }

    if ($PythonOnly) {
        $Script:InstallAll = $false
        $Script:InstallBasic = $false
        $Script:InstallCpp = $false
        $Script:InstallPython = $true
    }

    if ($NoValidation) {
        $Script:Validate = $false
    }

    if ($ValidateOnly) {
        $Script:InstallAll = $false
        $Script:InstallBasic = $false
        $Script:InstallCpp = $false
        $Script:InstallPython = $false
        $Script:Validate = $true
    }

    if ($Help) {
        Show-Usage
        exit 0
    }

    Write-Status "Starting Windows development environment setup..."
    Write-Status "Script directory: $ScriptDir"
    Write-Status "Windows directory: $WindowsDir"

    if ($DryRun) {
        Write-Status "Running in DRY RUN mode - no actual changes will be made"
    }

    # Check prerequisites
    if (-not $DryRun -and -not $ValidateOnly) {
        if (-not (Test-Administrator)) {
            Write-Error-Output "Please run this script as Administrator"
            exit 1
        }
    }

    # Validate directory structure
    if (-not (Test-Path $WindowsDir)) {
        Write-Error-Output "Windows directory not found: $WindowsDir"
        exit 1
    }

    # Execute installation steps
    try {
        if ($ValidateOnly) {
            Invoke-Validation
        } elseif ($Cleanup) {
            Invoke-Cleanup
        } else {
            # Installation phase
            if ($InstallBasic -or $InstallAll) {
                if (-not (Install-BasicTools)) {
                    throw "Basic tools installation failed"
                }
            }

            if ($InstallCpp -or $InstallAll) {
                if (-not (Install-CppTools)) {
                    throw "C++ tools installation failed"
                }
            }

            if ($InstallPython -or $InstallAll) {
                if (-not (Install-PythonTools)) {
                    throw "Python tools installation failed"
                }
            }

            if ($InstallAll -or $InstallCpp -or $InstallPython) {
                if (-not (Set-Configurations)) {
                    throw "Configuration setup failed"
                }
            }

            # Test projects and validation
            New-TestProjects
            Invoke-Validation

            if (-not $DryRun) {
                Show-Summary
            } else {
                Write-Status "DRY RUN completed successfully"
                Write-Status "Run without -DryRun to execute the installation"
            }
        }
    } catch {
        Write-Error-Output "Setup failed: $($_.Exception.Message)"
        exit 1
    }
}

# Execute main function
Main