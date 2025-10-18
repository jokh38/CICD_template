#!/usr/bin/env pwsh
# Setup Code Formatting Configurations for Windows

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

# Function to setup C++ formatting configurations
function Set-CppFormattingConfig {
    Write-Status "Setting up C++ code formatting configurations..."

    try {
        # Create .clang-format
        $clangFormatPath = Join-Path $env:USERPROFILE ".clang-format"

        $clangFormatContent = @"
# Based on LLVM style with some modifications for Windows development
BasedOnStyle: LLVM
IndentWidth: 4
TabWidth: 4
UseTab: Never
ColumnLimit: 100
BreakBeforeBraces: Linux
AllowShortFunctionsOnASingleLine: Empty
AllowShortIfStatementsOnASingleLine: false
AllowShortLoopsOnASingleLine: false
AllowShortCaseLabelsOnASingleLine: false
AllowShortBlocksOnASingleLine: Empty
SortIncludes: true
ReflowComments: true
SpacesBeforeTrailingComments: 2
SpaceAfterCStyleCast: false
SpaceAfterTemplateKeyword: true
SpaceBeforeAssignmentOperators: true
ContinuationIndentWidth: 4
CompactNamespaces: false
ConstructorInitializerAllOnOneLineOrOnePerLine: false
DerivePointerAlignment: false
FixNamespaceComments: true
IncludeBlocks: Preserve
IndentCaseLabels: true
IndentPPDirectives: BeforeHash
IndentWrappedFunctionNames: false
KeepEmptyLinesAtTheStartOfBlocks: false
MaxEmptyLinesToKeep: 1
NamespaceIndentation: None
PointerAlignment: Left
ReflowComments: true
SortUsingDeclarations: true
SpaceBeforeParens: ControlStatements
SpaceInEmptyParentheses: false
SpacesInCStyleCastParentheses: false
SpacesInContainerLiterals: true
SpacesInParentheses: false
SpacesInSquareBrackets: false
Standard: Latest

# Windows-specific settings
AlwaysBreakTemplateDeclarations: Yes
BinPackArguments: false
BinPackParameters: false
BreakConstructorInitializers: BeforeColon
ConstructorInitializerIndentWidth: 4
PenaltyBreakBeforeFirstCallParameter: 1
PenaltyBreakComment: 300
PenaltyBreakString: 1000
PenaltyExcessCharacter: 1000000
PenaltyReturnTypeOnItsOwnLine: 200
"@

        $clangFormatContent | Out-File -FilePath $clangFormatPath -Encoding UTF8 -Force

        # Create .clang-tidy
        $clangTidyPath = Join-Path $env:USERPROFILE ".clang-tidy"

        $clangTidyContent = @"
# clang-tidy configuration for Windows development
Checks: >
  bugprone-*,
  clang-analyzer-*,
  concurrency-*,
  modernize-*,
  performance-*,
  portability-*,
  readability-*,
  -modernize-use-trailing-return-type,
  -readability-else-after-return,
  -readability-magic-numbers,
  -cppcoreguidelines-avoid-magic-numbers,
  -readability-identifier-length,
  -cppcoreguidelines-pro-type-reinterpret-cast,
  -cppcoreguidelines-pro-type-vararg,
  -cppcoreguidelines-pro-bounds-pointer-arithmetic,
  -hicpp-signed-bitwise

WarningsAsErrors: '*'
HeaderFilterRegex: '.*'
CheckOptions:
  - key: readability-identifier-naming.ClassCase
    value: CamelCase
  - key: readability-identifier-naming.FunctionCase
    value: camelBack
  - key: readability-identifier-naming.VariableCase
    value: camelBack
  - key: readability-identifier-naming.ParameterCase
    value: camelBack
  - key: readability-identifier-naming.ConstantCase
    value: UPPER_CASE
  - key: readability-identifier-naming.EnumConstantCase
    value: UPPER_CASE
  - key: readability-identifier-naming.PrivateMemberSuffix
    value: '_'
  - key: readability-identifier-naming.PrivateMethodSuffix
    value: '_'
  - key: modernize-use-nullptr.NullMacros
    value: 'NULL'
"@

        $clangTidyContent | Out-File -FilePath $clangTidyPath -Encoding UTF8 -Force

        Write-Success "C++ formatting configurations created"

    } catch {
        Write-Error-Output "Failed to setup C++ formatting configurations: $($_.Exception.Message)"
        throw
    }
}

# Function to setup Python formatting configurations
function Set-PythonFormattingConfig {
    Write-Status "Setting up Python code formatting configurations..."

    try {
        # Create ruff configuration
        $ruffConfigDir = Join-Path $env:USERPROFILE ".config\ruff"
        if (-not (Test-Path $ruffConfigDir)) {
            New-Item -Path $ruffConfigDir -ItemType Directory -Force | Out-Null
        }

        $ruffConfigPath = Join-Path $ruffConfigDir "ruff.toml"

        $ruffConfigContent = @"
[tool.ruff]
# Exclude a variety of commonly ignored directories.
exclude = [
    ".bzr",
    ".direnv",
    ".eggs",
    ".git",
    ".git-rewrite",
    ".hg",
    ".mypy_cache",
    ".nox",
    ".pants.d",
    ".pytype",
    ".ruff_cache",
    ".svn",
    ".tox",
    ".venv",
    "__pypackages__",
    "_build",
    "buck-out",
    "build",
    "dist",
    "node_modules",
    "venv",
    ".vscode",
    ".idea",
]

# Same as Black.
line-length = 88
indent-width = 4

# Assume Python 3.8+
target-version = "py38"

[tool.ruff.lint]
# Enable Pyflakes (`F`) and a subset of the pycodestyle (`E`)  codes by default.
select = [
    # pycodestyle
    "E",
    # Pyflakes
    "F",
    # pyupgrade
    "UP",
    # flake8-bugbear
    "B",
    # flake8-simplify
    "SIM",
    # isort
    "I",
    # pep8-naming
    "N",
    # pylint
    "PL",
]
ignore = [
    # Star imports are used for type checking
    "F405",
    "F403",
    # Allow unused variables when underscore-prefixed.
    "F841",
    # Allow long lines for docstrings
    "E501",
    # Ignore certain pylint checks
    "PLR0913",  # Too many arguments
    "PLR0915",  # Too many statements
]

# Allow fix for all enabled rules (when `--fix`) is provided.
fixable = ["ALL"]
unfixable = []

# Allow unused variables when underscore-prefixed.
dummy-variable-rgx = "^(_+|(_+[a-zA-Z0-9_]*[a-zA-Z0-9]+?))$"

[tool.ruff.format]
# Like Black, use double quotes for strings.
quote-style = "double"

# Like Black, indent with spaces, rather than tabs.
indent-style = "space"

# Like Black, respect magic trailing commas.
skip-magic-trailing-comma = false

# Like Black, automatically detect the appropriate line ending.
line-ending = "auto"

[tool.ruff.lint.isort]
known-first-party = ["src"]
split-on-trailing-comma = true
"@

        $ruffConfigContent | Out-File -FilePath $ruffConfigPath -Encoding UTF8 -Force

        # Create pyproject.toml for Python projects
        $pyprojectTomlPath = Join-Path $env:USERPROFILE "pyproject.toml"

        $pyprojectTomlContent = @"
[build-system]
requires = ["setuptools>=45", "wheel"]
build-backend = "setuptools.build_meta"

[tool.black]
line-length = 88
target-version = ['py38']
include = '\.pyi?$'
extend-exclude = '''
/(
  # directories
  \.eggs
  | \.git
  | \.hg
  | \.mypy_cache
  | \.tox
  | \.venv
  | build
  | dist
  | _build
  | buck-out
  | build
  | dist
)/
'''

[tool.isort]
profile = "black"
multi_line_output = 3
line_length = 88
known_first_party = ["src"]
split_on_trailing_comma = true

[tool.mypy]
python_version = "3.8"
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
mypy_path = "src"

[[tool.mypy.overrides]]
module = [
    "tests.*",
]
ignore_errors = true

[tool.pytest.ini_options]
minversion = "6.0"
addopts = "-ra -q --strict-markers --strict-config --cov=src --cov-report=html --cov-report=term-missing"
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
    "windows: marks tests as Windows-specific",
]

[tool.coverage.run]
source = ["src"]
omit = [
    "*/tests/*",
    "*/test/*",
    "*/__pycache__/*",
]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise AssertionError",
    "raise NotImplementedError",
    "if __name__ == .__main__.:",
    "if TYPE_CHECKING:",
]
"@

        $pyprojectTomlContent | Out-File -FilePath $pyprojectTomlPath -Encoding UTF8 -Force

        Write-Success "Python formatting configurations created"

    } catch {
        Write-Error-Output "Failed to setup Python formatting configurations: $($_.Exception.Message)"
        throw
    }
}

# Function to setup CMake configurations
function Set-CMakeConfiguration {
    Write-Status "Setting up CMake configurations..."

    try {
        $cmakeConfigDir = Join-Path $env:USERPROFILE ".config\cmake"
        if (-not (Test-Path $cmakeConfigDir)) {
            New-Item -Path $cmakeConfigDir -ItemType Directory -Force | Out-Null
        }

        $cmakePresetsPath = Join-Path $cmakeConfigDir "CMakePresets.json"

        $cmakePresetsContent = @"
{
  "version": 6,
  "cmakeMinimumRequired": {
    "major": 3,
    "minor": 16,
    "patch": 0
  },
  "configurePresets": [
    {
      "name": "default",
      "displayName": "Default Config",
      "description": "Default configuration for Windows",
      "generator": "Visual Studio 17 2022",
      "toolset": {
        "value": "host=x64",
        "strategy": "external"
      },
      "architecture": {
        "value": "x64",
        "strategy": "external"
      },
      "toolchain": {
        "value": "${env:ProgramFiles}\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat",
        "strategy": "external"
      },
      "buildType": "Release",
      "installDir": "\${sourceDir}/out/install/\${presetName}",
      "condition": {
        "type": "equals",
        "lhs": "\${hostSystemName}",
        "rhs": "Windows"
      },
      "cacheVariables": {
        "CMAKE_CXX_STANDARD": "17",
        "CMAKE_CXX_STANDARD_REQUIRED": "ON",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON",
        "CMAKE_TOOLCHAIN_FILE": "$env:ProgramFiles\\vcpkg\\scripts\\buildsystems\\vcpkg.cmake",
        "VCPKG_TARGET_TRIPLET": "x64-windows"
      }
    },
    {
      "name": "debug",
      "displayName": "Debug Config",
      "description": "Debug configuration for Windows",
      "generator": "Visual Studio 17 2022",
      "toolset": {
        "value": "host=x64",
        "strategy": "external"
      },
      "architecture": {
        "value": "x64",
        "strategy": "external"
      },
      "toolchain": {
        "value": "${env:ProgramFiles}\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat",
        "strategy": "external"
      },
      "buildType": "Debug",
      "installDir": "\${sourceDir}/out/install/\${presetName}",
      "condition": {
        "type": "equals",
        "lhs": "\${hostSystemName}",
        "rhs": "Windows"
      },
      "cacheVariables": {
        "CMAKE_CXX_STANDARD": "17",
        "CMAKE_CXX_STANDARD_REQUIRED": "ON",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON",
        "CMAKE_TOOLCHAIN_FILE": "$env:ProgramFiles\\vcpkg\\scripts\\buildsystems\\vcpkg.cmake",
        "VCPKG_TARGET_TRIPLET": "x64-windows"
      }
    },
    {
      "name": "ninja",
      "displayName": "Ninja Config",
      "description": "Ninja-based configuration for Windows",
      "generator": "Ninja",
      "buildType": "Release",
      "installDir": "\${sourceDir}/out/install/\${presetName}",
      "condition": {
        "type": "equals",
        "lhs": "\${hostSystemName}",
        "rhs": "Windows"
      },
      "cacheVariables": {
        "CMAKE_CXX_STANDARD": "17",
        "CMAKE_CXX_STANDARD_REQUIRED": "ON",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON",
        "CMAKE_C_COMPILER": "clang-cl",
        "CMAKE_CXX_COMPILER": "clang-cl",
        "CMAKE_TOOLCHAIN_FILE": "$env:ProgramFiles\\vcpkg\\scripts\\buildsystems\\vcpkg.cmake",
        "VCPKG_TARGET_TRIPLET": "x64-windows"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "default",
      "configurePreset": "default",
      "jobs": 0
    },
    {
      "name": "debug",
      "configurePreset": "debug",
      "jobs": 0
    },
    {
      "name": "ninja",
      "configurePreset": "ninja",
      "jobs": 0
    }
  ],
  "testPresets": [
    {
      "name": "default",
      "configurePreset": "default",
      "execution": {
        "noTestsAction": "error",
        "stopOnFailure": false,
        "enableFailoverOutput": true,
        "timeout": {
          "style": "debug"
        }
      },
      "filter": {
        "exclude": {
          "name": "*DISABLED_*"
        }
      },
      "output": {
        "outputOnFailure": "error",
        "outputJUnitFile": "\${sourceDir}/out/test/\${presetName}.xml"
      }
    },
    {
      "name": "debug",
      "configurePreset": "debug",
      "execution": {
        "noTestsAction": "error",
        "stopOnFailure": false,
        "enableFailoverOutput": true,
        "timeout": {
          "style": "debug"
        }
      },
      "filter": {
        "exclude": {
          "name": "*DISABLED_*"
        }
      },
      "output": {
        "outputOnFailure": "error",
        "outputJUnitFile": "\${sourceDir}/out/test/\${presetName}.xml"
      }
    }
  ],
  "packagePresets": [
    {
      "name": "default",
      "configurePreset": "default",
      "packageDirectory": "\${sourceDir}/out/package",
      "generators": [
        "ZIP",
        "WIX"
      ]
    }
  ]
}
"@

        $cmakePresetsContent | Out-File -FilePath $cmakePresetsPath -Encoding UTF8 -Force

        Write-Success "CMake configurations created"

    } catch {
        Write-Error-Output "Failed to setup CMake configurations: $($_.Exception.Message)"
        throw
    }
}

# Function to setup sccache configuration
function Set-SCCacheConfiguration {
    Write-Status "Setting up sccache configuration..."

    try {
        $sccacheConfigDir = Join-Path $env:USERPROFILE ".config\sccache"
        if (-not (Test-Path $sccacheConfigDir)) {
            New-Item -Path $sccacheConfigDir -ItemType Directory -Force | Out-Null
        }

        $sccacheConfigPath = Join-Path $sccacheConfigDir "config"

        $sccacheConfigContent = @"
# sccache configuration for Windows
cache_dir = "~\\cache\\sccache"
max_size = "5G"

# Windows-specific settings
# You can customize these based on your needs
# For larger projects, consider increasing cache size
# max_size = "10G"

# Network settings (if using remote cache)
# server_url = "http://your-sccache-server:8080"
# auth_token = "your-auth-token"

# Compiler-specific settings
[dist.ccache]
# If you want to use ccache instead of sccache for some compilers
# rlimit_as = 2147483648  # 2GB memory limit

[dist gcc]
# GCC-specific settings
# rlimit_cpu = 4  # Limit CPU usage
"@

        $sccacheConfigContent | Out-File -FilePath $sccacheConfigPath -Encoding UTF8 -Force

        Write-Success "sccache configuration created"

    } catch {
        Write-Error-Output "Failed to setup sccache configuration: $($_.Exception.Message)"
        throw
    }
}

# Function to create editor integration files
function New-EditorIntegration {
    Write-Status "Creating editor integration files..."

    try {
        # VS Code settings
        $vscodeSettingsDir = Join-Path $env:USERPROFILE ".vscode"
        if (-not (Test-Path $vscodeSettingsDir)) {
            New-Item -Path $vscodeSettingsDir -ItemType Directory -Force | Out-Null
        }

        $vscodeSettingsPath = Join-Path $vscodeSettingsDir "settings.json"

        $vscodeSettings = @{
            "editor.formatOnSave" = $true
            "editor.codeActionsOnSave" = @{
                "source.fixAll" = $true
                "source.organizeImports" = $true
            }
            "editor.defaultFormatter" = "ms-python.black-formatter"
            "python.defaultInterpreterPath" = "python"
            "python.formatting.provider" = "black"
            "python.linting.enabled" = $true
            "python.linting.ruffEnabled" = $true
            "python.linting.mypyEnabled" = $true
            "python.testing.pytestEnabled" = $true
            "python.testing.unittestEnabled" = $false
            "files.associations" = @{
                "*.h" = "cpp"
                "*.hpp" = "cpp"
                "*.cxx" = "cpp"
                "*.cc" = "cpp"
                "*.cpp" = "cpp"
            }
            "C_Cpp.default.cppStandard" = "c++17"
            "C_Cpp.default.cStandard" = "c11"
            "C_Cpp.formatting" = "clangFormat"
            "cmake.configureOnOpen" = $true
            "cmake.generator" = "Ninja"
        }

        $vscodeSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $vscodeSettingsPath -Encoding UTF8 -Force

        # Create VS Code extensions.json
        $vscodeExtensionsPath = Join-Path $vscodeSettingsDir "extensions.json"

        $vscodeExtensions = @{
            "recommendations" = @(
                "ms-python.python",
                "ms-python.black-formatter",
                "charliermarsh.ruff",
                "ms-python.mypy-type-checker",
                "ms-python.debugpy",
                "ms-vscode.cmake-tools",
                "ms-vscode.cpptools",
                "ms-vscode.cpptools-extension-pack",
                "ms-vscode.cmake-tools",
                "twxs.cmake",
                "ms-vscode.vscode-json",
                "redhat.vscode-yaml",
                "eamodio.gitlens",
                "ms-vscode.powershell"
            )
        }

        $vscodeExtensions | ConvertTo-Json -Depth 10 | Out-File -FilePath $vscodeExtensionsPath -Encoding UTF8 -Force

        Write-Success "VS Code integration files created"

    } catch {
        Write-Warning "Failed to create VS Code integration: $($_.Exception.Message)"
    }
}

# Function to verify formatting configurations
function Test-FormattingConfigurations {
    Write-Status "Verifying formatting configurations..."

    try {
        $configs = @(
            @{ Name = ".clang-format"; Path = Join-Path $env:USERPROFILE ".clang-format" },
            @{ Name = ".clang-tidy"; Path = Join-Path $env:USERPROFILE ".clang-tidy" },
            @{ Name = "ruff.toml"; Path = Join-Path $env:USERPROFILE ".config\ruff\ruff.toml" },
            @{ Name = "pyproject.toml"; Path = Join-Path $env:USERPROFILE "pyproject.toml" },
            @{ Name = "CMakePresets.json"; Path = Join-Path $env:USERPROFILE ".config\cmake\CMakePresets.json" },
            @{ Name = "sccache config"; Path = Join-Path $env:USERPROFILE ".config\sccache\config" },
            @{ Name = "VS Code settings"; Path = Join-Path $env:USERPROFILE ".vscode\settings.json" }
        )

        foreach ($config in $configs) {
            if (Test-Path $config.Path) {
                Write-Success "$($config.Name) exists"
            } else {
                Write-Warning "$($config.Name) not found"
            }
        }

        Write-Success "Formatting configurations verification completed"

    } catch {
        Write-Warning "Could not verify formatting configurations: $($_.Exception.Message)"
    }
}

# Main configuration
try {
    Write-Status "Starting Windows code formatting configuration..."

    # Setup configurations
    Set-CppFormattingConfig
    Set-PythonFormattingConfig
    Set-CMakeConfiguration
    Set-SCCacheConfiguration

    # Create editor integrations
    New-EditorIntegration

    # Verify configurations
    Test-FormattingConfigurations

    Write-Success "Code formatting configuration completed successfully"
    Write-Status "Your editors and build tools are now configured for consistent formatting!"

} catch {
    Write-Error-Output "Code formatting configuration failed: $($_.Exception.Message)"
    exit 1
}