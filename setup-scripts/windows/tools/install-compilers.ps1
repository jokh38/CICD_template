#!/usr/bin/env pwsh
# Compiler Tools Installation for Windows

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

function Install-LLVM {
    Write-ColorOutput "Installing LLVM/Clang..." "Green"

    if (Get-Command clang -ErrorAction SilentlyContinue) {
        Write-ColorOutput "✅ LLVM/Clang already installed" "Green"
    } else {
        choco install llvm --package-parameters "'/ADD=64'" -y
        Write-ColorOutput "✅ LLVM/Clang installed" "Green"
    }
}

function Install-MinGW {
    Write-ColorOutput "Installing MinGW-w64..." "Green"

    if (Get-Command gcc -ErrorAction SilentlyContinue) {
        Write-ColorOutput "✅ MinGW-w64 already installed" "Green"
    } else {
        choco install mingw -y
        Write-ColorOutput "✅ MinGW-w64 installed" "Green"
    }
}

function Install-MSVC-Tools {
    Write-ColorOutput "Configuring MSVC tools..." "Green"

    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vsWhere) {
        $vsPath = & $vsWhere -latest -property installationPath
        $vcVarsPath = "$vsPath\VC\Auxiliary\Build\vcvars64.bat"

        if (Test-Path $vcVarsPath) {
            Write-ColorOutput "✅ MSVC tools found at: $vsPath" "Green"

            # Add to PATH for current session
            $env:PATH += ";$vsPath\VC\Tools\MSVC\*\bin\Hostx64\x64"
            Write-ColorOutput "✅ MSVC tools added to PATH" "Green"
        } else {
            Write-ColorOutput "⚠️ MSVC tools not properly configured" "Yellow"
        }
    } else {
        Write-ColorOutput "⚠️ Visual Studio installation not found" "Yellow"
    }
}

function Update-CompilerPath {
    Write-ColorOutput "Updating compiler PATH..." "Green"

    $llvmPath = "${env:ProgramFiles}\LLVM\bin"
    $mingwPath = "C:\tools\mingw64\bin"

    if (Test-Path $llvmPath) {
        $env:PATH += ";$llvmPath"
        Write-ColorOutput "✅ LLVM added to PATH" "Green"
    }

    if (Test-Path $mingwPath) {
        $env:PATH += ";$mingwPath"
        Write-ColorOutput "✅ MinGW added to PATH" "Green"
    }
}

function Test-Compilers {
    Write-ColorOutput "Testing installed compilers..." "Green"

    $compilers = @("gcc", "g++", "clang", "clang++", "cl")

    foreach ($compiler in $compilers) {
        try {
            $version = & $compiler --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "✅ $compiler is available" "Green"
            } else {
                Write-ColorOutput "⚠️ $compiler not found or not working" "Yellow"
            }
        } catch {
            Write-ColorOutput "⚠️ $compiler not found" "Yellow"
        }
    }
}

function Main {
    Write-ColorOutput "Starting Windows compiler tools installation..." "Green"

    try {
        # Check if running as Administrator
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-ColorOutput "Please run this script as Administrator" "Red"
            exit 1
        }

        Install-LLVM
        Install-MinGW
        Install-MSVC-Tools
        Update-CompilerPath
        Test-Compilers

        Write-ColorOutput "================================" "Green"
        Write-ColorOutput "✅ Compiler tools installation complete!" "Green"
        Write-ColorOutput "================================" "Green"

    } catch {
        Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
        exit 1
    }
}

Main