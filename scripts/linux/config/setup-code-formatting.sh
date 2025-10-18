#!/bin/bash
# Setup Code Formatting Configurations

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

# Setup C++ formatting configurations
print_status "Setting up C++ code formatting configurations..."

# Create .clang-format
cat > ~/.clang-format << 'EOF'
# Based on LLVM style with some modifications
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
EOF

# Create .clang-tidy
cat > ~/.clang-tidy << 'EOF'
# clang-tidy configuration
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
  -readability-identifier-length

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
EOF

# Setup Python formatting configurations
print_status "Setting up Python code formatting configurations..."

# Create ruff configuration
mkdir -p ~/.config/ruff
cat > ~/.config/ruff/ruff.toml << 'EOF'
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
]
ignore = [
    # Star imports are used for type checking
    "F405",
    "F403",
    # Allow unused variables when underscore-prefixed.
    "F841",
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
EOF

# Create pyproject.toml for Python projects
cat > ~/.pyproject.toml << 'EOF'
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
)/
'''

[tool.isort]
profile = "black"
multi_line_output = 3
line_length = 88
known_first_party = ["src"]

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

[tool.pytest.ini_options]
minversion = "6.0"
addopts = "-ra -q --strict-markers --strict-config"
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]
EOF

# Setup CMake configurations
print_status "Setting up CMake configurations..."

mkdir -p ~/.config/cmake
cat > ~/.config/cmake/CMakePresets.json << 'EOF'
{
  "version": 3,
  "configurePresets": [
    {
      "name": "default",
      "displayName": "Default Config",
      "generator": "Ninja",
      "toolset": {
        "value": "host=unknown",
        "strategy": "external"
      },
      "buildType": "Release",
      "installDir": "${sourceDir}/out/install/${presetName}",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Linux"
      }
    },
    {
      "name": "debug",
      "displayName": "Debug Config",
      "generator": "Ninja",
      "toolset": {
        "value": "host=unknown",
        "strategy": "external"
      },
      "buildType": "Debug",
      "installDir": "${sourceDir}/out/install/${presetName}",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Linux"
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
    }
  ],
  "testPresets": [
    {
      "name": "default",
      "configurePreset": "default",
      "execution": {
        "noTestsAction": "error",
        "stopOnFailure": false
      },
      "filter": {
        "exclude": {
          "name": "*DISABLED_*"
        }
      }
    },
    {
      "name": "debug",
      "configurePreset": "debug",
      "execution": {
        "noTestsAction": "error",
        "stopOnFailure": false
      },
      "filter": {
        "exclude": {
          "name": "*DISABLED_*"
        }
      }
    }
  ]
}
EOF

print_success "Code formatting configurations completed successfully"