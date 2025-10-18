#!/usr/bin/env pwsh
# Install Build Tools for Windows

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

# Function to install package via Chocolatey
function Install-ChocoPackage {
    param(
        [string]$PackageName,
        [string]$DisplayName = $PackageName,
        [string]$Version = ""
    )

    Write-Status "Installing $DisplayName..."
    try {
        if ($Version) {
            choco install $PackageName --version=$Version -y --no-progress
        } else {
            choco install $PackageName -y --no-progress
        }
        Write-Success "$DisplayName installed successfully"
    } catch {
        Write-Error-Output "Failed to install $DisplayName`: $($_.Exception.Message)"
        throw
    }
}

# Function to install CMake
function Install-CMake {
    Write-Status "Installing CMake..."
    try {
        # Check if CMake is already installed
        $cmakeVersion = cmake --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Status "CMake already installed: $cmakeVersion"
            return
        }

        # Install via Chocolatey
        choco install cmake -y --no-progress

        # Verify installation
        $cmakeVersion = cmake --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "CMake installed successfully"
        } else {
            throw "CMake installation verification failed"
        }
    } catch {
        Write-Error-Output "Failed to install CMake: $($_.Exception.Message)"
        throw
    }
}

# Function to install Ninja build system
function Install-Ninja {
    Write-Status "Installing Ninja build system..."
    try {
        # Check if Ninja is already installed
        $ninjaVersion = ninja --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Ninja already installed: version $ninjaVersion"
            return
        }

        # Install via Chocolatey
        choco install ninja -y --no-progress

        # Verify installation
        $ninjaVersion = ninja --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Ninja installed successfully"
        } else {
            throw "Ninja installation verification failed"
        }
    } catch {
        Write-Error-Output "Failed to install Ninja: $($_.Exception.Message)"
        throw
    }
}

# Function to install MSBuild tools
function Install-MSBuildTools {
    Write-Status "Installing MSBuild tools..."
    try {
        # MSBuild is typically installed with Visual Studio Build Tools
        # Check if MSBuild is available
        $msbuildPath = "${env:ProgramFiles}\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
        if (Test-Path $msbuildPath) {
            Write-Success "MSBuild found at: $msbuildPath"
        } else {
            # Try alternative paths
            $altPaths = @(
                "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
                "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
            )

            foreach ($path in $altPaths) {
                if (Test-Path $path) {
                    Write-Success "MSBuild found at: $path"
                    return
                }
            }

            Write-Warning "MSBuild not found. It should be installed with Visual Studio Build Tools."
        }
    } catch {
        Write-Warning "Could not verify MSBuild installation: $($_.Exception.Message)"
    }
}

# Function to install Conan package manager
function Install-Conan {
    Write-Status "Installing Conan package manager..."
    try {
        # Check if Conan is already installed
        try {
            $conanVersion = conan --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Status "Conan already installed: $conanVersion"
                return
            }
        } catch {
            # Conan not found, proceed with installation
        }

        # Install Conan via pip
        pip install conan --upgrade

        # Verify installation
        $conanVersion = conan --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Conan installed successfully"
        } else {
            throw "Conan installation verification failed"
        }
    } catch {
        Write-Error-Output "Failed to install Conan: $($_.Exception.Message)"
        throw
    }
}

# Function to install vcpkg
function Install-Vcpkg {
    Write-Status "Installing vcpkg package manager..."
    try {
        $vcpkgDir = "${env:ProgramFiles}\vcpkg"

        if (Test-Path $vcpkgDir) {
            Write-Status "vcpkg already installed in: $vcpkgDir"
        } else {
            # Clone vcpkg repository
            Write-Status "Cloning vcpkg repository..."
            & git clone https://github.com/Microsoft/vcpkg.git $vcpkgDir

            if ($LASTEXITCODE -eq 0) {
                # Bootstrap vcpkg
                Write-Status "Bootstrapping vcpkg..."
                Set-Location $vcpkgDir
                & .\bootstrap-vcpkg.bat

                if ($LASTEXITCODE -eq 0) {
                    Write-Success "vcpkg installed successfully"
                } else {
                    throw "vcpkg bootstrap failed"
                }
            } else {
                throw "Failed to clone vcpkg repository"
            }
        }

        # Add vcpkg to PATH if not already there
        $vcpkgExePath = Join-Path $vcpkgDir "vcpkg.exe"
        if (Test-Path $vcpkgExePath) {
            $vcpkgDirPath = Split-Path $vcpkgExePath -Parent
            $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
            if ($currentPath -notlike "*$vcpkgDirPath*") {
                [System.Environment]::SetEnvironmentVariable("PATH", $currentPath + ";$vcpkgDirPath", "User")
                Write-Status "Added vcpkg to user PATH"
            }
        }

    } catch {
        Write-Error-Output "Failed to install vcpkg: $($_.Exception.Message)"
        throw
    } finally {
        Set-Location $PSScriptRoot
    }
}

# Function to install additional build utilities
function Install-BuildUtilities {
    Write-Status "Installing additional build utilities..."

    $utilities = @(
        @{ Name = "make"; Display = "GNU Make" },
        @{ Name = "python3"; Display = "Python 3" }, # Required for many build systems
        @{ Name = "nasm"; Display = "NASM Assembler" },
        @{ Name = "jq"; Display = "jq JSON Processor" }
    )

    foreach ($utility in $utilities) {
        try {
            Install-ChocoPackage -PackageName $utility.Name -DisplayName $utility.Display
        } catch {
            Write-Warning "Failed to install $($utility.Display): $($_.Exception.Message)"
        }
    }
}

# Function to setup build environment variables
function Set-BuildEnvironment {
    Write-Status "Setting up build environment variables..."

    # Add common build tool directories to PATH
    $pathsToAdd = @(
        "${env:ProgramFiles}\CMake\bin",
        "${env:ProgramFiles}\Ninja",
        "${env:ProgramFiles}\vcpkg"
    )

    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $modified = $false

    foreach ($path in $pathsToAdd) {
        if ((Test-Path $path) -and ($currentPath -notlike "*$path*")) {
            $currentPath = $currentPath + ";$path"
            $modified = $true
            Write-Status "Added to PATH: $path"
        }
    }

    if ($modified) {
        [System.Environment]::SetEnvironmentVariable("PATH", $currentPath, "User")
        Write-Success "Updated user PATH with build tool directories"
    }

    # Set environment variables for vcpkg
    $vcpkgDir = "${env:ProgramFiles}\vcpkg"
    if (Test-Path $vcpkgDir) {
        [System.Environment]::SetEnvironmentVariable("VCPKG_ROOT", $vcpkgDir, "User")
        [System.Environment]::SetEnvironmentVariable("VCPKG_DEFAULT_TRIPLET", "x64-windows", "User")
        Write-Status "Set VCPKG environment variables"
    }
}

# Function to verify build tools installation
function Test-BuildToolsInstallation {
    Write-Status "Verifying build tools installation..."

    $tools = @(
        @{ Name = "cmake"; Command = "cmake --version" },
        @{ Name = "ninja"; Command = "ninja --version" },
        @{ Name = "conan"; Command = "conan --version" }
    )

    foreach ($tool in $tools) {
        try {
            $result = Invoke-Expression $tool.Command 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$($tool.Name) is working"
            } else {
                Write-Warning "$($tool.Name) not working properly"
            }
        } catch {
            Write-Warning "$($tool.Name) not found or not working"
        }
    }

    # Check vcpkg
    $vcpkgExe = "${env:ProgramFiles}\vcpkg\vcpkg.exe"
    if (Test-Path $vcpkgExe) {
        Write-Success "vcpkg is available"
    } else {
        Write-Warning "vcpkg not found"
    }
}

# Main installation
try {
    Write-Status "Starting Windows build tools installation..."

    # Check administrator privileges
    if (-not (Test-Administrator)) {
        Write-Error-Output "This script requires Administrator privileges"
        exit 1
    }

    # Refresh environment variables
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

    # Install build tools
    Install-CMake
    Install-Ninja
    Install-MSBuildTools
    Install-Conan
    Install-Vcpkg
    Install-BuildUtilities

    # Setup environment variables
    Set-BuildEnvironment

    # Verify installations
    Test-BuildToolsInstallation

    Write-Success "Build tools installation completed successfully"

} catch {
    Write-Error-Output "Build tools installation failed: $($_.Exception.Message)"
    exit 1
}