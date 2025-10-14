#!/usr/bin/env pwsh
# Compiler Tools Installation for Windows

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

function Install-LLVM {
    Write-Success "Installing LLVM/Clang..."

    if (Get-Command clang -ErrorAction SilentlyContinue) {
        Write-Success "✅ LLVM/Clang already installed"
    } else {
        choco install llvm --package-parameters "'/ADD=64'" -y
        Write-Success "✅ LLVM/Clang installed"
    }
}

function Install-MinGW {
    Write-Success "Installing MinGW-w64..."

    if (Get-Command gcc -ErrorAction SilentlyContinue) {
        Write-Success "✅ MinGW-w64 already installed"
    } else {
        choco install mingw -y
        Write-Success "✅ MinGW-w64 installed"
    }
}

function Install-MSVC-Tools {
    Write-Success "Configuring MSVC tools..."

    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vsWhere) {
        $vsPath = & $vsWhere -latest -property installationPath
        $vcVarsPath = "$vsPath\VC\Auxiliary\Build\vcvars64.bat"

        if (Test-Path $vcVarsPath) {
            Write-Success "✅ MSVC tools found at: $vsPath"

            # Add to PATH for current session
            $env:PATH += ";$vsPath\VC\Tools\MSVC\*\bin\Hostx64\x64"
            Write-Success "✅ MSVC tools added to PATH"
        } else {
            Write-Warning "⚠️ MSVC tools not properly configured"
        }
    } else {
        Write-Warning "⚠️ Visual Studio installation not found"
    }
}

function Update-CompilerPath {
    Write-Success "Updating compiler PATH..."

    $llvmPath = "${env:ProgramFiles}\LLVM\bin"
    $mingwPath = "C:\tools\mingw64\bin"

    if (Test-Path $llvmPath) {
        $env:PATH += ";$llvmPath"
        Write-Success "✅ LLVM added to PATH"
    }

    if (Test-Path $mingwPath) {
        $env:PATH += ";$mingwPath"
        Write-Success "✅ MinGW added to PATH"
    }
}

function Test-Compilers {
    Write-Success "Testing installed compilers..."

    $compilers = @("gcc", "g++", "clang", "clang++", "cl")

    foreach ($compiler in $compilers) {
        try {
            $version = & $compiler --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "✅ $compiler is available"
            } else {
                Write-Warning "⚠️ $compiler not found or not working"
            }
        } catch {
            Write-Warning "⚠️ $compiler not found"
        }
    }
}

function Main {
    Write-Success "Starting Windows compiler tools installation..."

    try {
        # Check if running as Administrator
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Error-Output "Please run this script as Administrator"
            exit 1
        }

        # Check if compiler tools are already installed
        if ((Test-CompilerTools) -and (-not $Force)) {
            Write-Success "Compiler tools are already installed - skipping"
            exit 0
        }

        Install-LLVM
        Install-MinGW
        Install-MSVC-Tools
        Update-CompilerPath
        Test-Compilers

        Write-Success "================================"
        Write-Success "✅ Compiler tools installation complete!"
        Write-Success "================================"

    } catch {
        Write-Error-Output "Error: $($_.Exception.Message)"
        exit 1
    }
}

Main