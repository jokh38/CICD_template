# GitHub Actions Self-Hosted Runner Installation (Windows)

param(
    [string]$GitHubUrl,
    [string]$Token,
    [string]$RunnerName = $env:COMPUTERNAME,
    [switch]$SetupPython,
    [switch]$SetupCpp,
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"

$RUNNER_VERSION = "2.319.1"
$INSTALL_DIR = "C:\actions-runner"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "Green")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Error-Output {
    param([string]$Message)
    Write-Host $Message -ForegroundColor "Red"
}

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Dependencies {
    Write-ColorOutput "Installing dependencies..." "Yellow"

    # Check if Chocolatey is installed
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-ColorOutput "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        refreshenv
    }

    # Install Git and other dependencies
    choco install -y git python3 visualstudio2022buildtools -y --params "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"

    Write-ColorOutput "✅ Dependencies installed"
}

function Download-Runner {
    Write-ColorOutput "Downloading runner..." "Yellow"

    if (!(Test-Path $INSTALL_DIR)) {
        New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
    }

    Set-Location $INSTALL_DIR

    $url = "https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-win-x64-$RUNNER_VERSION.zip"

    Invoke-WebRequest -Uri $url -OutFile "actions-runner.zip"
    Expand-Archive -Path "actions-runner.zip" -DestinationPath . -Force
    Remove-Item "actions-runner.zip"

    Write-ColorOutput "✅ Runner downloaded"
}

function Configure-Runner {
    Write-ColorOutput "Configuring runner..." "Yellow"

    if (!$GitHubUrl) {
        $GitHubUrl = Read-Host "GitHub URL (e.g., https://github.com/your-org)"
    }
    if (!$Token) {
        $Token = Read-Host "Registration token"
    }

    Set-Location $INSTALL_DIR

    .\config.cmd `
        --url $GitHubUrl `
        --token $Token `
        --name $RunnerName `
        --labels "self-hosted,Windows,X64" `
        --work "_work" `
        --unattended

    Write-ColorOutput "✅ Runner configured"
}

function Install-Service {
    Write-ColorOutput "Installing Windows service..." "Yellow"

    Set-Location $INSTALL_DIR
    .\svc.cmd install
    .\svc.cmd start

    Write-ColorOutput "✅ Service installed and started"
}

function Setup-PythonTools {
    Write-ColorOutput "Installing Python tools..." "Yellow"

    # Ensure Python is in PATH
    $pythonPath = Get-Command python3 -ErrorAction SilentlyContinue
    if (!$pythonPath) {
        $pythonPath = Get-Command python -ErrorAction SilentlyContinue
    }

    if ($pythonPath) {
        & $pythonPath -m pip install --upgrade pip setuptools wheel

        # Install Python tools
        & $pythonPath -m pip install ruff pytest pytest-cov mypy pre-commit black isort flake8 bandit pipx

        # Create ruff configuration
        $ruffConfig = @"
# Ruff configuration for Windows
target-version = "py310"
line-length = 88
indent-width = 4

[lint]
select = ["E", "W", "F", "I", "N", "UP", "B", "C4", "SIM", "S"]
ignore = ["E501", "S101"]

[format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "auto"
"@

        $ruffConfigPath = "$env:USERPROFILE\.config\ruff\ruff.toml"
        New-Item -ItemType Directory -Force -Path (Split-Path $ruffConfigPath) | Out-Null
        Set-Content -Path $ruffConfigPath -Value $ruffConfig

        Write-ColorOutput "✅ Python tools installed"
    } else {
        Write-Error-Output "Python not found. Please install Python first."
    }
}

function Setup-CppTools {
    Write-ColorOutput "Installing C++ tools..." "Yellow"

    # Install additional tools via Chocolatey
    choco install -y cmake ninja llvm visualstudio2022-workload-vctools

    # Install sccache
    $SCCACHE_VERSION = "0.7.7"
    $url = "https://github.com/mozilla/sccache/releases/download/v$SCCACHE_VERSION/sccache-v$SCCACHE_VERSION-x86_64-pc-windows-msvc.zip"

    $sccacheDir = "C:\sccache"
    if (!(Test-Path $sccacheDir)) {
        New-Item -ItemType Directory -Path $sccacheDir -Force | Out-Null
    }

    $sccacheZip = "$sccacheDir\sccache.zip"
    Invoke-WebRequest -Uri $url -OutFile $sccacheZip
    Expand-Archive -Path $sccacheZip -DestinationPath $sccacheDir -Force
    Remove-Item $sccacheZip

    # Add to PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($currentPath -notlike "*$sccacheDir*") {
        [Environment]::SetEnvironmentVariable(
            "Path",
            $currentPath + ";$sccacheDir",
            "Machine"
        )
    }

    # Create clang-format configuration
    $clangFormatConfig = @"
# clang-format configuration
BasedOnStyle: Google
Language: Cpp
Standard: c++17

ColumnLimit: 100
IndentWidth: 4
UseTab: Never
PointerAlignment: Left
ReferenceAlignment: Left

AllowShortFunctionsOnASingleLine: Inline
AllowShortIfStatementsOnASingleLine: Never
AllowShortLoopsOnASingleLine: false

BreakBeforeBraces: Attach
IndentCaseLabels: true
SpaceAfterCStyleCast: false
SpacesInParentheses: false
"@

    $clangFormatPath = "$env:USERPROFILE\.clang-format"
    Set-Content -Path $clangFormatPath -Value $clangFormatConfig

    # Create environment variables for sccache
    [Environment]::SetEnvironmentVariable("CMAKE_C_COMPILER_LAUNCHER", "sccache", "Machine")
    [Environment]::SetEnvironmentVariable("CMAKE_CXX_COMPILER_LAUNCHER", "sccache", "Machine")
    [Environment]::SetEnvironmentVariable("SCCACHE_DIR", "$env:USERPROFILE\.cache\sccache", "User")
    [Environment]::SetEnvironmentVariable("SCCACHE_CACHE_SIZE", "10G", "User")

    Write-ColorOutput "✅ C++ tools installed"
}

function Test-RunnerInstallation {
    Write-ColorOutput "Testing runner installation..." "Yellow"

    # Check if service is running
    $service = Get-Service "actions.runner.*" -ErrorAction SilentlyContinue
    if ($service) {
        Write-ColorOutput "✅ Runner service is running" "Green"
    } else {
        Write-Error-Output "❌ Runner service not found"
        return $false
    }

    # Test Python tools if installed
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        try {
            & $python -m ruff --version | Out-Null
            Write-ColorOutput "✅ Ruff is working"
        } catch {
            Write-Error-Output "❌ Ruff not working"
        }
    }

    # Test C++ tools if installed
    $cmake = Get-Command cmake -ErrorAction SilentlyContinue
    if ($cmake) {
        try {
            & cmake --version | Out-Null
            Write-ColorOutput "✅ CMake is working"
        } catch {
            Write-Error-Output "❌ CMake not working"
        }
    }

    $sccache = Get-Command sccache -ErrorAction SilentlyContinue
    if ($sccache) {
        try {
            & sccache --version | Out-Null
            Write-ColorOutput "✅ sccache is working"
        } catch {
            Write-Error-Output "❌ sccache not working"
        }
    }

    return $true
}

function Print-Success {
    Write-ColorOutput "`n================================" "Green"
    Write-ColorOutput "✅ Runner setup complete!" "Green"
    Write-ColorOutput "================================`n" "Green"

    Write-Host "Service status:"
    Get-Service "actions.runner.*" | Format-Table

    Write-Host "`nNext steps:"
    Write-Host "1. Verify runner in GitHub settings"
    Write-Host "2. Test with a sample workflow"

    if ($SetupPython) {
        Write-Host "3. Python tools are ready"
    }

    if ($SetupCpp) {
        Write-Host "3. C++ tools are ready"
    }

    Write-Host "`nTo install additional tools:"
    Write-Host "- PowerShell: .\install-runner-windows.ps1 -SetupPython"
    Write-Host "- PowerShell: .\install-runner-windows.ps1 -SetupCpp"
}

# Main execution
try {
    if ($ValidateOnly) {
        Test-RunnerInstallation
        exit 0
    }

    if (!(Test-Admin)) {
        Write-Error-Output "Please run this script as Administrator"
        exit 1
    }

    Write-ColorOutput "Starting GitHub Actions runner setup..." "Cyan"

    if ($SetupPython) {
        Setup-PythonTools
        exit 0
    }

    if ($SetupCpp) {
        Setup-CppTools
        exit 0
    }

    # Full installation
    Install-Dependencies
    Download-Runner
    Configure-Runner
    Install-Service

    # Optional setup prompts
    $setupPython = Read-Host "Do you want to install Python development tools? (y/N)"
    if ($setupPython -eq 'y' -or $setupPython -eq 'Y') {
        Setup-PythonTools
    }

    $setupCpp = Read-Host "Do you want to install C++ development tools? (y/N)"
    if ($setupCpp -eq 'y' -or $setupCpp -eq 'Y') {
        Setup-CppTools
    }

    # Test installation
    if (Test-RunnerInstallation) {
        Print-Success
    } else {
        Write-Error-Output "Installation completed with errors. Please check the logs."
        exit 1
    }
}
catch {
    Write-Error-Output "Error: $_"
    Write-Error-Output "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}