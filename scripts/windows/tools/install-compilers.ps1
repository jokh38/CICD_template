#!/usr/bin/env pwsh
# Install Compiler Tools for Windows

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

# Function to install Visual Studio Build Tools
function Install-VisualStudioBuildTools {
    Write-Status "Installing Visual Studio Build Tools..."

    $vsInstallerUrl = "https://aka.ms/vs/17/release/vs_buildtools.exe"
    $vsInstallerPath = "$env:TEMP\vs_buildtools.exe"
    $vsConfigPath = "$env:TEMP\vs_buildtools_config.json"

    # Create configuration file for Visual Studio Build Tools
    $vsConfig = @"
{
    "version": "1.0",
    "components": [
        "Microsoft.VisualStudio.Workload.VCTools",
        "Microsoft.VisualStudio.Workload.MSBuildTools",
        "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "Microsoft.VisualStudio.Component.Windows10SDK.19041",
        "Microsoft.VisualStudio.Component.Windows11SDK.22000",
        "Microsoft.VisualStudio.Component.VC.CMake.Project",
        "Microsoft.VisualStudio.Component.Git",
        "Microsoft.VisualStudio.Component.VC.Llvm.Clang",
        "Microsoft.Net.Component.4.8.SDK",
        "Microsoft.Net.Component.4.8.TargetingPack"
    ]
}
"@

    try {
        # Download Visual Studio Build Tools installer
        Write-Status "Downloading Visual Studio Build Tools installer..."
        Invoke-WebRequest -Uri $vsInstallerUrl -OutFile $vsInstallerPath -UseBasicParsing

        # Save configuration file
        $vsConfig | Out-File -FilePath $vsConfigPath -Encoding UTF8

        # Install Visual Studio Build Tools
        Write-Status "Installing Visual Studio Build Tools (this may take a while)..."
        $process = Start-Process -FilePath $vsInstallerPath -ArgumentList "--quiet", "--wait", "--config", $vsConfigPath -Wait -PassThru

        if ($process.ExitCode -eq 0) {
            Write-Success "Visual Studio Build Tools installed successfully"
        } else {
            Write-Warning "Visual Studio Build Tools installation returned exit code: $($process.ExitCode)"
        }

        # Cleanup
        Remove-Item $vsInstallerPath -ErrorAction SilentlyContinue
        Remove-Item $vsConfigPath -ErrorAction SilentlyContinue

    } catch {
        Write-Error-Output "Failed to install Visual Studio Build Tools: $($_.Exception.Message)"
        throw
    }
}

# Function to install LLVM/Clang via Chocolatey
function Install-LlvmClang {
    Write-Status "Installing LLVM/Clang..."
    try {
        choco install llvm -y --no-progress
        Write-Success "LLVM/Clang installed successfully"
    } catch {
        Write-Error-Output "Failed to install LLVM/Clang: $($_.Exception.Message)"
        throw
    }
}

# Function to install MinGW-w64
function Install-MinGW {
    Write-Status "Installing MinGW-w64..."
    try {
        choco install mingw -y --no-progress
        Write-Success "MinGW-w64 installed successfully"
    } catch {
        Write-Warning "Failed to install MinGW-w64: $($_.Exception.Message)"
    }
}

# Function to setup compiler environment variables
function Set-CompilerEnvironment {
    Write-Status "Setting up compiler environment variables..."

    # Find Visual Studio installation
    try {
        $vsPath = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($vsPath) {
            $vcVarsPath = Join-Path $vsPath "VC\Auxiliary\Build\vcvars64.bat"
            if (Test-Path $vcVarsPath) {
                Write-Status "Found Visual Studio installation at: $vsPath"
            }
        } else {
            Write-Warning "Visual Studio installation not found via vswhere.exe"
        }
    } catch {
        Write-Warning "Could not locate Visual Studio installation: $($_.Exception.Message)"
    }

    # Add LLVM to PATH if installed
    $llvmPath = "${env:ProgramFiles}\LLVM\bin"
    if (Test-Path $llvmPath) {
        $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        if ($currentPath -notlike "*$llvmPath*") {
            [System.Environment]::SetEnvironmentVariable("PATH", $currentPath + ";$llvmPath", "User")
            Write-Status "Added LLVM to user PATH"
        }
    }

    # Add MinGW to PATH if installed
    $mingwPath = "${env:ProgramFiles}\mingw-w64\x86_64-8.1.0-posix-seh-rt_v6-rev0\mingw64\bin"
    if (Test-Path $mingwPath) {
        $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        if ($currentPath -notlike "*$mingwPath*") {
            [System.Environment]::SetEnvironmentVariable("PATH", $currentPath + ";$mingwPath", "User")
            Write-Status "Added MinGW to user PATH"
        }
    }
}

# Function to verify compiler installations
function Test-CompilerInstallations {
    Write-Status "Verifying compiler installations..."

    # Test MSVC
    try {
        $clVersion = cmd /c "cl 2>&1" | Select-Object -First 3
        if ($clVersion -match "Microsoft.*C/C\+\+.*Compiler") {
            Write-Success "MSVC compiler is available"
        }
    } catch {
        Write-Warning "MSVC compiler test failed (may need to run in Developer Command Prompt)"
    }

    # Test Clang
    try {
        $clangVersion = & clang --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Clang compiler is available"
        } else {
            Write-Warning "Clang compiler not found in PATH"
        }
    } catch {
        Write-Warning "Clang compiler test failed"
    }

    # Test GCC (MinGW)
    try {
        $gccVersion = & gcc --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "GCC (MinGW) compiler is available"
        } else {
            Write-Warning "GCC (MinGW) compiler not found in PATH"
        }
    } catch {
        Write-Warning "GCC (MinGW) compiler test failed"
    }
}

# Main installation
try {
    Write-Status "Starting Windows compiler tools installation..."

    # Check administrator privileges
    if (-not (Test-Administrator)) {
        Write-Error-Output "This script requires Administrator privileges"
        exit 1
    }

    # Refresh environment variables
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

    # Install Visual Studio Build Tools (MSVC)
    Install-VisualStudioBuildTools

    # Install LLVM/Clang
    Install-LlvmClang

    # Install MinGW-w64 (optional alternative)
    Install-MinGW

    # Setup environment variables
    Set-CompilerEnvironment

    # Verify installations
    Test-CompilerInstallations

    Write-Success "Compiler tools installation completed successfully"
    Write-Status "Note: Some compilers may require restarting PowerShell or using Developer Command Prompt"

} catch {
    Write-Error-Output "Compiler tools installation failed: $($_.Exception.Message)"
    exit 1
}