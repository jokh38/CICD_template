# PowerShell Module for Dependency Checking
# Common utility functions for Windows setup scripts

# Color output functions
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error-Output {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to check if command exists
function Test-CommandExists {
    param([string]$Command)
    return (Get-Command $Command -ErrorAction SilentlyContinue) -ne $null
}

# Function to check if Chocolatey package is installed
function Test-ChocoPackageInstalled {
    param([string]$PackageName)
    try {
        $package = choco list --local-only --exact $PackageName | Where-Object { $_ -match "^$PackageName\s" }
        return $package -ne $null
    } catch {
        return $false
    }
}

# Function to check if Python package is installed
function Test-PythonPackageInstalled {
    param([string]$PackageName)
    try {
        $result = python -m pip show $PackageName 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

# Function to check if Visual Studio is installed
function Test-VisualStudioInstalled {
    try {
        $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        if (Test-Path $vsWhere) {
            $vsPath = & $vsWhere -latest -property installationPath 2>$null
            return $vsPath -ne $null -and $vsPath -ne ""
        }
        return $false
    } catch {
        return $false
    }
}

# Function to check if Windows SDK is installed
function Test-WindowsSDKInstalled {
    try {
        $sdkPath = "${env:ProgramFiles(x86)}\Windows Kits\10\bin"
        return (Test-Path $sdkPath)
    } catch {
        return $false
    }
}

# Function to check system dependencies
function Test-SystemDependencies {
    Write-Status "Checking system dependencies..."
    $missingDeps = @()
    $allInstalled = $true

    # Check for Chocolatey
    if (-not (Test-CommandExists "choco")) {
        $missingDeps += "Chocolatey"
        $allInstalled = $false
    }

    # Check for Visual Studio Build Tools
    if (-not (Test-VisualStudioInstalled)) {
        $missingDeps += "Visual Studio Build Tools"
        $allInstalled = $false
    }

    # Check for Windows SDK
    if (-not (Test-WindowsSDKInstalled)) {
        $missingDeps += "Windows SDK"
        $allInstalled = $false
    }

    # Check for Git
    if (-not (Test-CommandExists "git")) {
        $missingDeps += "Git"
        $allInstalled = $false
    }

    # Check for Python
    if (-not (Test-CommandExists "python")) {
        $missingDeps += "Python"
        $allInstalled = $false
    }

    # Check for curl
    if (-not (Test-CommandExists "curl")) {
        $missingDeps += "curl"
        $allInstalled = $false
    }

    if ($allInstalled) {
        Write-Success "All system dependencies are already installed"
        return $true
    } else {
        Write-Warning "Missing system dependencies:"
        $missingDeps | ForEach-Object { Write-Host "  - $_" }
        return $false
    }
}

# Function to check compiler tools
function Test-CompilerTools {
    Write-Status "Checking compiler tools..."
    $missingTools = @()
    $allInstalled = $true

    $compilers = @("gcc", "g++", "clang", "clang++", "cl")

    foreach ($compiler in $compilers) {
        if (-not (Test-CommandExists $compiler)) {
            $missingTools += $compiler
            $allInstalled = $false
        }
    }

    # Check for MSVC tools specifically
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vsWhere) {
        $vsPath = & $vsWhere -latest -property installationPath 2>$null
        $vcVarsPath = "$vsPath\VC\Auxiliary\Build\vcvars64.bat"
        if (-not (Test-Path $vcVarsPath)) {
            $missingTools += "MSVC Tools"
            $allInstalled = $false
        }
    } else {
        $missingTools += "Visual Studio Installer"
        $allInstalled = $false
    }

    if ($allInstalled) {
        Write-Success "All compiler tools are already installed"
        return $true
    } else {
        Write-Warning "Missing compiler tools:"
        $missingTools | ForEach-Object { Write-Host "  - $_" }
        return $false
    }
}

# Function to check build tools
function Test-BuildTools {
    Write-Status "Checking build tools..."
    $missingTools = @()
    $allInstalled = $true

    $tools = @("cmake", "ninja", "make")

    foreach ($tool in $tools) {
        if (-not (Test-CommandExists $tool)) {
            $missingTools += $tool
            $allInstalled = $false
        }
    }

    if ($allInstalled) {
        Write-Success "All build tools are already installed"
        return $true
    } else {
        Write-Warning "Missing build tools:"
        $missingTools | ForEach-Object { Write-Host "  - $_" }
        return $false
    }
}

# Function to check Python tools
function Test-PythonTools {
    Write-Status "Checking Python tools..."
    $missingTools = @()
    $allInstalled = $true

    # Check for Python
    if (-not (Test-CommandExists "python")) {
        $missingTools += "python"
        $allInstalled = $false
    }

    # Check for pip
    if (-not (Test-CommandExists "pip")) {
        $missingTools += "pip"
        $allInstalled = $false
    }

    # Check for Python packages if Python is available
    if (Test-CommandExists "python") {
        $pythonPackages = @("ruff", "pytest", "mypy", "black", "isort", "pre-commit")
        foreach ($package in $pythonPackages) {
            if (-not (Test-PythonPackageInstalled $package)) {
                $missingTools += "python-$package"
                $allInstalled = $false
            }
        }
    } else {
        $allInstalled = $false
    }

    if ($allInstalled) {
        Write-Success "All Python tools are already installed"
        return $true
    } else {
        Write-Warning "Missing Python tools:"
        $missingTools | ForEach-Object { Write-Host "  - $_" }
        return $false
    }
}

# Function to check C++ frameworks
function Test-CppFrameworks {
    Write-Status "Checking C++ frameworks..."
    $missingTools = @()
    $allInstalled = $true

    # Check for Google Test headers
    $gtestPaths = @(
        "${env:ProgramFiles}\googletest\include\gtest\gtest.h",
        "${env:ProgramFiles(x86)}\googletest\include\gtest\gtest.h",
        "C:\libs\gtest\include\gtest\gtest.h"
    )

    $gtestFound = $false
    foreach ($path in $gtestPaths) {
        if (Test-Path $path) {
            $gtestFound = $true
            break
        }
    }

    if (-not $gtestFound) {
        $missingTools += "Google Test"
        $allInstalled = $false
    }

    # Check for Catch2 headers
    $catch2Paths = @(
        "${env:ProgramFiles}\catch2\include\catch2\catch_test_macros.hpp",
        "${env:ProgramFiles(x86)}\catch2\include\catch2\catch_test_macros.hpp",
        "C:\libs\catch2\include\catch2\catch_test_macros.hpp"
    )

    $catch2Found = $false
    foreach ($path in $catch2Paths) {
        if (Test-Path $path) {
            $catch2Found = $true
            break
        }
    }

    if (-not $catch2Found) {
        $missingTools += "Catch2"
        $allInstalled = $false
    }

    # Check for Google Benchmark headers
    $benchmarkPaths = @(
        "${env:ProgramFiles}\benchmark\include\benchmark\benchmark.h",
        "${env:ProgramFiles(x86)}\benchmark\include\benchmark\benchmark.h",
        "C:\libs\benchmark\include\benchmark\benchmark.h"
    )

    $benchmarkFound = $false
    foreach ($path in $benchmarkPaths) {
        if (Test-Path $path) {
            $benchmarkFound = $true
            break
        }
    }

    if (-not $benchmarkFound) {
        $missingTools += "Google Benchmark"
        $allInstalled = $false
    }

    if ($allInstalled) {
        Write-Success "All C++ frameworks are already installed"
        return $true
    } else {
        Write-Warning "Missing C++ frameworks:"
        $missingTools | ForEach-Object { Write-Host "  - $_" }
        return $false
    }
}

# Function to check sccache
function Test-Sccache {
    Write-Status "Checking sccache..."

    if (Test-CommandExists "sccache") {
        Write-Success "sccache is already installed"
        return $true
    } else {
        Write-Warning "sccache is not installed"
        return $false
    }
}

# Function to check if Git is configured
function Test-GitConfig {
    Write-Status "Checking Git configuration..."

    try {
        $userProfile = [System.Environment]::GetEnvironmentVariable("USERPROFILE", "User")
        $gitConfigPath = Join-Path $userProfile ".gitconfig"

        if (Test-Path $gitConfigPath) {
            $userName = git config --global user.name 2>$null
            $userEmail = git config --global user.email 2>$null

            if ($userName -and $userEmail) {
                Write-Success "Git is already configured"
                return $true
            }
        }

        Write-Warning "Git is not configured"
        return $false
    } catch {
        Write-Warning "Git is not configured"
        return $false
    }
}

# Function to check code formatting configurations
function Test-CodeFormatting {
    Write-Status "Checking code formatting configurations..."

    $userProfile = [System.Environment]::GetEnvironmentVariable("USERPROFILE", "User")
    $missingConfigs = @()
    $allConfigured = $true

    $configs = @(
        (Join-Path $userProfile ".clang-format"),
        (Join-Path $userProfile ".clang-tidy"),
        (Join-Path $userProfile ".config\ruff\ruff.toml")
    )

    foreach ($config in $configs) {
        if (-not (Test-Path $config)) {
            $missingConfigs += $config
            $allConfigured = $false
        }
    }

    if ($allConfigured) {
        Write-Success "All code formatting configurations are already set up"
        return $true
    } else {
        Write-Warning "Missing formatting configurations:"
        $missingConfigs | ForEach-Object { Write-Host "  - $_" }
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    "Write-Status",
    "Write-Success",
    "Write-Warning",
    "Write-Error-Output",
    "Test-CommandExists",
    "Test-ChocoPackageInstalled",
    "Test-PythonPackageInstalled",
    "Test-VisualStudioInstalled",
    "Test-WindowsSDKInstalled",
    "Test-SystemDependencies",
    "Test-CompilerTools",
    "Test-BuildTools",
    "Test-PythonTools",
    "Test-CppFrameworks",
    "Test-Sccache",
    "Test-GitConfig",
    "Test-CodeFormatting"
)