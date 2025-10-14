# GitHub Actions Self-Hosted Runner Installation (Windows)
# Part of CICD Template System - Phase 6.2

param(
    [Parameter(Mandatory=$false)]
    [string]$GitHubUrl,

    [Parameter(Mandatory=$false)]
    [string]$Token,

    [Parameter(Mandatory=$false)]
    [string]$RunnerName = $env:COMPUTERNAME,

    [Parameter(Mandatory=$false)]
    [switch]$SetupPython,

    [Parameter(Mandatory=$false)]
    [switch]$SetupCpp,

    [Parameter(Mandatory=$false)]
    [switch]$ValidateOnly,

    [Parameter(Mandatory=$false)]
    [switch]$Help,

    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "runner-config.yaml"
)

$ErrorActionPreference = "Stop"

# Configuration constants
$RUNNER_VERSION = "2.319.1"
$INSTALL_DIR = "C:\actions-runner"
$RUNNER_USER = "github-runner"
$LOG_DIR = "$INSTALL_DIR\_diag"
$CONFIG_DIR = "$INSTALL_DIR\config"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "Green",
        [switch]$NoNewline
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = "[$timestamp]"

    if ($NoNewline) {
        Write-Host "$prefix $Message" -ForegroundColor $Color -NoNewline
    } else {
        Write-Host "$prefix $Message" -ForegroundColor $Color
    }
}

function Write-Header {
    param([string]$Message)
    Write-ColorOutput "`n=== $Message ===" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✅ $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠️  $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "❌ $Message" "Red"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ️  $Message" "White"
}

function Show-Help {
    Write-Host @"
GitHub Actions Self-Hosted Runner Installation Script for Windows
Part of CICD Template System - Phase 6.2

USAGE:
    .\install-runner-windows.ps1 [-GitHubUrl <url>] [-Token <token>] [-RunnerName <name>]
    .\install-runner-windows.ps1 -SetupPython [-ConfigFile <path>]
    .\install-runner-windows.ps1 -SetupCpp [-ConfigFile <path>]
    .\install-runner-windows.ps1 -ValidateOnly
    .\install-runner-windows.ps1 -Help

PARAMETERS:
    -GitHubUrl    GitHub repository or organization URL
    -Token        Runner registration token
    -RunnerName   Name for the runner (default: computer name)
    -SetupPython  Install Python development tools
    -SetupCpp     Install C++ development tools
    -ValidateOnly Test existing installation
    -ConfigFile   Path to configuration file (default: runner-config.yaml)
    -Help         Show this help message

EXAMPLES:
    # Interactive installation
    .\install-runner-windows.ps1

    # Non-interactive installation
    .\install-runner-windows.ps1 -GitHubUrl "https://github.com/myorg" -Token "ghp_xxx"

    # Setup Python tools after installation
    .\install-runner-windows.ps1 -SetupPython

    # Setup C++ tools after installation
    .\install-runner-windows.ps1 -SetupCpp

    # Validate existing installation
    .\install-runner-windows.ps1 -ValidateOnly

FEATURES:
- Installs GitHub Actions self-hosted runner as Windows service
- Installs Chocolatey package manager
- Sets up Python development environment (Ruff, pytest, mypy, etc.)
- Sets up C++ development environment (CMake, Ninja, sccache, clang tools)
- Configures sccache for compilation caching
- Creates user configurations for development tools
- Provides comprehensive logging and error handling
"@
    exit 0
}

function Test-AdminPrivileges {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        if (-not $isAdmin) {
            Write-Error "This script requires administrator privileges. Please run as Administrator."
            Write-Info "Right-click PowerShell and select 'Run as Administrator'"
            exit 1
        }

        return $true
    }
    catch {
        Write-Error "Failed to check administrator privileges: $_"
        exit 1
    }
}

function Install-Chocolatey {
    Write-Header "Installing Chocolatey Package Manager"

    try {
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Success "Chocolatey is already installed"
            return
        }

        Write-Info "Downloading and installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

        # Refresh environment variables
        refreshenv
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

        Write-Success "Chocolatey installed successfully"
    }
    catch {
        Write-Error "Failed to install Chocolatey: $_"
        Write-Info "You can install Chocolatey manually from: https://chocolatey.org/install"
        exit 1
    }
}

function Install-Dependencies {
    Write-Header "Installing System Dependencies"

    try {
        # Install Chocolatey if not present
        Install-Chocolatey

        # Install Git with command line tools
        Write-Info "Installing Git..."
        choco install -y git --params "/GitAndUnixToolsOnPath /NoAutoCrlf"
        if ($LASTEXITCODE -ne 0) {
            throw "Git installation failed"
        }
        Write-Success "Git installed successfully"

        # Install additional useful tools
        Write-Info "Installing additional system tools..."
        choco install -y 7zip curl jq wget
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Some additional tools failed to install"
        } else {
            Write-Success "Additional tools installed successfully"
        }

        # Install PowerShell Core for better scripting experience
        Write-Info "Installing PowerShell Core..."
        choco install -y powershell-core --pre
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "PowerShell Core installation failed, using built-in PowerShell"
        } else {
            Write-Success "PowerShell Core installed successfully"
        }

        # Refresh PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

        Write-Success "All system dependencies installed successfully"
    }
    catch {
        Write-Error "Failed to install dependencies: $_"
        exit 1
    }
}

function Create-RunnerUser {
    Write-Header "Creating Runner Service User"

    try {
        # Check if user already exists
        $existingUser = Get-LocalUser -Name $RUNNER_USER -ErrorAction SilentlyContinue
        if ($existingUser) {
            Write-Success "Runner user '$RUNNER_USER' already exists"
            return
        }

        # Create new user with secure password
        $password = ConvertTo-SecureString -String "Runner@2024!SecurePassword" -AsPlainText -Force
        $userParams = @{
            Name = $RUNNER_USER
            Password = $password
            Description = "GitHub Actions runner service user"
            PasswordNeverExpires = $true
            UserMayNotChangePassword = $true
        }

        New-LocalUser @userParams

        # Add user to appropriate groups
        Add-LocalGroupMember -Group "Users" -Member $RUNNER_USER

        # Grant Log on as a service right
        try {
            $sid = (Get-LocalUser -Name $RUNNER_USER).SID.Value
            $tempFile = New-TemporaryFile

            # Create secpol.cfg
            secedit /export /cfg "$($tempFile.FullName)" | Out-Null

            # Modify the file to add logon as service right
            $content = Get-Content "$($tempFile.FullName)"
            $newContent = $content -replace '^SeServiceLogonRight .+', "SeServiceLogonRight = $sid"
            Set-Content "$($tempFile.FullName)" -Value $newContent

            # Apply the security policy
            secedit /configure /db secedit.sdb /cfg "$($tempFile.FullName)" /areas USER_RIGHTS | Out-Null

            Remove-Item "$($tempFile.FullName)"
            Write-Success "Granted Log on as service right to $RUNNER_USER"
        }
        catch {
            Write-Warning "Could not grant Log on as service right automatically. This may need to be done manually."
        }

        Write-Success "Runner user '$RUNNER_USER' created successfully"
    }
    catch {
        Write-Warning "Failed to create dedicated runner user: $_. Using current user for runner service."
        Write-Info "This is acceptable but not recommended for production environments."
    }
}

function Download-Runner {
    Write-Header "Downloading GitHub Actions Runner"

    try {
        # Create installation directory if it doesn't exist
        if (Test-Path $INSTALL_DIR) {
            Write-Warning "Existing installation found at $INSTALL_DIR"
            $continue = Read-Host "Do you want to remove it and continue? (y/N)"
            if ($continue -ne 'y' -and $continue -ne 'Y') {
                Write-Info "Installation cancelled"
                exit 0
            }

            Write-Info "Removing existing installation..."
            Stop-Service -Name "actions.runner.*" -ErrorAction SilentlyContinue -Force
            Start-Sleep -Seconds 2
            Remove-Item -Path $INSTALL_DIR -Recurse -Force
        }

        New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
        New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null
        New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null

        Set-Location $INSTALL_DIR

        # Download runner
        $url = "https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-win-x64-$RUNNER_VERSION.zip"
        Write-Info "Downloading from: $url"

        Invoke-WebRequest -Uri $url -OutFile "actions-runner.zip" -UseBasicParsing -TimeoutSec 300

        if (-not (Test-Path "actions-runner.zip")) {
            throw "Failed to download runner package"
        }

        # Verify download
        $fileInfo = Get-Item "actions-runner.zip"
        if ($fileInfo.Length -lt 1MB) {
            throw "Downloaded file seems too small ($($fileInfo.Length) bytes)"
        }

        Write-Info "Extracting runner..."
        Expand-Archive -Path "actions-runner.zip" -DestinationPath . -Force
        Remove-Item "actions-runner.zip"

        # Verify extraction
        $requiredFiles = @("config.cmd", "run.cmd", "svc.cmd")
        foreach ($file in $requiredFiles) {
            if (-not (Test-Path $file)) {
                throw "Required file $file not found after extraction"
            }
        }

        # Set permissions for runner user
        try {
            $acl = Get-Acl $INSTALL_DIR
            $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $RUNNER_USER,
                "FullControl",
                "ContainerInherit,ObjectInherit",
                "None",
                "Allow"
            )
            $acl.SetAccessRule($accessRule)
            Set-Acl -Path $INSTALL_DIR -AclObject $acl
            Write-Success "Set permissions for runner user"
        }
        catch {
            Write-Warning "Could not set permissions for runner user: $_"
        }

        Write-Success "Runner downloaded and extracted successfully"
    }
    catch {
        Write-Error "Failed to download runner: $_"
        exit 1
    }
}

function Get-RunnerCredentials {
    param(
        [string]$Url,
        [string]$RegistrationToken,
        [string]$Name
    )

    # If parameters not provided, ask for them
    if (-not $Url) {
        Write-Info "Please provide your GitHub repository or organization URL"
        Write-Info "Examples:"
        Write-Info "  Repository: https://github.com/myorg/myrepo"
        Write-Info "  Organization: https://github.com/myorg"
        $Url = Read-Host "GitHub URL"
    }

    if (-not $RegistrationToken) {
        Write-Info "You need a runner registration token from GitHub"
        Write-Info "Get it from: GitHub Settings -> Actions -> Runners -> New runner"
        $RegistrationToken = Read-Host "Registration token"
    }

    if (-not $Name) {
        $defaultName = $env:COMPUTERNAME
        Write-Info "Enter a name for this runner (default: $defaultName)"
        $inputName = Read-Host "Runner name"
        if ([string]::IsNullOrWhiteSpace($inputName)) {
            $Name = $defaultName
        } else {
            $Name = $inputName
        }
    }

    # Validate URL format
    if ($Url -notmatch '^https://github\.com/') {
        throw "Invalid GitHub URL format. Expected: https://github.com/owner or https://github.com/owner/repo"
    }

    return @{
        Url = $Url
        Token = $RegistrationToken
        Name = $Name
    }
}

function Configure-Runner {
    Write-Header "Configuring GitHub Actions Runner"

    try {
        $config = Get-RunnerCredentials -Url $GitHubUrl -Token $Token -Name $RunnerName

        Write-Info "Configuration details:"
        Write-Info "  URL: $($config.Url)"
        Write-Info "  Name: $($config.Name)"
        Write-Info "  Labels: self-hosted,Windows,X64"

        Set-Location $INSTALL_DIR

        # Configure runner
        $configArgs = @(
            "--url", $config.Url,
            "--token", $config.Token,
            "--name", $config.Name,
            "--labels", "self-hosted,Windows,X64",
            "--work", "_work",
            "--unattended"
        )

        Write-Info "Running configuration..."
        $process = Start-Process -FilePath ".\config.cmd" -ArgumentList $configArgs -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -ne 0) {
            throw "Runner configuration failed with exit code $($process.ExitCode)"
        }

        # Verify configuration
        $configFile = "$INSTALL_DIR\.runner"
        if (Test-Path $configFile) {
            Write-Success "Runner configured successfully"
        } else {
            throw "Configuration completed but config file not found"
        }

        # Save configuration summary
        $configSummary = @{
            Url = $config.Url
            Name = $config.Name
            Labels = "self-hosted,Windows,X64"
            ConfiguredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
            RunnerVersion = $RUNNER_VERSION
        }

        $configSummary | ConvertTo-Json -Depth 10 | Set-Content "$CONFIG_DIR\runner-config.json"
        Write-Info "Configuration saved to $CONFIG_DIR\runner-config.json"

    }
    catch {
        Write-Error "Failed to configure runner: $_"
        Write-Info "Please check:"
        Write-Info "  - GitHub URL is correct"
        Write-Info "  - Registration token is valid and not expired"
        Write-Info "  - Network connectivity to GitHub"
        exit 1
    }
}

function Install-RunnerService {
    Write-Header "Installing Runner as Windows Service"

    try {
        Set-Location $INSTALL_DIR

        Write-Info "Installing runner service..."
        $process = Start-Process -FilePath ".\svc.cmd" -ArgumentList "install" -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -ne 0) {
            throw "Service installation failed with exit code $($process.ExitCode)"
        }

        Write-Info "Starting runner service..."
        $process = Start-Process -FilePath ".\svc.cmd" -ArgumentList "start" -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -ne 0) {
            throw "Service start failed with exit code $($process.ExitCode)"
        }

        # Wait for service to initialize
        Write-Info "Waiting for service to initialize..."
        Start-Sleep -Seconds 10

        # Check service status
        $serviceName = "actions.runner.*"
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

        if ($service) {
            if ($service.Status -eq "Running") {
                Write-Success "Runner service is running: $($service.Name)"
            } else {
                Write-Warning "Runner service found but status is: $($service.Status)"
            }

            Write-Info "Service details:"
            Write-Info "  Name: $($service.Name)"
            Write-Info "  Status: $($service.Status)"
            Write-Info "  Start Type: $($service.StartType)"
            Write-Info "  Display Name: $($service.DisplayName)"

        } else {
            # Try to find the service by different means
            Write-Warning "Service not found with wildcard pattern, searching manually..."
            $allServices = Get-Service | Where-Object { $_.Name -like "*actions*" -or $_.DisplayName -like "*actions*" }

            if ($allServices) {
                foreach ($svc in $allServices) {
                    Write-Info "Found related service: $($svc.Name) - $($svc.Status)"
                }
            } else {
                Write-Warning "No runner service found. Installation may have failed."
            }
        }

        # Test connectivity
        Write-Info "Testing runner connectivity..."
        try {
            $testProcess = Start-Process -FilePath ".\run.cmd" -ArgumentList "--once" -Wait -PassThru -NoNewWindow
            if ($testProcess.ExitCode -eq 0) {
                Write-Success "Runner connectivity test passed"
            } else {
                Write-Warning "Runner connectivity test failed with exit code $($testProcess.ExitCode)"
            }
        }
        catch {
            Write-Warning "Could not run connectivity test: $_"
        }

        Write-Success "Runner service installation completed"
    }
    catch {
        Write-Error "Failed to install runner service: $_"
        Write-Info "Troubleshooting steps:"
        Write-Info "  1. Check if the runner user has proper permissions"
        Write-Info "  2. Verify Windows Event Log for detailed errors"
        Write-Info "  3. Try running the service manually: .\run.cmd"
        exit 1
    }
}

function Get-RunnerStatus {
    Write-Header "Checking Runner Status"

    try {
        # Check service status
        $service = Get-Service -Name "actions.runner.*" -ErrorAction SilentlyContinue
        if ($service) {
            Write-Success "Runner service found: $($service.Name)"
            Write-Info "  Status: $($service.Status)"
            Write-Info "  Start Type: $($service.StartType)"
        } else {
            Write-Warning "No runner service found"
        }

        # Check installation directory
        if (Test-Path $INSTALL_DIR) {
            Write-Success "Runner installation directory exists: $INSTALL_DIR"

            # Check key files
            $keyFiles = @("config.cmd", "run.cmd", "svc.cmd", ".runner")
            foreach ($file in $keyFiles) {
                $filePath = Join-Path $INSTALL_DIR $file
                if (Test-Path $filePath) {
                    Write-Info "  ✓ $file exists"
                } else {
                    Write-Warning "  ✗ $file missing"
                }
            }
        } else {
            Write-Warning "Runner installation directory not found: $INSTALL_DIR"
        }

        # Check configuration
        $configFile = Join-Path $CONFIG_DIR "runner-config.json"
        if (Test-Path $configFile) {
            Write-Success "Configuration file found: $configFile"
            $config = Get-Content $configFile | ConvertFrom-Json
            Write-Info "  Runner Name: $($config.Name)"
            Write-Info "  GitHub URL: $($config.Url)"
            Write-Info "  Configured: $($config.ConfiguredAt)"
        }

        # Check logs
        if (Test-Path $LOG_DIR) {
            $logFiles = Get-ChildItem $LOG_DIR -File | Sort-Object LastWriteTime -Descending | Select-Object -First 3
            if ($logFiles) {
                Write-Info "Recent log files:"
                foreach ($logFile in $logFiles) {
                    Write-Info "  $($logFile.Name) - $($logFile.LastWriteTime)"
                }
            }
        }

        return $true
    }
    catch {
        Write-Error "Failed to get runner status: $_"
        return $false
    }
}

function Setup-PythonTools {
    Write-Header "Installing Python Development Tools"

    try {
        # Check if Python is installed
        $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
        if (-not $pythonCmd) {
            Write-Info "Python not found. Installing Python 3.11..."
            choco install -y python311
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
            $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
        }

        if ($pythonCmd) {
            $pythonVersion = & $pythonCmd --version
            Write-Success "Found Python: $pythonVersion"

            Write-Info "Upgrading pip and installing core packages..."
            & $pythonCmd -m pip install --upgrade pip setuptools wheel

            # Install Python development tools
            $packages = @(
                "ruff>=0.6.0",
                "pytest>=7.4.0",
                "pytest-cov>=4.1.0",
                "mypy>=1.11.0",
                "pre-commit>=3.5.0",
                "black>=23.0.0",
                "flake8>=6.0.0",
                "isort>=5.12.0",
                "bandit>=1.7.0",
                "pipx"
            )

            foreach ($package in $packages) {
                Write-Info "Installing $package..."
                & $pythonCmd -m pip install $package
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Failed to install $package"
                }
            }

            # Create Ruff configuration
            Write-Info "Creating Ruff configuration..."
            $ruffConfig = @"
# Ruff configuration for CICD Template Windows Runner
target-version = "py310"
line-length = 88
indent-width = 4

[lint]
# Enable rules
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort
    "N",   # pep8-naming
    "UP",  # pyupgrade
    "B",   # flake8-bugbear
    "C4",  # flake8-comprehensions
    "SIM", # flake8-simplify
    "S",   # flake8-bandit
]

ignore = [
    "E501",  # line too long (handled by formatter)
    "S101",  # use of assert detected
]

# Allow autofix
fixable = ["ALL"]
unfixable = []

[format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "auto"

[per-file-ignores]
"tests/*" = ["S101"]  # Allow assert in tests
"__init__.py" = ["F401"]  # Allow unused imports in __init__
"@

            $ruffConfigDir = "$env:USERPROFILE\.config\ruff"
            New-Item -ItemType Directory -Force -Path $ruffConfigDir | Out-Null
            Set-Content -Path "$ruffConfigDir\ruff.toml" -Value $ruffConfig

            # Create mypy configuration
            Write-Info "Creating MyPy configuration..."
            $mypyConfig = @"
# MyPy configuration for CICD Template
[mypy]
python_version = "3.10"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
check_untyped_defs = true
disallow_untyped_decorators = true
no_implicit_optional = true
warn_redundant_casts = true
warn_unused_ignores = true
warn_no_return = true
warn_unreachable = true
strict_equality = true

# Per-module configuration
[mypy-tests.*]
disallow_untyped_defs = false
"@

            Set-Content -Path "$env:USERPROFILE\mypy.ini" -Value $mypyConfig

            # Create pre-commit configuration template
            Write-Info "Creating pre-commit configuration template..."
            $precommitConfig = @"
# Pre-commit configuration for Python projects
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: check-merge-conflict
      - id: detect-private-key

  # Ruff replaces: Black, Flake8, isort, pyupgrade
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.0
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format

  # Optional: mypy
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.11.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
        args: [--strict, --ignore-missing-imports]
"@

            Set-Content -Path "$CONFIG_DIR\pre-commit-config-template.yaml" -Value $precommitConfig

            # Create requirements file
            Write-Info "Creating requirements reference file..."
            $requirementsContent = @"
# Python development tools installed by CICD Template Windows Runner
# Generated by install-runner-windows.ps1
ruff>=0.6.0
pytest>=7.4.0
pytest-cov>=4.1.0
mypy>=1.11.0
pre-commit>=3.5.0
black>=23.0.0
flake8>=6.0.0
isort>=5.12.0
bandit>=1.7.0
pipx
"@

            Set-Content -Path "$CONFIG_DIR\python-requirements.txt" -Value $requirementsContent

            # Test installations
            Write-Info "Testing Python tools..."
            try {
                & $pythonCmd -m ruff --version | Out-Null
                Write-Success "✓ Ruff is working"
            } catch {
                Write-Warning "✗ Ruff test failed"
            }

            try {
                & $pythonCmd -m pytest --version | Out-Null
                Write-Success "✓ pytest is working"
            } catch {
                Write-Warning "✗ pytest test failed"
            }

            try {
                & $pythonCmd -m mypy --version | Out-Null
                Write-Success "✓ mypy is working"
            } catch {
                Write-Warning "✗ mypy test failed"
            }

            Write-Success "Python development tools installed successfully"
            Write-Info "Configuration files created in:"
            Write-Info "  - $ruffConfigDir\ruff.toml"
            Write-Info "  - $env:USERPROFILE\mypy.ini"
            Write-Info "  - $CONFIG_DIR\pre-commit-config-template.yaml"
            Write-Info "  - $CONFIG_DIR\python-requirements.txt"

        } else {
            Write-Error "Python installation failed or not found"
            exit 1
        }
    }
    catch {
        Write-Error "Failed to install Python tools: $_"
        exit 1
    }
}

function Setup-CppTools {
    Write-Header "Installing C++ Development Tools"

    try {
        # Install Visual Studio Build Tools
        Write-Info "Installing Visual Studio Build Tools 2022..."
        choco install -y visualstudio2022buildtools --package-parameters "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --passive"
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Visual Studio Build Tools installation may have failed - continuing anyway"
        }

        # Install CMake and Ninja
        Write-Info "Installing CMake and Ninja..."
        choco install -y cmake ninja
        if ($LASTEXITCODE -ne 0) {
            throw "CMake/Ninja installation failed"
        }

        # Install LLVM/Clang
        Write-Info "Installing LLVM/Clang..."
        choco install -y llvm
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "LLVM installation failed - using MSVC compiler"
        }

        # Install sccache for compilation caching
        Write-Info "Installing sccache (compilation cache)..."
        $sccacheVersion = "0.7.7"
        $sccacheUrl = "https://github.com/mozilla/sccache/releases/download/v$sccacheVersion/sccache-v$sccacheVersion-x86_64-pc-windows-msvc.zip"

        $sccacheDir = "C:\sccache"
        New-Item -ItemType Directory -Path $sccacheDir -Force | Out-Null

        try {
            Write-Info "Downloading sccache from: $sccacheUrl"
            Invoke-WebRequest -Uri $sccacheUrl -OutFile "$sccacheDir\sccache.zip" -UseBasicParsing -TimeoutSec 300
            Expand-Archive -Path "$sccacheDir\sccache.zip" -DestinationPath $sccacheDir -Force
            Remove-Item "$sccacheDir\sccache.zip"

            # Add sccache to PATH
            $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
            if ($currentPath -notlike "*$sccacheDir*") {
                [System.Environment]::SetEnvironmentVariable(
                    "Path",
                    $currentPath + ";$sccacheDir",
                    "Machine"
                )
                Write-Success "Added sccache to system PATH"
            }
        }
        catch {
            Write-Warning "Failed to install sccache: $_"
        }

        # Create clang-format configuration
        Write-Info "Creating clang-format configuration..."
        $clangFormatConfig = @"
# clang-format configuration for CICD Template Windows Runner
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

# Enable modern C++ features
SortIncludes: true
IncludeBlocks: Preserve
SpaceBeforeParens: ControlStatements
"@

        Set-Content -Path "$env:USERPROFILE\.clang-format" -Value $clangFormatConfig

        # Create clang-tidy configuration
        Write-Info "Creating clang-tidy configuration..."
        $clangTidyConfig = @"
# clang-tidy configuration for CICD Template
Checks: >
  *,
  -fuchsia-*,
  -google-*,
  -llvm-*,
  -modernize-use-trailing-return-type,
  -readability-magic-numbers,
  -cppcoreguidelines-avoid-magic-numbers,
  -hicpp-avoid-magic-numbers

WarningsAsErrors: '*'

HeaderFilterRegex: '.*'

CheckOptions:
  - key: readability-identifier-naming.ClassCase
    value: CamelCase
  - key: readability-identifier-naming.FunctionCase
    value: camelBack
  - key: readability-identifier-naming.VariableCase
    value: lower_case
  - key: readability-identifier-naming.ConstantCase
    value: UPPER_CASE
  - key: readability-identifier-naming.EnumConstantCase
    value: UPPER_CASE
  - key: readability-identifier-naming.PrivateMemberSuffix
    value: _
  - key: modernize-use-nullptr.NullptrMacros
    value: 'NULL'
"@

        Set-Content -Path "$env:USERPROFILE\.clang-tidy" -Value $clangTidyConfig

        # Configure sccache environment variables
        Write-Info "Configuring sccache environment variables..."
        [System.Environment]::SetEnvironmentVariable("CMAKE_C_COMPILER_LAUNCHER", "sccache", "Machine")
        [System.Environment]::SetEnvironmentVariable("CMAKE_CXX_COMPILER_LAUNCHER", "sccache", "Machine")
        [System.Environment]::SetEnvironmentVariable("SCCACHE_DIR", "$env:USERPROFILE\.cache\sccache", "User")
        [System.Environment]::SetEnvironmentVariable("SCCACHE_CACHE_SIZE", "10G", "User")
        [System.Environment]::SetEnvironmentVariable("SCCACHE_IDLE_TIMEOUT", "7200", "User")  # 2 hours

        # Create CMake presets template
        Write-Info "Creating CMake presets template..."
        $cmakePresets = @"
{
  "version": 3,
  "configurePresets": [
    {
      "name": "windows-default",
      "displayName": "Windows Default Config",
      "description": "Default configuration for Windows using MSVC",
      "generator": "Ninja",
      "toolset": "host=x64",
      "architecture": "x64",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release",
        "CMAKE_C_COMPILER_LAUNCHER": "sccache",
        "CMAKE_CXX_COMPILER_LAUNCHER": "sccache",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
      }
    },
    {
      "name": "windows-debug",
      "displayName": "Windows Debug Config",
      "description": "Debug configuration for Windows",
      "inherits": "windows-default",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "windows-release",
      "configurePreset": "windows-default",
      "displayName": "Release Build"
    }
  ],
  "testPresets": [
    {
      "name": "windows-test",
      "configurePreset": "windows-default",
      "displayName": "Run Tests",
      "execution": {
        "noTestsAction": "error"
      }
    }
  ]
}
"@

        Set-Content -Path "$CONFIG_DIR\CMakePresets.json" -Value $cmakePresets

        # Create C++ tools summary
        Write-Info "Creating C++ tools configuration summary..."
        $cppToolsSummary = @"
# C++ Development Tools Configuration Summary
# Generated by install-runner-windows.ps1

## Installed Tools:
- Visual Studio Build Tools 2022 with C++ workload
- CMake (latest)
- Ninja build system
- LLVM/Clang compiler (optional)
- sccache (compilation cache)

## Environment Variables Configured:
- CMAKE_C_COMPILER_LAUNCHER = sccache
- CMAKE_CXX_COMPILER_LAUNCHER = sccache
- SCCACHE_DIR = $env:USERPROFILE\.cache\sccache
- SCCACHE_CACHE_SIZE = 10G
- SCCACHE_IDLE_TIMEOUT = 7200 seconds (2 hours)

## Configuration Files Created:
- $env:USERPROFILE\.clang-format
- $env:USERPROFILE\.clang-tidy
- $CONFIG_DIR\CMakePresets.json

## Usage Examples:

### Basic CMake usage:
```powershell
# Configure with sccache
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Build
cmake --build build -j$(nproc)

# Run tests
ctest --test-dir build --output-on-failure
```

### Using CMake presets:
```powershell
# Configure
cmake --preset windows-default

# Build
cmake --build --preset windows-release

# Test
ctest --preset windows-test
```

### sccache management:
```powershell
# Check sccache stats
sccache --show-stats

# Clear cache
sccache --zero-stats
```
"@

        Set-Content -Path "$CONFIG_DIR\cpp-tools-summary.md" -Value $cppToolsSummary

        # Test installations
        Write-Info "Testing C++ tools..."
        $cmake = Get-Command cmake -ErrorAction SilentlyContinue
        if ($cmake) {
            try {
                $version = & cmake --version | Select-Object -First 1
                Write-Success "✓ CMake is working: $version"
            } catch {
                Write-Warning "✗ CMake test failed"
            }
        }

        $ninja = Get-Command ninja -ErrorAction SilentlyContinue
        if ($ninja) {
            try {
                $version = & ninja --version
                Write-Success "✓ Ninja is working: version $version"
            } catch {
                Write-Warning "✗ Ninja test failed"
            }
        }

        $sccache = Get-Command sccache -ErrorAction SilentlyContinue
        if ($sccache) {
            try {
                $version = & sccache --version
                Write-Success "✓ sccache is working: $version"
            } catch {
                Write-Warning "✗ sccache test failed"
            }
        }

        Write-Success "C++ development tools installed successfully"
        Write-Info "Configuration files created in:"
        Write-Info "  - $env:USERPROFILE\.clang-format"
        Write-Info "  - $env:USERPROFILE\.clang-tidy"
        Write-Info "  - $CONFIG_DIR\CMakePresets.json"
        Write-Info "  - $CONFIG_DIR\cpp-tools-summary.md"

        # Refresh PATH for current session
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    }
    catch {
        Write-Error "Failed to install C++ tools: $_"
        exit 1
    }
}

function Test-CompleteInstallation {
    Write-Header "Testing Complete Installation"

    $allTestsPassed = $true

    try {
        # Test service status
        Write-Info "Testing runner service..."
        $service = Get-Service -Name "actions.runner.*" -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.Status -eq "Running") {
                Write-Success "✓ Runner service is running"
            } else {
                Write-Warning "⚠ Runner service found but status: $($service.Status)"
                $allTestsPassed = $false
            }
        } else {
            Write-Error "✗ Runner service not found"
            $allTestsPassed = $false
        }

        # Test installation directory
        Write-Info "Testing installation files..."
        $requiredFiles = @("config.cmd", "run.cmd", "svc.cmd", ".runner")
        foreach ($file in $requiredFiles) {
            $filePath = Join-Path $INSTALL_DIR $file
            if (Test-Path $filePath) {
                Write-Info "✓ $file exists"
            } else {
                Write-Error "✗ $file missing"
                $allTestsPassed = $false
            }
        }

        # Test Python tools
        Write-Info "Testing Python development tools..."
        $python = Get-Command python -ErrorAction SilentlyContinue
        if ($python) {
            $pythonTests = @{
                "Ruff" = "python -m ruff --version"
                "pytest" = "python -m pytest --version"
                "mypy" = "python -m mypy --version"
                "pip" = "python -m pip --version"
            }

            foreach ($tool in $pythonTests.Keys) {
                try {
                    $result = & $pythonTests[$tool] 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "✓ $tool is working"
                    } else {
                        Write-Warning "⚠ $tool test failed"
                    }
                }
                catch {
                    Write-Warning "⚠ $tool not available"
                }
            }
        } else {
            Write-Info "ℹ Python not installed"
        }

        # Test C++ tools
        Write-Info "Testing C++ development tools..."
        $cppTests = @{
            "CMake" = "cmake --version"
            "Ninja" = "ninja --version"
            "sccache" = "sccache --version"
            "clang-format" = "clang-format --version"
        }

        foreach ($tool in $cppTests.Keys) {
            $cmd = Get-Command $tool -ErrorAction SilentlyContinue
            if ($cmd) {
                try {
                    $result = & $cppTests[$tool] 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "✓ $tool is working"
                    } else {
                        Write-Warning "⚠ $tool test failed"
                    }
                }
                catch {
                    Write-Warning "⚠ $tool not working properly"
                }
            } else {
                Write-Info "ℹ $tool not installed"
            }
        }

        # Test network connectivity to GitHub
        Write-Info "Testing GitHub connectivity..."
        try {
            $testUrl = "https://github.com"
            $response = Invoke-WebRequest -Uri $testUrl -UseBasicParsing -TimeoutSec 10 -Method Head
            if ($response.StatusCode -eq 200) {
                Write-Success "✓ GitHub connectivity OK"
            } else {
                Write-Warning "⚠ GitHub connectivity issue: $($response.StatusCode)"
            }
        }
        catch {
            Write-Warning "⚠ GitHub connectivity test failed: $_"
        }

        # Summary
        Write-Host ""
        if ($allTestsPassed) {
            Write-Success "All critical tests passed! Installation is ready to use."
        } else {
            Write-Warning "Some tests failed. Review the output above for details."
        }

        return $allTestsPassed
    }
    catch {
        Write-Error "Test suite failed: $_"
        return $false
    }
}

function Show-InstallationSummary {
    Write-Header "Installation Summary"

    Write-Success "GitHub Actions self-hosted runner installation completed!"
    Write-Host ""

    Write-Info "Installation Details:"
    Write-Host "  Installation Directory: $INSTALL_DIR"
    Write-Host "  Configuration Directory: $CONFIG_DIR"
    Write-Host "  Log Directory: $LOG_DIR"
    Write-Host "  Runner Version: $RUNNER_VERSION"
    Write-Host "  Runner Name: $RunnerName"

    if ($GitHubUrl) {
        Write-Host "  GitHub URL: $GitHubUrl"
    }

    Write-Host ""
    Write-Info "Next Steps:"
    Write-Host "1. Verify the runner appears in your GitHub repository/organization settings"
    Write-Host "2. Test with a sample workflow that uses 'self-hosted' label"
    Write-Host "3. Install additional development tools if needed:"

    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCmd) {
        Write-Host "   - Run: .\install-runner-windows.ps1 -SetupPython"
    }

    $cmakeCmd = Get-Command cmake -ErrorAction SilentlyContinue
    if (-not $cmakeCmd) {
        Write-Host "   - Run: .\install-runner-windows.ps1 -SetupCpp"
    }

    Write-Host ""
    Write-Info "Service Management:"
    Write-Host "  - Start service: .\svc.cmd start"
    Write-Host "  - Stop service: .\svc.cmd stop"
    Write-Host "  - Restart service: .\svc.cmd restart"

    Write-Host ""
    Write-Info "Troubleshooting:"
    Write-Host "  - Check logs in: $LOG_DIR"
    Write-Host "  - Validate installation: .\install-runner-windows.ps1 -ValidateOnly"
    Write-Host "  - Show this help: .\install-runner-windows.ps1 -Help"

    Write-Host ""
    Write-Success "Thank you for using CICD Template System!"
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

# Main execution logic
try {
    # Handle help flag
    if ($Help) {
        Show-Help
    }

    # Handle validation only mode
    if ($ValidateOnly) {
        $result = Get-RunnerStatus
        if ($result) {
            Write-Success "Runner installation validation passed"
        } else {
            Write-Error "Runner installation validation failed"
            exit 1
        }
        exit 0
    }

    # Check admin privileges for most operations
    Test-AdminPrivileges

    Write-ColorOutput "GitHub Actions Self-Hosted Runner Installation for Windows" "Magenta"
    Write-ColorOutput "CICD Template System - Phase 6.2" "Magenta"
    Write-Host ""

    # Handle tool setup modes
    if ($SetupPython) {
        Write-Info "Python development tools setup mode"
        Setup-PythonTools
        Write-Success "Python tools setup completed"
        exit 0
    }

    if ($SetupCpp) {
        Write-Info "C++ development tools setup mode"
        Setup-CppTools
        Write-Success "C++ tools setup completed"
        exit 0
    }

    # Full installation mode
    Write-Info "Starting full runner installation..."

    # Check if this is a re-installation
    $isReinstall = Test-Path $INSTALL_DIR
    if ($isReinstall) {
        Write-Warning "Existing installation detected at $INSTALL_DIR"
        $continue = Read-Host "Do you want to continue with reinstallation? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            Write-Info "Installation cancelled by user"
            exit 0
        }
    }

    # Execute installation steps
    Write-Host ""
    Write-Info "Step 1: Installing system dependencies"
    Install-Dependencies

    Write-Host ""
    Write-Info "Step 2: Creating runner service user"
    Create-RunnerUser

    Write-Host ""
    Write-Info "Step 3: Downloading and extracting GitHub Actions runner"
    Download-Runner

    Write-Host ""
    Write-Info "Step 4: Configuring runner"
    Configure-Runner

    Write-Host ""
    Write-Info "Step 5: Installing and starting Windows service"
    Install-RunnerService

    # Optional development tools setup
    Write-Host ""
    Write-Info "Optional: Development tools setup"

    $setupPython = Read-Host "Do you want to install Python development tools? (y/N)"
    if ($setupPython -eq 'y' -or $setupPython -eq 'Y') {
        Write-Host ""
        Setup-PythonTools
    }

    $setupCpp = Read-Host "Do you want to install C++ development tools? (y/N)"
    if ($setupCpp -eq 'y' -or $setupCpp -eq 'Y') {
        Write-Host ""
        Setup-CppTools
    }

    # Final testing and validation
    Write-Host ""
    Write-Info "Step 6: Testing installation"
    $testResult = Test-CompleteInstallation

    # Show installation summary
    Write-Host ""
    Show-InstallationSummary

    if ($testResult) {
        Write-Success "Installation completed successfully! 🎉"
        Write-Host ""
        Write-Info "Your self-hosted runner is ready to use."
        Write-Info "Don't forget to verify it appears in your GitHub repository/organization settings."
    } else {
        Write-Warning "Installation completed with some issues. Please review the output above."
        Write-Info "You can run the script with -ValidateOnly to check the current status."
        exit 1
    }
}
catch {
    Write-Error "Installation failed: $_"
    Write-Host ""
    Write-Info "For troubleshooting:"
    Write-Info "1. Check if you're running PowerShell as Administrator"
    Write-Info "2. Verify network connectivity to GitHub"
    Write-Info "3. Check Windows Event Log for detailed errors"
    Write-Info "4. Run with -Help to see available options"
    Write-Host ""
    Write-Info "Error details:"
    Write-Info "  $($_.Exception.GetType().FullName)"
    Write-Info "  $($_.Exception.Message)"
    Write-Info "  $($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.OffsetInLine)"
    exit 1
}