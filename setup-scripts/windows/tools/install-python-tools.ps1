#!/usr/bin/env pwsh
# Install Python Development Tools for Windows

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

# Function to check Python installation
function Test-PythonInstallation {
    try {
        $pythonVersion = python --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Python found: $pythonVersion"
            return $true
        }
    } catch {
        # Python not found
    }

    try {
        $pythonVersion = python3 --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Python3 found: $pythonVersion"
            return $true
        }
    } catch {
        # Python3 not found
    }

    Write-Warning "Python not found. Installing Python..."
    return $false
}

# Function to install Python
function Install-Python {
    Write-Status "Installing Python 3..."

    try {
        # Install Python via Chocolatey
        choco install python3 -y --no-progress

        # Refresh environment variables
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

        # Verify installation
        $pythonVersion = python --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Python installed successfully: $pythonVersion"
        } else {
            throw "Python installation verification failed"
        }

    } catch {
        Write-Error-Output "Failed to install Python: $($_.Exception.Message)"
        throw
    }
}

# Function to install Python package
function Install-PythonPackage {
    param(
        [string]$PackageName,
        [string]$DisplayName = $PackageName,
        [string[]]$Arguments = @()
    )

    Write-Status "Installing $DisplayName..."
    try {
        $installArgs = @("install", "--upgrade", $PackageName) + $Arguments
        & python $installArgs

        if ($LASTEXITCODE -eq 0) {
            Write-Success "$DisplayName installed successfully"
        } else {
            Write-Warning "Failed to install $DisplayName"
        }
    } catch {
        Write-Warning "Failed to install $DisplayName`: $($_.Exception.Message)"
    }
}

# Function to install essential Python development tools
function Install-EssentialPythonTools {
    Write-Status "Installing essential Python development tools..."

    try {
        # Upgrade pip first
        Write-Status "Upgrading pip..."
        & python -m pip install --upgrade pip

        # Essential packages for code quality and development
        $essentialPackages = @(
            @{ Name = "ruff"; Display = "Ruff linter and formatter" },
            @{ Name = "black"; Display = "Black code formatter" },
            @{ Name = "isort"; Display = "isort import sorter" },
            @{ Name = "pytest"; Display = "pytest testing framework" },
            @{ Name = "pytest-cov"; Display = "pytest coverage plugin" },
            @{ Name = "pytest-mock"; Display = "pytest mocking support" },
            @{ Name = "mypy"; Display = "MyPy type checker" },
            @{ Name = "flake8"; Display = "Flake8 linter" },
            @{ Name = "bandit"; Display = "Bandit security analyzer" },
            @{ Name = "pre-commit"; Display = "pre-commit hooks" }
        )

        foreach ($package in $essentialPackages) {
            Install-PythonPackage -PackageName $package.Name -DisplayName $package.Display
        }

    } catch {
        Write-Error-Output "Failed to install essential Python tools: $($_.Exception.Message)"
        throw
    }
}

# Function to install Python development environment tools
function Install-DevelopmentEnvironmentTools {
    Write-Status "Installing Python development environment tools..."

    $devPackages = @(
        @{ Name = "virtualenv"; Display = "virtualenv" },
        @{ Name = "pipenv"; Display = "Pipenv" },
        @{ Name = "poetry"; Display = "Poetry" },
        @{ Name = "tox"; Display = "Tox" },
        @{ Name = "cookiecutter"; Display = "Cookiecutter project templates" }
    )

    foreach ($package in $devPackages) {
        Install-PythonPackage -PackageName $package.Name -DisplayName $package.Display
    }
}

# Function to install Python IDE and debugging tools
function Install-IDETools {
    Write-Status "Installing Python IDE and debugging tools..."

    $idePackages = @(
        @{ Name = "jupyter"; Display = "Jupyter Notebook" },
        @{ Name = "jupyterlab"; Display = "JupyterLab" },
        @{ Name = "ipython"; Display = "IPython" },
        @{ Name = "python-lsp-server"; Display = "Python LSP Server" },
        @{ Name = "debugpy"; Display = "DebugPy debugger" }
    )

    foreach ($package in $idePackages) {
        Install-PythonPackage -PackageName $package.Name -DisplayName $package.Display
    }
}

# Function to install documentation tools
function Install-DocumentationTools {
    Write-Status "Installing Python documentation tools..."

    $docPackages = @(
        @{ Name = "sphinx"; Display = "Sphinx documentation generator" },
        @{ Name = "sphinx-rtd-theme"; Display = "Sphinx ReadTheDocs theme" },
        @{ Name = "myst-parser"; Display = "MyST markdown parser for Sphinx" }
    )

    foreach ($package in $docPackages) {
        Install-PythonPackage -PackageName $package.Name -DisplayName $package.Display
    }
}

# Function to install performance and profiling tools
function Install-PerformanceTools {
    Write-Status "Installing Python performance and profiling tools..."

    $perfPackages = @(
        @{ Name = "memory-profiler"; Display = "Memory profiler" },
        @{ Name = "line-profiler"; Display = "Line profiler" },
        @{ Name = "py-spy"; Display = "Py-spy sampling profiler" },
        @{ Name = "scalene"; Display = "Scalene CPU and memory profiler" }
    )

    foreach ($package in $perfPackages) {
        Install-PythonPackage -PackageName $package.Name -DisplayName $package.Display
    }
}

# Function to setup Python environment variables
function Set-PythonEnvironment {
    Write-Status "Setting up Python environment..."

    try {
        # Set PYTHONPATH if not already set
        $pythonPath = [System.Environment]::GetEnvironmentVariable("PYTHONPATH", "User")
        if (-not $pythonPath) {
            $defaultPythonPath = Join-Path $env:USERPROFILE "dev\python"
            [System.Environment]::SetEnvironmentVariable("PYTHONPATH", $defaultPythonPath, "User")
            Write-Status "Set PYTHONPATH to: $defaultPythonPath"
        }

        # Create Python development directories
        $pythonDirs = @(
            Join-Path $env:USERPROFILE "dev\python",
            Join-Path $env:USERPROFILE "dev\python\projects",
            Join-Path $env:USERPROFILE "dev\python\scripts"
        )

        foreach ($dir in $pythonDirs) {
            if (-not (Test-Path $dir)) {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
            }
        }

        # Add Python Scripts directory to PATH
        $pythonScriptsPath = & python -c "import sys; import os; print(os.path.join(sys.prefix, 'Scripts'))" 2>$null
        if ($pythonScriptsPath -and (Test-Path $pythonScriptsPath)) {
            $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
            if ($currentPath -notlike "*$pythonScriptsPath*") {
                [System.Environment]::SetEnvironmentVariable("PATH", $currentPath + ";$pythonScriptsPath", "User")
                Write-Status "Added Python Scripts to PATH: $pythonScriptsPath"
            }
        }

        Write-Success "Python environment setup completed"

    } catch {
        Write-Warning "Failed to setup Python environment: $($_.Exception.Message)"
    }
}

# Function to create Python project templates
function New-PythonProjectTemplates {
    Write-Status "Creating Python project templates..."

    try {
        $templatesDir = Join-Path $env:USERPROFILE "dev\python\templates"
        if (-not (Test-Path $templatesDir)) {
            New-Item -Path $templatesDir -ItemType Directory -Force | Out-Null
        }

        # Create basic Python project template
        $basicTemplateDir = Join-Path $templatesDir "basic-python"
        New-Item -Path $basicTemplateDir -ItemType Directory -Force | Out-Null

        # Create template files
        $pyprojectToml = @"
[build-system]
requires = ["setuptools>=45", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "my-project"
version = "0.1.0"
description = "A Python project"
authors = [
    {name = "Your Name", email = "your.email@example.com"}
]
readme = "README.md"
requires-python = ">=3.8"
classifiers = [
    "Development Status :: 3 - Alpha",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.8",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=4.0.0",
    "black>=23.0.0",
    "ruff>=0.0.260",
    "mypy>=1.0.0",
]

[tool.black]
line-length = 88
target-version = ['py38']

[tool.ruff]
line-length = 88
target-version = "py38"
select = ["E", "F", "UP", "B", "SIM", "I"]

[tool.mypy]
python_version = "3.8"
warn_return_any = true
warn_unused_configs = true

[tool.pytest.ini_options]
minversion = "6.0"
addopts = "-ra -q --strict-markers"
testpaths = ["tests"]
"@

        $pyprojectToml | Out-File -FilePath (Join-Path $basicTemplateDir "pyproject.toml") -Encoding UTF8 -Force

        # Create basic README template
        $readmeTemplate = @"
# My Python Project

A description of my Python project.

## Installation

\`\`\`bash
pip install -e .
\`\`\`

## Development

\`\`\`bash
# Install development dependencies
pip install -e ".[dev]"

# Run tests
pytest

# Format code
black src/ tests/
ruff check src/ tests/
ruff format src/ tests/

# Type checking
mypy src/
\`\`\`
"@

        $readmeTemplate | Out-File -FilePath (Join-Path $basicTemplateDir "README.md") -Encoding UTF8 -Force

        Write-Success "Python project templates created in: $templatesDir"

    } catch {
        Write-Warning "Failed to create Python project templates: $($_.Exception.Message)"
    }
}

# Function to verify Python tools installation
function Test-PythonToolsInstallation {
    Write-Status "Verifying Python tools installation..."

    $tools = @(
        @{ Name = "ruff"; Command = "ruff --version" },
        @{ Name = "black"; Command = "black --version" },
        @{ Name = "pytest"; Command = "pytest --version" },
        @{ Name = "mypy"; Command = "mypy --version" },
        @{ Name = "bandit"; Command = "bandit --version" },
        @{ Name = "pre-commit"; Command = "pre-commit --version" }
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
}

# Main installation
try {
    Write-Status "Starting Windows Python development tools installation..."

    # Check and install Python if needed
    if (-not (Test-PythonInstallation)) {
        Install-Python
    }

    # Refresh environment variables after Python installation
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

    # Install Python development tools
    Install-EssentialPythonTools
    Install-DevelopmentEnvironmentTools
    Install-IDETools
    Install-DocumentationTools
    Install-PerformanceTools

    # Setup Python environment
    Set-PythonEnvironment

    # Create project templates
    New-PythonProjectTemplates

    # Verify installations
    Test-PythonToolsInstallation

    Write-Success "Python development tools installation completed successfully"

} catch {
    Write-Error-Output "Python development tools installation failed: $($_.Exception.Message)"
    exit 1
}