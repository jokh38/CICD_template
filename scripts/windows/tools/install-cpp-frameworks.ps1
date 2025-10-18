#!/usr/bin/env pwsh
# Install C++ Testing Frameworks for Windows

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

# Function to install via Chocolatey
function Install-ChocoPackage {
    param(
        [string]$PackageName,
        [string]$DisplayName = $PackageName
    )

    Write-Status "Installing $DisplayName..."
    try {
        choco install $PackageName -y --no-progress
        Write-Success "$DisplayName installed successfully"
    } catch {
        Write-Error-Output "Failed to install $DisplayName`: $($_.Exception.Message)"
        throw
    }
}

# Function to install Google Test
function Install-GoogleTest {
    Write-Status "Installing Google Test framework..."

    try {
        # Check if vcpkg is available
        $vcpkgExe = "${env:ProgramFiles}\vcpkg\vcpkg.exe"
        if (Test-Path $vcpkgExe) {
            Write-Status "Installing Google Test via vcpkg..."
            & $vcpkgExe install gtest:x64-windows
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Google Test installed via vcpkg"
            } else {
                Write-Warning "vcpkg installation failed, trying alternative method"
                Install-GoogleTestAlternative
            }
        } else {
            Install-GoogleTestAlternative
        }
    } catch {
        Write-Error-Output "Failed to install Google Test: $($_.Exception.Message)"
        throw
    }
}

# Alternative Google Test installation
function Install-GoogleTestAlternative {
    Write-Status "Installing Google Test via alternative method..."

    try {
        # Clone Google Test repository
        $gtestDir = "${env:ProgramFiles}\googletest"
        if (-not (Test-Path $gtestDir)) {
            Write-Status "Cloning Google Test repository..."
            & git clone https://github.com/google/googletest.git $gtestDir

            if ($LASTEXITCODE -eq 0) {
                # Build Google Test
                Set-Location $gtestDir
                $buildDir = Join-Path $gtestDir "build"
                New-Item -Path $buildDir -ItemType Directory -Force | Out-Null

                Write-Status "Building Google Test..."
                cmake -S . -B $buildDir -A x64
                cmake --build $buildDir --config Release

                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Google Test built successfully"
                } else {
                    throw "Failed to build Google Test"
                }
            } else {
                throw "Failed to clone Google Test repository"
            }
        } else {
            Write-Status "Google Test already exists in: $gtestDir"
        }

    } catch {
        Write-Warning "Alternative Google Test installation failed: $($_.Exception.Message)"
    } finally {
        Set-Location $PSScriptRoot
    }
}

# Function to install Catch2
function Install-Catch2 {
    Write-Status "Installing Catch2 testing framework..."

    try {
        # Catch2 is header-only, so we can install it via vcpkg
        $vcpkgExe = "${env:ProgramFiles}\vcpkg\vcpkg.exe"
        if (Test-Path $vcpkgExe) {
            Write-Status "Installing Catch2 via vcpkg..."
            & $vcpkgExe install catch2:x64-windows
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Catch2 installed via vcpkg"
            } else {
                Write-Warning "vcpkg installation failed for Catch2"
            }
        } else {
            Write-Warning "vcpkg not found, Catch2 installation skipped (it's header-only, can be downloaded manually)"
        }
    } catch {
        Write-Warning "Failed to install Catch2: $($_.Exception.Message)"
    }
}

# Function to install Boost.Test
function Install-BoostTest {
    Write-Status "Installing Boost.Test framework..."

    try {
        # Install Boost via Chocolatey (includes Boost.Test)
        Install-ChocoPackage -PackageName "boost" -DisplayName "Boost Libraries"

        # Also try via vcpkg for more comprehensive installation
        $vcpkgExe = "${env:ProgramFiles}\vcpkg\vcpkg.exe"
        if (Test-Path $vcpkgExe) {
            Write-Status "Installing Boost via vcpkg..."
            & $vcpkgExe install boost-test:x64-windows
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Boost.Test installed via vcpkg"
            } else {
                Write-Warning "vcpkg installation failed for Boost.Test"
            }
        }
    } catch {
        Write-Error-Output "Failed to install Boost.Test: $($_.Exception.Message)"
        throw
    }
}

# Function to install Doctest
function Install-Doctest {
    Write-Status "Installing Doctest framework..."

    try {
        # Doctest is header-only, install via vcpkg
        $vcpkgExe = "${env:ProgramFiles}\vcpkg\vcpkg.exe"
        if (Test-Path $vcpkgExe) {
            Write-Status "Installing Doctest via vcpkg..."
            & $vcpkgExe install doctest:x64-windows
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Doctest installed via vcpkg"
            } else {
                Write-Warning "vcpkg installation failed for Doctest"
            }
        } else {
            Write-Warning "vcpkg not found, Doctest installation skipped (it's header-only)"
        }
    } catch {
        Write-Warning "Failed to install Doctest: $($_.Exception.Message)"
    }
}

# Function to install additional testing tools
function Install-TestingTools {
    Write-Status "Installing additional testing tools..."

    try {
        # Install lcov for code coverage (if available on Windows)
        try {
            Install-ChocoPackage -PackageName "lcov" -DisplayName "lcov coverage tool"
        } catch {
            Write-Warning "lcov not available on Windows or installation failed"
        }

        # Install OpenCppCoverage for C++ code coverage on Windows
        Write-Status "Installing OpenCppCoverage..."
        try {
            choco install opencppcoverage -y --no-progress
            Write-Success "OpenCppCoverage installed successfully"
        } catch {
            Write-Warning "Failed to install OpenCppCoverage: $($_.Exception.Message)"
        }

        # Install gcovr (Python-based coverage report generator)
        Write-Status "Installing gcovr..."
        try {
            pip install gcovr
            Write-Success "gcovr installed successfully"
        } catch {
            Write-Warning "Failed to install gcovr: $($_.Exception.Message)"
        }

    } catch {
        Write-Warning "Failed to install some testing tools: $($_.Exception.Message)"
    }
}

# Function to setup testing environment
function Set-TestingEnvironment {
    Write-Status "Setting up testing environment..."

    try {
        # Create testing workspace directory
        $testingDir = Join-Path $env:USERPROFILE "dev\testing"
        if (-not (Test-Path $testingDir)) {
            New-Item -Path $testingDir -ItemType Directory -Force | Out-Null
        }

        # Create CMake template for testing
        $cmakeTemplate = @"
# CMake template for projects with testing
cmake_minimum_required(VERSION 3.16)
project(TestProject VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(GTest REQUIRED)

# Enable testing
enable_testing()

# Add test executable
add_executable(unit_tests
    test/test_main.cpp
    test/test_calculator.cpp
    src/calculator.cpp
)

# Link libraries
target_link_libraries(unit_tests
    GTest::gtest
    GTest::gtest_main
)

# Add tests
add_test(NAME UnitTests COMMAND unit_tests)

# Optional: Add coverage if available
find_program(GCOV_PATH gcov)
if(GCOV_PATH)
    target_compile_options(unit_tests PRIVATE --coverage)
    target_link_options(unit_tests PRIVATE --coverage)
endif()
"@

        $cmakeTemplatePath = Join-Path $testingDir "CMakeTestingTemplate.txt"
        $cmakeTemplate | Out-File -FilePath $cmakeTemplatePath -Encoding UTF8 -Force

        Write-Success "Testing environment setup completed"

    } catch {
        Write-Warning "Failed to setup testing environment: $($_.Exception.Message)"
    }
}

# Function to verify testing frameworks installation
function Test-TestingFrameworksInstallation {
    Write-Status "Verifying testing frameworks installation..."

    try {
        # Check vcpkg packages
        $vcpkgExe = "${env:ProgramFiles}\vcpkg\vcpkg.exe"
        if (Test-Path $vcpkgExe) {
            Write-Status "Checking vcpkg packages..."
            $packages = @("gtest", "catch2", "boost-test", "doctest")

            foreach ($package in $packages) {
                $result = & $vcpkgExe list $package 2>$null
                if ($result -match $package) {
                    Write-Success "$package is installed via vcpkg"
                } else {
                    Write-Warning "$package not found via vcpkg"
                }
            }
        }

        # Check OpenCppCoverage
        try {
            $openCppCoverage = opencppcoverage --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "OpenCppCoverage is working"
            }
        } catch {
            Write-Warning "OpenCppCoverage not working"
        }

        # Check gcovr
        try {
            $gcovrVersion = gcovr --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "gcovr is working"
            }
        } catch {
            Write-Warning "gcovr not working"
        }

    } catch {
        Write-Warning "Could not verify testing frameworks installation: $($_.Exception.Message)"
    }
}

# Main installation
try {
    Write-Status "Starting Windows C++ testing frameworks installation..."

    # Check administrator privileges
    if (-not (Test-Administrator)) {
        Write-Warning "Not running as Administrator. Some features may not work properly."
    }

    # Refresh environment variables
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

    # Install testing frameworks
    Install-GoogleTest
    Install-Catch2
    Install-BoostTest
    Install-Doctest

    # Install additional testing tools
    Install-TestingTools

    # Setup testing environment
    Set-TestingEnvironment

    # Verify installations
    Test-TestingFrameworksInstallation

    Write-Success "C++ testing frameworks installation completed successfully"
    Write-Status "Note: Some frameworks require integration with your build system (CMake, etc.)"

} catch {
    Write-Error-Output "C++ testing frameworks installation failed: $($_.Exception.Message)"
    exit 1
}