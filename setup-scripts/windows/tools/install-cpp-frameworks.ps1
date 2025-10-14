#!/usr/bin/env pwsh
# C++ Testing Frameworks Installation for Windows

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

function Install-GTest {
    Write-ColorOutput "Installing GoogleTest v1.17.0..." "Green"

    $gtestPath = "${env:ProgramFiles}\googletest"
    if (Test-Path $gtestPath -and -not $Force) {
        Write-ColorOutput "✅ GoogleTest already installed" "Green"
        return
    }

    $tempPath = "$env:TEMP\gtest"
    $downloadUrl = "https://github.com/google/googletest/archive/refs/tags/v1.17.0.tar.gz"

    try {
        New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

        # Download and extract
        Write-ColorOutput "Downloading GoogleTest..." "Yellow"
        Invoke-WebRequest -Uri $downloadUrl -OutFile "$tempPath\gtest.tar.gz"
        Expand-Archive -Path "$tempPath\gtest.tar.gz" -DestinationPath $tempPath -Force

        # Build and install
        $sourcePath = Join-Path $tempPath "googletest-1.17.0"
        $buildPath = Join-Path $sourcePath "build"

        New-Item -ItemType Directory -Path $buildPath -Force | Out-Null
        Set-Location $buildPath

        Write-ColorOutput "Building GoogleTest..." "Yellow"
        cmake -DCMAKE_INSTALL_PREFIX="$gtestPath" -DBUILD_TESTING=OFF -DINSTALL_GTEST=ON -G "Ninja" ..
        cmake --build . --config Release
        cmake --install . --config Release

        Write-ColorOutput "✅ GoogleTest installed to $gtestPath" "Green"

    } catch {
        Write-ColorOutput "Error installing GoogleTest: $($_.Exception.Message)" "Red"
        throw
    } finally {
        # Cleanup
        Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        Set-Location $PSScriptRoot
    }
}

function Install-Catch2 {
    Write-ColorOutput "Installing Catch2 v3.11.0..." "Green"

    $catch2Path = "${env:ProgramFiles}\Catch2"
    if (Test-Path $catch2Path -and -not $Force) {
        Write-ColorOutput "✅ Catch2 already installed" "Green"
        return
    }

    $tempPath = "$env:TEMP\catch2"
    $downloadUrl = "https://github.com/catchorg/Catch2/archive/refs/tags/v3.11.0.tar.gz"

    try {
        New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

        # Download and extract
        Write-ColorOutput "Downloading Catch2..." "Yellow"
        Invoke-WebRequest -Uri $downloadUrl -OutFile "$tempPath\catch2.tar.gz"
        Expand-Archive -Path "$tempPath\catch2.tar.gz" -DestinationPath $tempPath -Force

        # Build and install
        $sourcePath = Join-Path $tempPath "Catch2-3.11.0"
        $buildPath = Join-Path $sourcePath "build"

        New-Item -ItemType Directory -Path $buildPath -Force | Out-Null
        Set-Location $buildPath

        Write-ColorOutput "Building Catch2..." "Yellow"
        cmake -DCMAKE_INSTALL_PREFIX="$catch2Path" -DBUILD_TESTING=OFF -G "Ninja" ..
        cmake --build . --config Release
        cmake --install . --config Release

        Write-ColorOutput "✅ Catch2 installed to $catch2Path" "Green"

    } catch {
        Write-ColorOutput "Error installing Catch2: $($_.Exception.Message)" "Red"
        throw
    } finally {
        # Cleanup
        Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        Set-Location $PSScriptRoot
    }
}

function Install-GoogleBenchmark {
    Write-ColorOutput "Installing Google Benchmark..." "Green"

    $benchmarkPath = "${env:ProgramFiles}\benchmark"
    if (Test-Path $benchmarkPath -and -not $Force) {
        Write-ColorOutput "✅ Google Benchmark already installed" "Green"
        return
    }

    $tempPath = "$env:TEMP\benchmark"

    try {
        New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

        # Clone repository
        Write-ColorOutput "Cloning Google Benchmark..." "Yellow"
        git clone "https://github.com/google/benchmark.git" $tempPath

        # Build and install
        $buildPath = Join-Path $tempPath "build"

        New-Item -ItemType Directory -Path $buildPath -Force | Out-Null
        Set-Location $buildPath

        Write-ColorOutput "Building Google Benchmark..." "Yellow"
        cmake -DCMAKE_INSTALL_PREFIX="$benchmarkPath" -DBENCHMARK_ENABLE_TESTING=OFF -G "Ninja" ..
        cmake --build . --config Release
        cmake --install . --config Release

        Write-ColorOutput "✅ Google Benchmark installed to $benchmarkPath" "Green"

    } catch {
        Write-ColorOutput "Error installing Google Benchmark: $($_.Exception.Message)" "Red"
        throw
    } finally {
        # Cleanup
        Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        Set-Location $PSScriptRoot
    }
}

function Update-CMakePrefixPath {
    Write-ColorOutput "Updating CMAKE_PREFIX_PATH..." "Green"

    $paths = @(
        "${env:ProgramFiles}\googletest",
        "${env:ProgramFiles}\Catch2",
        "${env:ProgramFiles}\benchmark"
    )

    $currentPath = [System.Environment]::GetEnvironmentVariable("CMAKE_PREFIX_PATH", "Machine") ?? ""
    $newPaths = $paths | Where-Object { Test-Path $_ } | ForEach-Object { $_ }

    if ($newPaths.Count -gt 0) {
        $updatedPath = $currentPath
        if ($updatedPath) {
            $updatedPath += ";" + ($newPaths -join ";")
        } else {
            $updatedPath = $newPaths -join ";"
        }

        [System.Environment]::SetEnvironmentVariable("CMAKE_PREFIX_PATH", $updatedPath, "Machine")
        Write-ColorOutput "✅ CMAKE_PREFIX_PATH updated" "Green"
    }
}

function Main {
    Write-ColorOutput "Starting Windows C++ testing frameworks installation..." "Green"

    try {
        # Check if running as Administrator
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-ColorOutput "Please run this script as Administrator" "Red"
            exit 1
        }

        Install-GTest
        Install-Catch2
        Install-GoogleBenchmark
        Update-CMakePrefixPath

        Write-ColorOutput "================================" "Green"
        Write-ColorOutput "✅ C++ testing frameworks installation complete!" "Green"
        Write-ColorOutput "================================" "Green"
        Write-ColorOutput "Note: Frameworks installed to Program Files" "Yellow"

    } catch {
        Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
        exit 1
    }
}

Main