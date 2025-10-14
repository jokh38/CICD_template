#!/usr/bin/env pwsh
# Code Formatting Configuration Setup for Windows

param(
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

function Setup-CppFormatting {
    Write-ColorOutput "Setting up C++ code formatting configurations..." "Green"

    try {
        $userProfile = [System.Environment]::GetEnvironmentVariable("USERPROFILE", "User")

        # Create .clang-format configuration
        $clangFormatPath = Join-Path $userProfile ".clang-format"
        $clangFormatContent = @"
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

        Set-Content -Path $clangFormatPath -Value $clangFormatContent -Encoding UTF8
        Write-ColorOutput "✅ .clang-format created at $clangFormatPath" "Green"

        # Create .clang-tidy configuration
        $clangTidyPath = Join-Path $userProfile ".clang-tidy"
        $clangTidyContent = @"
# clang-tidy configuration
Checks: >
  *,
  -fuchsia-*,
  -google-*,
  -llvm-*,
  -modernize-use-trailing-return-type,
  -readability-magic-numbers,
  -cppcoreguidelines-avoid-magic-numbers

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
"@

        Set-Content -Path $clangTidyPath -Value $clangTidyContent -Encoding UTF8
        Write-ColorOutput "✅ .clang-tidy created at $clangTidyPath" "Green"

        # Create CMake presets template
        $cmakeConfigPath = Join-Path $userProfile ".config\cmake"
        New-Item -ItemType Directory -Path $cmakeConfigPath -Force | Out-Null

        $cmakePresetsPath = Join-Path $cmakeConfigPath "CMakePresets.json"
        $cmakePresetsContent = @"
{
  "version": 6,
  "configurePresets": [
    {
      "name": "base",
      "hidden": true,
      "toolchain": {
        "file": "`${sourceDir}/cmake/toolchains/default.cmake"
      },
      "cacheVariables": {
        "CMAKE_C_COMPILER_LAUNCHER": "sccache",
        "CMAKE_CXX_COMPILER_LAUNCHER": "sccache",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
      }
    },
    {
      "name": "debug",
      "inherits": "base",
      "displayName": "Debug",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "CMAKE_DEBUG_POSTFIX": "-d"
      }
    },
    {
      "name": "release",
      "inherits": "base",
      "displayName": "Release",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release",
        "CMAKE_INTERPROCEDURAL_OPTIMIZATION": "ON"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "debug",
      "configurePreset": "debug",
      "jobs": 4
    },
    {
      "name": "release",
      "configurePreset": "release",
      "jobs": 4
    }
  ],
  "testPresets": [
    {
      "name": "debug",
      "configurePreset": "debug",
      "execution": {
        "noTestsAction": "error",
        "timeout": 300
      }
    },
    {
      "name": "release",
      "configurePreset": "release",
      "execution": {
        "noTestsAction": "error",
        "timeout": 300
      }
    }
  ]
}
"@

        Set-Content -Path $cmakePresetsPath -Value $cmakePresetsContent -Encoding UTF8
        Write-ColorOutput "✅ CMake presets created at $cmakePresetsPath" "Green"

    } catch {
        Write-ColorOutput "Error setting up C++ formatting: $($_.Exception.Message)" "Red"
        throw
    }
}

function Setup-PythonFormatting {
    Write-ColorOutput "Setting up Python code formatting configurations..." "Green"

    try {
        $userProfile = [System.Environment]::GetEnvironmentVariable("USERPROFILE", "User")

        # Create ruff config
        $ruffConfigPath = Join-Path $userProfile ".config\ruff"
        New-Item -ItemType Directory -Path $ruffConfigPath -Force | Out-Null

        $ruffTomlPath = Join-Path $ruffConfigPath "ruff.toml"
        $ruffConfigContent = @"
# Global Ruff configuration
target-version = "py310"
line-length = 88
indent-width = 4

[lint]
# Enable common rules
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
"@

        Set-Content -Path $ruffTomlPath -Value $ruffConfigContent -Encoding UTF8
        Write-ColorOutput "✅ Ruff configuration created at $ruffTomlPath" "Green"

        # Create pre-commit config template
        $precommitConfigPath = Join-Path $userProfile ".config\pre-commit"
        New-Item -ItemType Directory -Path $precommitConfigPath -Force | Out-Null

        $precommitYamlPath = Join-Path $precommitConfigPath "pre-commit-config.yaml"
        $precommitConfigContent = @"
# Global pre-commit configuration template
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

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.0
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.11.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
        args: [--strict, --ignore-missing-imports]
"@

        Set-Content -Path $precommitYamlPath -Value $precommitConfigContent -Encoding UTF8
        Write-ColorOutput "✅ Pre-commit configuration created at $precommitYamlPath" "Green"

    } catch {
        Write-ColorOutput "Error setting up Python formatting: $($_.Exception.Message)" "Red"
        throw
    }
}

function Add-DevelopmentAliases {
    Write-ColorOutput "Adding development aliases to PowerShell profile..." "Green"

    try {
        $powershellProfile = Join-Path ([System.Environment]::GetEnvironmentVariable("USERPROFILE", "User")) "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

        # Create profile directory if it doesn't exist
        $profileDir = Split-Path $powershellProfile -Parent
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null

        $aliasesContent = @"

# C++ development aliases
Set-Alias -Name cmake-debug -Value "cmake --preset debug"
Set-Alias -Name cmake-release -Value "cmake --preset release"
Set-Alias -Name build-debug -Value "cmake --build --preset debug"
Set-Alias -Name build-release -Value "cmake --build --preset release"
Set-Alias -Name test-debug -Value "ctest --preset debug"
Set-Alias -Name test-release -Value "ctest --preset release"

# Python development aliases
Set-Alias -Name lint -Value "ruff check . && ruff format --check ."
Set-Alias -Name fmt -Value "ruff check . --fix && ruff format ."
Set-Alias -Name test -Value "pytest"
Set-Alias -Name cov -Value "pytest --cov=src --cov-report=html --cov-report=term"
Set-Alias -Name typecheck -Value "mypy ."
"@

        # Check if profile exists and add aliases if not already present
        if (Test-Path $powershellProfile) {
            $profileContent = Get-Content $powershellProfile -Raw
            if ($profileContent -notlike "*C++ development aliases*") {
                Add-Content -Path $powershellProfile -Value $aliasesContent
                Write-ColorOutput "✅ Development aliases added to PowerShell profile" "Green"
            } else {
                Write-ColorOutput "✅ Development aliases already exist in PowerShell profile" "Green"
            }
        } else {
            Set-Content -Path $powershellProfile -Value $aliasesContent
            Write-ColorOutput "✅ PowerShell profile created with development aliases" "Green"
        }

    } catch {
        Write-ColorOutput "Error adding development aliases: $($_.Exception.Message)" "Red"
    }
}

function Main {
    Write-ColorOutput "Starting Windows code formatting configuration..." "Green"

    try {
        Setup-CppFormatting
        Setup-PythonFormatting
        Add-DevelopmentAliases

        Write-ColorOutput "================================" "Green"
        Write-ColorOutput "✅ Code formatting configuration complete!" "Green"
        Write-ColorOutput "================================" "Green"
        Write-ColorOutput "Note: Restart PowerShell to use new aliases" "Yellow"

    } catch {
        Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
        exit 1
    }
}

Main